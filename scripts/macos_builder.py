import subprocess
import os
import sys
import shlex
import time
import json
from pathlib import Path
from git_utils import get_git_repo_info

class MacOSBuilder:
    """
    Execute native macOS commands via SSH from Docker container.
    Enables running native macOS builds and commands on the host system.
    """
    
    def __init__(self, 
                 host="host.docker.internal", 
                 username=None, 
                 ssh_key_path="~/.ssh/host_keys/id_rsa",
                 working_directory=None):
        """
        Initialize macOS builder.
        
        Args:
            host (str): Host to connect to (default: host.docker.internal)
            username (str): Username for SSH connection (default: from env MACOS_USERNAME)
            ssh_key_path (str): Path to SSH private key for host connection
            working_directory (str): Working directory on host (default: current project)
        """
        self.host = host
        self.username = username or os.environ.get('MACOS_USERNAME', os.environ.get('USER', 'user'))
        self.ssh_key_path = os.path.expanduser(ssh_key_path)
        self.working_directory = working_directory
        self.enabled = os.environ.get('ENABLE_MACOS_BUILDS', 'false').lower() == 'true'
        
        # SSH connection options
        self.ssh_options = [
            "-o", "ConnectTimeout=10",
            "-o", "BatchMode=yes",
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-o", "LogLevel=ERROR"
        ]
    
    def is_available(self):
        """
        Check if macOS native builds are available.
        
        Returns:
            bool: True if macOS builds can be executed
        """
        if not self.enabled:
            return False
        
        if not os.path.exists(self.ssh_key_path):
            return False
        
        # Test SSH connectivity
        return self.test_connection()
    
    def test_connection(self):
        """
        Test SSH connection to macOS host.
        
        Returns:
            bool: True if connection successful
        """
        try:
            cmd = ["ssh", "-i", self.ssh_key_path] + self.ssh_options + \
                  [f"{self.username}@{self.host}", "echo", "connection_test"]
            
            result = subprocess.run(cmd, 
                                  capture_output=True, 
                                  text=True, 
                                  timeout=15)
            
            return result.returncode == 0 and "connection_test" in result.stdout
        except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError):
            return False
    
    def get_host_working_directory(self):
        """
        Get the corresponding working directory on the macOS host.
        
        Returns:
            str: Path to working directory on host
        """
        if self.working_directory:
            return self.working_directory
        
        # Try to determine the host working directory
        # Assumes the project is mounted at /workspace in container
        container_cwd = os.getcwd()
        
        # If we're in /workspace, the host directory should be available via env
        if container_cwd.startswith('/workspace'):
            # Get the relative path from /workspace
            rel_path = os.path.relpath(container_cwd, '/workspace')
            if rel_path == '.':
                # We're at the project root
                host_project_root = os.environ.get('HOST_WORKING_DIRECTORY')
                if host_project_root:
                    return host_project_root
            else:
                # We're in a subdirectory
                host_project_root = os.environ.get('HOST_WORKING_DIRECTORY')
                if host_project_root:
                    return os.path.join(host_project_root, rel_path)
        
        # Fallback: assume same absolute path exists on host
        return container_cwd
    
    def execute_command(self, command, 
                       capture_output=False, 
                       stream_output=True,
                       timeout=None,
                       working_directory=None):
        """
        Execute a command on the macOS host via SSH.
        
        Args:
            command (str or list): Command to execute
            capture_output (bool): Whether to capture and return output
            stream_output (bool): Whether to stream output in real-time
            timeout (int): Command timeout in seconds
            working_directory (str): Override working directory
        
        Returns:
            subprocess.CompletedProcess: Result of the command
        """
        if not self.is_available():
            raise RuntimeError("macOS native builds are not available. Check SSH configuration.")
        
        # Prepare the command
        if isinstance(command, list):
            command_str = shlex.join(command)
        else:
            command_str = command
        
        # Determine working directory
        work_dir = working_directory or self.get_host_working_directory()
        
        # Construct the SSH command with working directory change
        if work_dir:
            full_command = f"cd {shlex.quote(work_dir)} && {command_str}"
        else:
            full_command = command_str
        
        ssh_cmd = ["ssh", "-i", self.ssh_key_path] + self.ssh_options + \
                  [f"{self.username}@{self.host}", full_command]
        
        print(f"Executing on macOS host: {command_str}")
        if work_dir:
            print(f"Working directory: {work_dir}")
        
        # Execute the command
        if stream_output and not capture_output:
            # Stream output in real-time
            return subprocess.run(ssh_cmd, timeout=timeout)
        else:
            # Capture output
            return subprocess.run(ssh_cmd, 
                                capture_output=capture_output,
                                text=True,
                                timeout=timeout)
    
    def build_xcode_project(self, scheme=None, configuration="Debug", 
                          destination="generic/platform=macOS",
                          additional_args=None):
        """
        Build an Xcode project using xcodebuild.
        
        Args:
            scheme (str): Xcode scheme to build
            configuration (str): Build configuration (Debug/Release)
            destination (str): Build destination
            additional_args (list): Additional xcodebuild arguments
        
        Returns:
            subprocess.CompletedProcess: Build result
        """
        cmd = ["xcodebuild"]
        
        if scheme:
            cmd.extend(["-scheme", scheme])
        
        cmd.extend([
            "-configuration", configuration,
            "-destination", destination
        ])
        
        if additional_args:
            cmd.extend(additional_args)
        
        return self.execute_command(cmd)
    
    def build_swift_package(self, configuration="debug", additional_args=None):
        """
        Build a Swift package using swift build.
        
        Args:
            configuration (str): Build configuration (debug/release)
            additional_args (list): Additional swift build arguments
        
        Returns:
            subprocess.CompletedProcess: Build result
        """
        cmd = ["swift", "build", "-c", configuration]
        
        if additional_args:
            cmd.extend(additional_args)
        
        return self.execute_command(cmd)
    
    def run_make(self, target=None, additional_args=None):
        """
        Run make command.
        
        Args:
            target (str): Make target
            additional_args (list): Additional make arguments
        
        Returns:
            subprocess.CompletedProcess: Make result
        """
        cmd = ["make"]
        
        if target:
            cmd.append(target)
        
        if additional_args:
            cmd.extend(additional_args)
        
        return self.execute_command(cmd)
    
    def install_homebrew_package(self, package):
        """
        Install a Homebrew package.
        
        Args:
            package (str): Package to install
        
        Returns:
            subprocess.CompletedProcess: Installation result
        """
        cmd = ["brew", "install", package]
        return self.execute_command(cmd)
    
    def sync_files_to_host(self, local_path, remote_path=None):
        """
        Sync files from container to host using rsync over SSH.
        
        Args:
            local_path (str): Local path in container
            remote_path (str): Remote path on host (default: same as local)
        
        Returns:
            subprocess.CompletedProcess: Sync result
        """
        if not self.is_available():
            raise RuntimeError("macOS native builds are not available. Check SSH configuration.")
        
        if remote_path is None:
            remote_path = local_path
        
        # Use rsync over SSH
        rsync_cmd = [
            "rsync", "-avz", "-e", 
            f"ssh -i {self.ssh_key_path} {' '.join(self.ssh_options)}",
            local_path,
            f"{self.username}@{self.host}:{remote_path}"
        ]
        
        print(f"Syncing {local_path} to host:{remote_path}")
        return subprocess.run(rsync_cmd)

# Convenience functions for common use cases
def execute_native_command(command, **kwargs):
    """
    Execute a command natively on macOS host.
    
    Args:
        command (str or list): Command to execute
        **kwargs: Additional arguments for MacOSBuilder.execute_command
    
    Returns:
        subprocess.CompletedProcess: Command result
    """
    builder = MacOSBuilder()
    return builder.execute_command(command, **kwargs)

def build_xcode_project(scheme=None, configuration="Debug", **kwargs):
    """
    Build Xcode project natively on macOS host.
    
    Args:
        scheme (str): Xcode scheme
        configuration (str): Build configuration
        **kwargs: Additional arguments for MacOSBuilder.build_xcode_project
    
    Returns:
        subprocess.CompletedProcess: Build result
    """
    builder = MacOSBuilder()
    return builder.build_xcode_project(scheme=scheme, configuration=configuration, **kwargs)

def build_swift_package(configuration="debug", **kwargs):
    """
    Build Swift package natively on macOS host.
    
    Args:
        configuration (str): Build configuration
        **kwargs: Additional arguments for MacOSBuilder.build_swift_package
    
    Returns:
        subprocess.CompletedProcess: Build result
    """
    builder = MacOSBuilder()
    return builder.build_swift_package(configuration=configuration, **kwargs)

def is_macos_builds_available():
    """
    Check if native macOS builds are available.
    
    Returns:
        bool: True if macOS builds can be executed
    """
    builder = MacOSBuilder()
    return builder.is_available()

def get_build_status():
    """
    Get status information about macOS build capabilities.
    
    Returns:
        dict: Status information
    """
    builder = MacOSBuilder()
    
    status = {
        "enabled": builder.enabled,
        "ssh_key_exists": os.path.exists(builder.ssh_key_path),
        "connection_available": False,
        "working_directory": None,
        "build_commands": get_configured_build_commands()
    }
    
    if status["enabled"] and status["ssh_key_exists"]:
        status["connection_available"] = builder.test_connection()
        if status["connection_available"]:
            status["working_directory"] = builder.get_host_working_directory()
    
    return status

def get_worktree_paths(project_path=None):
    """
    Get current and main worktree paths for configuration loading.
    
    Args:
        project_path (str): Path to check. Defaults to current directory.
        
    Returns:
        tuple: (current_path, main_worktree_path)
    """
    if project_path is None:
        project_path = os.getcwd()
    
    current_path = Path(project_path).resolve()
    
    # Get git repository information
    git_info = get_git_repo_info(project_path)
    
    # If not in a git repo or not a worktree, main path is same as current
    if not git_info["is_repo"] or not git_info["is_worktree"]:
        return str(current_path), str(current_path)
    
    # Get main worktree path
    main_worktree_path = git_info.get("worktree_info", {}).get("main_worktree")
    if main_worktree_path:
        main_worktree_path = Path(main_worktree_path).resolve()
    else:
        main_worktree_path = current_path
    
    return str(current_path), str(main_worktree_path)

def detect_project_type(project_path=None):
    """
    Detect project type based on files in the directory.
    
    Args:
        project_path (str): Path to project directory. Defaults to current directory.
    
    Returns:
        str: Detected project type
    """
    if project_path is None:
        project_path = os.getcwd()
    
    project_path = Path(project_path)
    
    # Check for specific project indicators
    if (project_path / "src-tauri").exists() and (project_path / "package.json").exists():
        return "tauri"
    elif (project_path / "ios").exists() and (project_path / "package.json").exists():
        return "react-native"
    elif (project_path / "Package.swift").exists():
        return "swift-package"
    elif list(project_path.glob("*.xcodeproj")) or list(project_path.glob("*.xcworkspace")):
        return "xcode"
    elif (project_path / "Cargo.toml").exists():
        return "rust"
    elif (project_path / "package.json").exists():
        return "nodejs"
    elif (project_path / "Makefile").exists() or (project_path / "makefile").exists():
        return "make"
    elif (project_path / "go.mod").exists():
        return "go"
    elif (project_path / "requirements.txt").exists() or (project_path / "pyproject.toml").exists():
        return "python"
    else:
        return "unknown"

def get_default_commands_for_project_type(project_type):
    """
    Get default build commands for a detected project type.
    
    Args:
        project_type (str): Project type from detect_project_type
        
    Returns:
        dict: Default commands for the project type
    """
    defaults = {
        "tauri": {
            "build": "npm run tauri build",
            "dev": "npm run tauri dev",
            "test": "npm run test",  
            "clean": "npm run clean",
            "install": "npm install",
            "build_dir": "src-tauri",
            "pre_build": "npm run build"
        },
        "react-native": {
            "build": "npx react-native run-macos --mode Release",
            "dev": "npx react-native run-macos",
            "test": "npm test",
            "clean": "npx react-native clean",
            "install": "npm install"
        },
        "swift-package": {
            "build": "swift build -c release",
            "dev": "swift run",
            "test": "swift test",
            "clean": "swift package clean",
            "install": "swift package resolve"
        },
        "xcode": {
            "build": "xcodebuild -scheme $(xcodebuild -list | grep -A 1 'Schemes:' | tail -1 | xargs) -configuration Release",
            "dev": "xcodebuild -scheme $(xcodebuild -list | grep -A 1 'Schemes:' | tail -1 | xargs) -configuration Debug",
            "test": "xcodebuild test -scheme $(xcodebuild -list | grep -A 1 'Schemes:' | tail -1 | xargs)",
            "clean": "xcodebuild clean"
        },
        "rust": {
            "build": "cargo build --release",
            "dev": "cargo run",
            "test": "cargo test",
            "clean": "cargo clean",
            "install": "cargo fetch"
        },
        "nodejs": {
            "build": "npm run build",
            "dev": "npm run dev",
            "test": "npm test",
            "clean": "npm run clean",
            "install": "npm install"
        },
        "make": {
            "build": "make",
            "dev": "make dev",
            "test": "make test",
            "clean": "make clean",
            "install": "make install"
        },
        "go": {
            "build": "go build -o ./bin/app ./...",
            "dev": "go run .",
            "test": "go test ./...",
            "clean": "go clean",
            "install": "go mod download"
        },
        "python": {
            "build": "python -m build",
            "dev": "python -m pip install -e .",
            "test": "python -m pytest",
            "clean": "python setup.py clean",
            "install": "python -m pip install -r requirements.txt"
        }
    }
    
    return defaults.get(project_type, {})

def load_env_file(env_file_path):
    """
    Load configuration from a single .env file.
    
    Args:
        env_file_path (Path): Path to .env file
        
    Returns:
        dict: Configuration from .env file
    """
    config = {}
    
    if env_file_path.exists():
        try:
            with open(env_file_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        key = key.strip()
                        value = value.strip().strip('"').strip("'")
                        
                        # Map environment variable names to config keys
                        if key == 'NATIVE_BUILD_COMMAND':
                            config['build'] = value
                        elif key == 'NATIVE_DEV_COMMAND':
                            config['dev'] = value
                        elif key == 'NATIVE_TEST_COMMAND':
                            config['test'] = value
                        elif key == 'NATIVE_CLEAN_COMMAND':
                            config['clean'] = value
                        elif key == 'NATIVE_INSTALL_COMMAND':
                            config['install'] = value
                        elif key == 'NATIVE_RELEASE_COMMAND':
                            config['release'] = value
                        elif key == 'NATIVE_LINT_COMMAND':
                            config['lint'] = value
                        elif key == 'NATIVE_FORMAT_COMMAND':
                            config['format'] = value
                        elif key == 'NATIVE_BUILD_DIR':
                            config['build_dir'] = value
                        elif key == 'NATIVE_PRE_BUILD':
                            config['pre_build'] = value
                        elif key == 'NATIVE_POST_BUILD':
                            config['post_build'] = value
        except Exception as e:
            print(f"Warning: Error reading .env file {env_file_path}: {e}")
    
    return config

def load_project_env_config(project_path=None):
    """
    Load build configuration from project .env file.
    Checks both current worktree and main worktree (if in a worktree).
    
    Args:
        project_path (str): Path to project directory
        
    Returns:
        dict: Configuration from .env file (main worktree config + current worktree overrides)
    """
    if project_path is None:
        project_path = os.getcwd()
    
    current_path, main_worktree_path = get_worktree_paths(project_path)
    
    # Start with main worktree config (if different from current)
    config = {}
    if main_worktree_path != current_path:
        main_env_file = Path(main_worktree_path) / ".env"
        config = load_env_file(main_env_file)
        if config:
            config['_source'] = 'main_worktree'
    
    # Override with current worktree config
    current_env_file = Path(current_path) / ".env"
    current_config = load_env_file(current_env_file)
    if current_config:
        config.update(current_config)
        config['_source'] = 'current_worktree' if not config.get('_source') else 'both_worktrees'
    
    return config

def load_claude_build_config(project_path=None):
    """
    Load build configuration from claude-build.json file.
    Checks both current worktree and main worktree (if in a worktree).
    
    Args:
        project_path (str): Path to project directory
        
    Returns:
        dict: Configuration from claude-build.json (main worktree config + current worktree overrides)
    """
    if project_path is None:
        project_path = os.getcwd()
    
    current_path, main_worktree_path = get_worktree_paths(project_path)
    
    # Start with main worktree config (if different from current)
    config = {}
    if main_worktree_path != current_path:
        main_config_file = Path(main_worktree_path) / "claude-build.json"
        if main_config_file.exists():
            try:
                with open(main_config_file, 'r') as f:
                    config = json.load(f)
                    config['_source'] = 'main_worktree'
            except Exception as e:
                print(f"Warning: Error reading main worktree claude-build.json: {e}")
    
    # Override with current worktree config
    current_config_file = Path(current_path) / "claude-build.json"
    if current_config_file.exists():
        try:
            with open(current_config_file, 'r') as f:
                current_config = json.load(f)
                config.update(current_config)
                config['_source'] = 'current_worktree' if not config.get('_source') else 'both_worktrees'
        except Exception as e:
            print(f"Warning: Error reading current worktree claude-build.json: {e}")
    
    return config

def load_package_json_from_file(package_file_path):
    """
    Load configuration from a single package.json file.
    
    Args:
        package_file_path (Path): Path to package.json file
        
    Returns:
        dict: Configuration from package.json
    """
    config = {}
    
    if package_file_path.exists():
        try:
            with open(package_file_path, 'r') as f:
                package_data = json.load(f)
                
            # Check for claude-docker specific configuration
            if 'claude-docker' in package_data:
                claude_config = package_data['claude-docker']
                config.update(claude_config)
            
            # Fallback to scripts section
            scripts = package_data.get('scripts', {})
            if 'build' in scripts and 'build' not in config:
                config['build'] = f"npm run build"
            if 'dev' in scripts and 'dev' not in config:
                config['dev'] = f"npm run dev"
            if 'test' in scripts and 'test' not in config:
                config['test'] = f"npm test"
            if 'clean' in scripts and 'clean' not in config:
                config['clean'] = f"npm run clean"
                
        except Exception as e:
            print(f"Warning: Error reading package.json {package_file_path}: {e}")
    
    return config

def load_package_json_config(project_path=None):
    """
    Load build configuration from package.json.
    Checks both current worktree and main worktree (if in a worktree).
    
    Args:
        project_path (str): Path to project directory
        
    Returns:
        dict: Configuration from package.json (main worktree config + current worktree overrides)
    """
    if project_path is None:
        project_path = os.getcwd()
    
    current_path, main_worktree_path = get_worktree_paths(project_path)
    
    # Start with main worktree config (if different from current)
    config = {}
    if main_worktree_path != current_path:
        main_package_file = Path(main_worktree_path) / "package.json"
        config = load_package_json_from_file(main_package_file)
        if config:
            config['_source'] = 'main_worktree'
    
    # Override with current worktree config
    current_package_file = Path(current_path) / "package.json"
    current_config = load_package_json_from_file(current_package_file)
    if current_config:
        config.update(current_config)
        config['_source'] = 'current_worktree' if not config.get('_source') else 'both_worktrees'
    
    return config

def get_configured_build_commands(project_path=None):
    """
    Get build commands using priority-based configuration detection.
    
    Args:
        project_path (str): Path to project directory
        
    Returns:
        dict: Final build configuration
    """
    if project_path is None:
        project_path = os.getcwd()
    
    # Start with empty config
    config = {}
    
    # 1. Auto-detect project type and get defaults (lowest priority)
    project_type = detect_project_type(project_path)
    if project_type != "unknown":
        config.update(get_default_commands_for_project_type(project_type))
        config['detected_type'] = project_type
    
    # 2. Load from package.json (if exists)
    package_config = load_package_json_config(project_path)
    config.update(package_config)
    
    # 3. Load from claude-build.json (if exists)  
    claude_config = load_claude_build_config(project_path)
    config.update(claude_config)
    
    # 4. Load from project .env file (highest priority)
    env_config = load_project_env_config(project_path)
    config.update(env_config)
    
    # 5. Override with any environment variables (for container compatibility)
    env_overrides = {
        'build': os.environ.get('NATIVE_BUILD_COMMAND'),
        'dev': os.environ.get('NATIVE_DEV_COMMAND'),
        'test': os.environ.get('NATIVE_TEST_COMMAND'),
        'clean': os.environ.get('NATIVE_CLEAN_COMMAND'),
        'install': os.environ.get('NATIVE_INSTALL_COMMAND'),
        'release': os.environ.get('NATIVE_RELEASE_COMMAND'),
        'lint': os.environ.get('NATIVE_LINT_COMMAND'),
        'format': os.environ.get('NATIVE_FORMAT_COMMAND'),
        'build_dir': os.environ.get('NATIVE_BUILD_DIR'),
        'pre_build': os.environ.get('NATIVE_PRE_BUILD'),
        'post_build': os.environ.get('NATIVE_POST_BUILD')
    }
    
    for key, value in env_overrides.items():
        if value:
            config[key] = value
    
    # Add configuration source summary
    sources = []
    if env_config.get('_source'):
        sources.append(f".env ({env_config['_source']})")
    if claude_config.get('_source'):
        sources.append(f"claude-build.json ({claude_config['_source']})")
    if package_config.get('_source'):
        sources.append(f"package.json ({package_config['_source']})")
    if project_type != "unknown":
        sources.append(f"auto-detected ({project_type})")
    
    if sources:
        config['_config_sources'] = sources
    
    # Clean up internal tracking keys
    config.pop('_source', None)
    
    return config

def run_configured_command(command_name, **kwargs):
    """
    Run a configured build command by name.
    
    Args:
        command_name (str): Name of the command (build, dev, test, etc.)
        **kwargs: Additional arguments for execute_command
    
    Returns:
        subprocess.CompletedProcess: Command result
    
    Raises:
        ValueError: If command is not configured
        RuntimeError: If macOS builds are not available
    """
    commands = get_configured_build_commands()
    
    if command_name not in commands or not commands[command_name]:
        available = [k for k, v in commands.items() if v and k not in ['pre_build', 'post_build', 'build_dir']]
        raise ValueError(f"Command '{command_name}' is not configured. Available commands: {available}")
    
    builder = MacOSBuilder()
    
    # Determine working directory
    build_dir = commands.get('build_dir')
    if build_dir:
        working_directory = build_dir
    else:
        working_directory = kwargs.get('working_directory')
    
    command = commands[command_name]
    
    # Handle build command with pre/post hooks
    if command_name == 'build':
        return run_build_with_hooks(builder, command, working_directory, **kwargs)
    else:
        return builder.execute_command(command, working_directory=working_directory, **kwargs)

def run_build_with_hooks(builder, build_command, working_directory=None, **kwargs):
    """
    Run build command with pre and post build hooks.
    
    Args:
        builder (MacOSBuilder): Builder instance
        build_command (str): Main build command
        working_directory (str): Working directory
        **kwargs: Additional arguments
        
    Returns:
        subprocess.CompletedProcess: Build result
    """
    commands = get_configured_build_commands()
    
    # Run pre-build hook
    pre_build = commands.get('pre_build')
    if pre_build:
        print(f"Running pre-build: {pre_build}")
        pre_result = builder.execute_command(pre_build, working_directory=working_directory, **kwargs)
        if pre_result.returncode != 0:
            print("❌ Pre-build failed")
            return pre_result
        print("✅ Pre-build completed")
    
    # Run main build
    print(f"Running build: {build_command}")
    build_result = builder.execute_command(build_command, working_directory=working_directory, **kwargs)
    
    # Run post-build hook only if build succeeded
    if build_result.returncode == 0:
        post_build = commands.get('post_build')
        if post_build:
            print(f"Running post-build: {post_build}")
            post_result = builder.execute_command(post_build, working_directory=working_directory, **kwargs)
            if post_result.returncode != 0:
                print("❌ Post-build failed")
                return post_result
            print("✅ Post-build completed")
        print("✅ Build completed successfully")
    else:
        print("❌ Build failed")
    
    return build_result

# Convenience functions for semantic commands
def run_build(**kwargs):
    """Run the configured build command."""
    return run_configured_command('build', **kwargs)

def run_dev(**kwargs):
    """Run the configured development server command.""" 
    return run_configured_command('dev', **kwargs)

def run_test(**kwargs):
    """Run the configured test command."""
    return run_configured_command('test', **kwargs)

def run_clean(**kwargs):
    """Run the configured clean command."""
    return run_configured_command('clean', **kwargs)

def run_install(**kwargs):
    """Run the configured install dependencies command."""
    return run_configured_command('install', **kwargs)

def run_release(**kwargs):
    """Run the configured release command."""
    return run_configured_command('release', **kwargs)

def run_lint(**kwargs):
    """Run the configured lint command."""
    return run_configured_command('lint', **kwargs)

def run_format(**kwargs):
    """Run the configured format command."""
    return run_configured_command('format', **kwargs)

if __name__ == "__main__":
    # Command line interface
    import argparse
    
    parser = argparse.ArgumentParser(description="Execute native macOS commands from Docker container")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # Status command
    status_parser = subparsers.add_parser("status", help="Show macOS build status and configured commands")
    
    # Test command
    test_parser = subparsers.add_parser("test", help="Test SSH connection")
    
    # Semantic build commands
    build_parser = subparsers.add_parser("build", help="Run configured build command")
    dev_parser = subparsers.add_parser("dev", help="Run configured development server command")
    test_cmd_parser = subparsers.add_parser("test-cmd", help="Run configured test command")
    clean_parser = subparsers.add_parser("clean", help="Run configured clean command")
    install_parser = subparsers.add_parser("install", help="Run configured install dependencies command")
    release_parser = subparsers.add_parser("release", help="Run configured release command")
    lint_parser = subparsers.add_parser("lint", help="Run configured lint command")
    format_parser = subparsers.add_parser("format", help="Run configured format command")
    
    # List configured commands
    list_parser = subparsers.add_parser("list", help="List all configured build commands")
    
    # Execute command
    exec_parser = subparsers.add_parser("exec", help="Execute arbitrary command")
    exec_parser.add_argument("cmd", nargs="+", help="Command to execute")
    exec_parser.add_argument("--capture", action="store_true", help="Capture output")
    exec_parser.add_argument("--timeout", type=int, help="Command timeout")
    
    # Xcode build command
    xcode_parser = subparsers.add_parser("xcodebuild", help="Build Xcode project")
    xcode_parser.add_argument("--scheme", help="Xcode scheme")
    xcode_parser.add_argument("--configuration", default="Debug", help="Build configuration")
    xcode_parser.add_argument("--destination", default="generic/platform=macOS", help="Build destination")
    
    # Swift build command
    swift_parser = subparsers.add_parser("swift-build", help="Build Swift package")
    swift_parser.add_argument("--configuration", default="debug", help="Build configuration")
    
    # Make command
    make_parser = subparsers.add_parser("make", help="Run make")
    make_parser.add_argument("target", nargs="?", help="Make target")
    
    args = parser.parse_args()
    
    if args.command == "status":
        status = get_build_status()
        print("macOS Native Build Status:")
        print(f"  Enabled: {status['enabled']}")
        print(f"  SSH Key Exists: {status['ssh_key_exists']}")
        print(f"  Connection Available: {status['connection_available']}")
        if status['working_directory']:
            print(f"  Working Directory: {status['working_directory']}")
        
        # Show project detection and configured commands
        commands = status['build_commands']
        if commands.get('detected_type'):
            print(f"\nProject Type: {commands['detected_type']}")
        
        configured = [k for k, v in commands.items() if v and k not in ['pre_build', 'post_build', 'build_dir', 'detected_type']]
        if configured:
            print(f"Configured Commands: {', '.join(configured)}")
            
            # Show special directories and hooks
            if commands.get('build_dir'):
                print(f"  Build Directory: {commands['build_dir']}")
            if commands.get('pre_build'):
                print(f"  Pre-build Hook: {commands['pre_build']}")
            if commands.get('post_build'):
                print(f"  Post-build Hook: {commands['post_build']}")
        else:
            print("\nNo build commands configured.")
            print("Configuration options (in priority order):")
            print("  1. Create .env file in project directory with NATIVE_*_COMMAND variables")
            print("  2. Create claude-build.json configuration file")
            print("  3. Add 'claude-docker' section to package.json")
            print("  4. Auto-detection from project structure")
    
    elif args.command == "list":
        commands = get_configured_build_commands()
        
        if commands.get('detected_type'):
            print(f"Project Type: {commands['detected_type']}")
            print()
        
        print("Configured Build Commands:")
        for name, command in commands.items():
            if command and name not in ['pre_build', 'post_build', 'build_dir', 'detected_type']:
                print(f"  {name}: {command}")
        
        if commands.get('build_dir'):
            print(f"\nBuild Directory: {commands['build_dir']}")
        if commands.get('pre_build'):
            print(f"Pre-build Hook: {commands['pre_build']}")  
        if commands.get('post_build'):
            print(f"Post-build Hook: {commands['post_build']}")
            
        if not any(v for k, v in commands.items() if k not in ['detected_type']):
            print("  No commands configured.")
            print("\nConfiguration sources (checked in order):")
            print("  1. .env file in current directory")
            print("  2. claude-build.json file")  
            print("  3. package.json 'claude-docker' section")
            print("  4. Auto-detection from project files")
    
    elif args.command == "test":
        builder = MacOSBuilder()
        if builder.test_connection():
            print("✓ SSH connection to macOS host successful")
            sys.exit(0)
        else:
            print("✗ SSH connection to macOS host failed")
            sys.exit(1)
    
    # Semantic command handlers
    elif args.command == "build":
        try:
            result = run_build()
            sys.exit(result.returncode)
        except ValueError as e:
            print(f"Error: {e}")
            sys.exit(1)
        except Exception as e:
            print(f"Error running build: {e}")
            sys.exit(1)
    
    elif args.command == "dev":
        try:
            result = run_dev()
            sys.exit(result.returncode)
        except ValueError as e:
            print(f"Error: {e}")
            sys.exit(1)
        except Exception as e:
            print(f"Error running dev command: {e}")
            sys.exit(1)
    
    elif args.command == "test-cmd":
        try:
            result = run_test()
            sys.exit(result.returncode)
        except ValueError as e:
            print(f"Error: {e}")
            sys.exit(1)
        except Exception as e:
            print(f"Error running test command: {e}")
            sys.exit(1)
    
    elif args.command == "clean":
        try:
            result = run_clean()
            sys.exit(result.returncode)
        except ValueError as e:
            print(f"Error: {e}")
            sys.exit(1)
        except Exception as e:
            print(f"Error running clean command: {e}")
            sys.exit(1)
    
    elif args.command == "install":
        try:
            result = run_install()
            sys.exit(result.returncode)
        except ValueError as e:
            print(f"Error: {e}")
            sys.exit(1)
        except Exception as e:
            print(f"Error running install command: {e}")
            sys.exit(1)
    
    elif args.command == "release":
        try:
            result = run_release()
            sys.exit(result.returncode)
        except ValueError as e:
            print(f"Error: {e}")
            sys.exit(1)
        except Exception as e:
            print(f"Error running release command: {e}")
            sys.exit(1)
    
    elif args.command == "lint":
        try:
            result = run_lint()
            sys.exit(result.returncode)
        except ValueError as e:
            print(f"Error: {e}")
            sys.exit(1)
        except Exception as e:
            print(f"Error running lint command: {e}")
            sys.exit(1)
    
    elif args.command == "format":
        try:
            result = run_format()
            sys.exit(result.returncode)
        except ValueError as e:
            print(f"Error: {e}")
            sys.exit(1)
        except Exception as e:
            print(f"Error running format command: {e}")
            sys.exit(1)
    
    elif args.command == "exec":
        try:
            result = execute_native_command(
                args.cmd,
                capture_output=args.capture,
                timeout=args.timeout
            )
            sys.exit(result.returncode)
        except Exception as e:
            print(f"Error executing command: {e}")
            sys.exit(1)
    
    elif args.command == "xcodebuild":
        try:
            builder = MacOSBuilder()
            result = builder.build_xcode_project(
                scheme=args.scheme,
                configuration=args.configuration,
                destination=args.destination
            )
            sys.exit(result.returncode)
        except Exception as e:
            print(f"Error building Xcode project: {e}")
            sys.exit(1)
    
    elif args.command == "swift-build":
        try:
            result = build_swift_package(configuration=args.configuration)
            sys.exit(result.returncode)
        except Exception as e:
            print(f"Error building Swift package: {e}")
            sys.exit(1)
    
    elif args.command == "make":
        try:
            builder = MacOSBuilder()
            result = builder.run_make(target=args.target)
            sys.exit(result.returncode)
        except Exception as e:
            print(f"Error running make: {e}")
            sys.exit(1)
    
    else:
        parser.print_help()