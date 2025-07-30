import subprocess
import sys
import os
import argparse
from git_utils import get_git_repo_info, is_git_worktree

def check_git_state_clean(path=None, check_all_worktrees=False):
    """
    Check if git state has uncommitted changes.
    Enhanced to work with git worktrees.

    Args:
        path (str, optional): Path to check. Defaults to current directory.
        check_all_worktrees (bool): If True and in a worktree, check all worktrees

    Returns:
        tuple: (is_clean, details_dict)
            - is_clean (bool): True if git state is clean
            - details_dict (dict): Details about git state
    """
    if path is None:
        path = os.getcwd()
    
    details = {}
    
    try:
        # Get git repository information
        git_info = get_git_repo_info(path)
        
        if not git_info["is_repo"]:
            details["error"] = "Not in a git repository"
            return False, details
        
        # Check current worktree/repository status
        git_status = (
            subprocess.check_output(["git", "status", "--porcelain"], cwd=path)
            .decode("utf-8")
            .strip()
        )
        
        current_is_clean = not git_status
        details = {
            "is_clean": current_is_clean,
            "status": git_status.split("\n") if git_status else [],
            "is_worktree": git_info["is_worktree"],
            "current_branch": git_info["current_branch"],
            "worktree_status": {}
        }
        
        # If this is a worktree and we should check all worktrees
        if check_all_worktrees and git_info["is_worktree"] and git_info["worktree_info"]:
            all_clean = current_is_clean
            worktree_status = {}
            
            for worktree in git_info["worktree_info"]["all_worktrees"]:
                wt_path = worktree["path"]
                wt_branch = worktree.get("branch", "detached")
                
                try:
                    wt_status = (
                        subprocess.check_output(["git", "status", "--porcelain"], cwd=wt_path)
                        .decode("utf-8")
                        .strip()
                    )
                    wt_clean = not wt_status
                    worktree_status[wt_path] = {
                        "branch": wt_branch,
                        "is_clean": wt_clean,
                        "status": wt_status.split("\n") if wt_status else []
                    }
                    all_clean = all_clean and wt_clean
                except (subprocess.CalledProcessError, FileNotFoundError):
                    worktree_status[wt_path] = {
                        "branch": wt_branch,
                        "error": "Could not check status"
                    }
                    all_clean = False
            
            details["worktree_status"] = worktree_status
            details["all_worktrees_clean"] = all_clean
            return all_clean, details
        
        return current_is_clean, details
        
    except (subprocess.CalledProcessError, FileNotFoundError):
        details["error"] = "Git information not available"
        return False, details

def create_reproduce_command(parser, output_file, dvc_file_path=None):
    """
    Create a text file with the command to reproduce this run

    Args:
        parser (argparse.ArgumentParser): Parser object
        output_file (str): File to save reproduction command
        dvc_file_path (str, optional): Path to DVC file for checkout
    """
    git_hash = (
        subprocess.check_output(["git", "rev-parse", "HEAD"]).decode("utf-8").strip()
    )
    with open(output_file, "w") as f:
        f.write(f"git checkout {git_hash}\n")
    if dvc_file_path:
        with open(output_file, "a") as f:
            f.write(f"dvc checkout {dvc_file_path}\n")
    command = ["python"]
    script_path = sys.argv[0]
    command.append(script_path)
    args = parser.parse_args()
    default_values = {action.dest: action.default for action in parser._actions}
    store_action_args = {
        action.dest
        for action in parser._actions
        if isinstance(action, argparse._StoreTrueAction) or isinstance(action, argparse._StoreFalseAction)
    }
    for arg_name, arg_value in vars(args).items():
        if arg_value == default_values.get(arg_name):
            continue
        if arg_name in store_action_args:
            command.append(f"--{arg_name}")
        else:
            command.append(f"--{arg_name} {arg_value}")
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    with open(output_file, "a") as f:
        f.write(" ".join(command))

def get_worktree_safe_output_dir(base_output_dir, path=None):
    """
    Get a safe output directory that accounts for git worktrees.
    Ensures output directories don't conflict across worktrees.
    
    Args:
        base_output_dir (str): Base output directory name
        path (str, optional): Path to check. Defaults to current directory.
    
    Returns:
        str: Safe output directory path
    """
    if path is None:
        path = os.getcwd()
    
    git_info = get_git_repo_info(path)
    
    # If not in a git repo or not a worktree, use base name
    if not git_info["is_repo"] or not git_info["is_worktree"]:
        return base_output_dir
    
    # If in a worktree, append branch name to avoid conflicts
    branch_name = git_info["current_branch"] or "detached"
    # Sanitize branch name for filesystem
    safe_branch = branch_name.replace("/", "_").replace("\\", "_")
    
    return f"{base_output_dir}_{safe_branch}"

def create_worktree_aware_reproduce_command(parser, output_dir, dvc_file_path=None):
    """
    Create reproduction command that's aware of git worktrees.
    
    Args:
        parser (argparse.ArgumentParser): Parser object
        output_dir (str): Output directory for reproduce command
        dvc_file_path (str, optional): Path to DVC file for checkout
    """
    git_info = get_git_repo_info()
    
    reproduce_file = os.path.join(output_dir, "reproduce.txt")
    
    # Get current commit hash
    try:
        git_hash = (
            subprocess.check_output(["git", "rev-parse", "HEAD"]).decode("utf-8").strip()
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        git_hash = "unknown"
    
    with open(reproduce_file, "w") as f:
        f.write("# Reproduction instructions\n")
        f.write(f"# Generated from: {os.getcwd()}\n")
        f.write(f"# Git commit: {git_hash}\n")
        
        if git_info["is_worktree"]:
            f.write(f"# Git worktree: {git_info['current_branch']}\n")
            f.write(f"# Main worktree: {git_info['worktree_info']['main_worktree']}\n")
        
        f.write("\n")
        
        # Checkout instructions
        if git_info["is_worktree"]:
            f.write("# For worktree reproduction:\n")
            f.write(f'git worktree add reproduce_worktree {git_hash}\n')
            f.write("cd reproduce_worktree\n")
        else:
            f.write(f"git checkout {git_hash}\n")
        
        if dvc_file_path:
            f.write(f"dvc checkout {dvc_file_path}\n")
        
        # Command reconstruction
        command = ["python"]
        script_path = sys.argv[0]
        command.append(script_path)
        
        args = parser.parse_args()
        default_values = {action.dest: action.default for action in parser._actions}
        store_action_args = {
            action.dest
            for action in parser._actions
            if isinstance(action, argparse._StoreTrueAction) or isinstance(action, argparse._StoreFalseAction)
        }
        
        for arg_name, arg_value in vars(args).items():
            if arg_value == default_values.get(arg_name):
                continue
            if arg_name in store_action_args:
                command.append(f"--{arg_name}")
            else:
                command.append(f"--{arg_name} {arg_value}")
        
        f.write(" ".join(command))
        f.write("\n")

def ensure_worktree_git_safety(input_path, allow_test_demo=True):
    """
    Ensure git safety for worktree-aware scripts.
    
    Args:
        input_path (str): Input file or directory path
        allow_test_demo (bool): Allow execution if input contains 'test' or 'demo'
    
    Raises:
        SystemExit: If git state is not clean and safety check fails
    """
    # Check if input contains test or demo keywords
    if allow_test_demo:
        input_lower = input_path.lower()
        if 'test' in input_lower or 'demo' in input_lower:
            print(f"Input contains 'test' or 'demo' keyword - skipping git safety check")
            return
    
    # Check git state
    is_clean, details = check_git_state_clean()
    
    if not is_clean:
        print("Git state is not clean:", details)
        
        # If in a worktree, provide additional context
        if details.get("is_worktree"):
            print(f"Current worktree branch: {details.get('current_branch')}")
            print("Consider:")
            print("  1. Committing changes in current worktree")
            print("  2. Using a different worktree for this operation")
            print("  3. Stashing changes temporarily")
        
        sys.exit(1)
