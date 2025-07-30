#!/bin/bash
# Test script for git worktree detection functionality

echo "Testing git worktree detection..."
echo

# Test the git_utils.py script
if [ -f "scripts/git_utils.py" ]; then
    echo "1. Testing git_utils.py JSON output:"
    python3 scripts/git_utils.py json
    echo
    
    echo "2. Testing git repository detection:"
    python3 scripts/git_utils.py is-repo
    echo
    
    echo "3. Testing git worktree detection:"
    python3 scripts/git_utils.py is-worktree
    echo
    
    echo "4. Testing environment variable export:"
    eval $(python3 scripts/git_utils.py env)
    echo "CLAUDE_GIT_IS_REPO: $CLAUDE_GIT_IS_REPO"
    echo "CLAUDE_GIT_IS_WORKTREE: $CLAUDE_GIT_IS_WORKTREE"
    echo "CLAUDE_GIT_ROOT_PATH: $CLAUDE_GIT_ROOT_PATH"
    echo "CLAUDE_GIT_CURRENT_BRANCH: $CLAUDE_GIT_CURRENT_BRANCH"
    if [ "$CLAUDE_GIT_IS_WORKTREE" = "true" ]; then
        echo "CLAUDE_GIT_MAIN_WORKTREE: $CLAUDE_GIT_MAIN_WORKTREE"
        echo "CLAUDE_GIT_WORKTREE_COUNT: $CLAUDE_GIT_WORKTREE_COUNT"
    fi
    echo
else
    echo "ERROR: scripts/git_utils.py not found"
    exit 1
fi

# Test the worktree detection function from claude-docker.sh
echo "5. Testing worktree detection function:"
# Source the function from claude-docker.sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR"

# Extract and test the detect_git_worktree function
detect_git_worktree() {
    local git_info_json
    local is_worktree
    local main_repo_path
    
    # Use our git_utils.py to get repository information
    if command -v python3 >/dev/null 2>&1 && [ -f "$PROJECT_ROOT/scripts/git_utils.py" ]; then
        git_info_json=$(python3 "$PROJECT_ROOT/scripts/git_utils.py" json 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$git_info_json" ]; then
            # Parse JSON to check if this is a worktree
            is_worktree=$(echo "$git_info_json" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('is_worktree', False))" 2>/dev/null)
            
            if [ "$is_worktree" = "True" ]; then
                # Get main repository path from worktree info
                main_repo_path=$(echo "$git_info_json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
worktree_info = data.get('worktree_info', {})
main_worktree = worktree_info.get('main_worktree')
if main_worktree:
    print(main_worktree)
" 2>/dev/null)
                
                if [ -n "$main_repo_path" ] && [ -d "$main_repo_path" ]; then
                    echo "WORKTREE_DETECTED=true"
                    echo "MAIN_REPO_PATH=$main_repo_path"
                    echo "WORKTREE_PATH=$(pwd)"
                    return 0
                fi
            fi
        fi
    fi
    
    echo "WORKTREE_DETECTED=false"
    return 1
}

WORKTREE_INFO=$(detect_git_worktree)
eval "$WORKTREE_INFO"

echo "WORKTREE_DETECTED: $WORKTREE_DETECTED"
if [ "$WORKTREE_DETECTED" = "true" ]; then
    echo "MAIN_REPO_PATH: $MAIN_REPO_PATH"
    echo "WORKTREE_PATH: $WORKTREE_PATH"
fi

echo
echo "Test completed successfully!"