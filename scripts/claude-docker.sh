#!/bin/bash
# ABOUTME: Wrapper script to run Claude Code in Docker container
# ABOUTME: Handles project mounting, .claude setup, and environment variables

# Get the absolute path of the current directory
CURRENT_DIR=$(pwd)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if .claude directory exists in current project, create if not
if [ ! -d "$CURRENT_DIR/.claude" ]; then
    echo "Creating .claude directory for this project..."
    mkdir -p "$CURRENT_DIR/.claude"
    
    # Copy template files
    cp "$PROJECT_ROOT/templates/.claude/CLAUDE.md" "$CURRENT_DIR/.claude/"
    
    # Create scratchpad.md if it doesn't exist
    if [ ! -f "$CURRENT_DIR/scratchpad.md" ]; then
        cp "$PROJECT_ROOT/templates/scratchpad.md" "$CURRENT_DIR/"
    fi
    
    echo "✓ Claude configuration created"
fi

# Check if .env exists in claude-docker directory for building
ENV_FILE="$PROJECT_ROOT/.env"
if [ -f "$ENV_FILE" ]; then
    echo "✓ Found .env file with credentials"
    # Source .env to get configuration variables
    set -a
    source "$ENV_FILE" 2>/dev/null || true
    set +a
else
    echo "⚠️  No .env file found at $ENV_FILE"
    echo "   Twilio MCP features will be unavailable."
    echo "   To enable: create .env in claude-docker directory with your credentials"
fi

# Check if we need to rebuild the image
NEED_REBUILD=false

if ! docker images | grep -q "claude-docker"; then
    echo "Building Claude Docker image for first time..."
    NEED_REBUILD=true
fi

if [ "$NEED_REBUILD" = true ]; then
    # Copy authentication files to build context
    if [ -f "$HOME/.claude.json" ]; then
        cp "$HOME/.claude.json" "$PROJECT_ROOT/.claude.json"
    fi
    if [ -d "$HOME/.claude" ]; then
        cp -r "$HOME/.claude" "$PROJECT_ROOT/.claude"
    fi
    
    # Get git config from host
    GIT_USER_NAME=$(git config --global --get user.name 2>/dev/null || echo "")
    GIT_USER_EMAIL=$(git config --global --get user.email 2>/dev/null || echo "")
    
    # Build docker command with conditional system packages and git config
    BUILD_ARGS="--build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g)"
    if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
        BUILD_ARGS="$BUILD_ARGS --build-arg GIT_USER_NAME=\"$GIT_USER_NAME\" --build-arg GIT_USER_EMAIL=\"$GIT_USER_EMAIL\""
    fi
    if [ -n "$SYSTEM_PACKAGES" ]; then
        echo "✓ Building with additional system packages: $SYSTEM_PACKAGES"
        BUILD_ARGS="$BUILD_ARGS --build-arg SYSTEM_PACKAGES=\"$SYSTEM_PACKAGES\""
    fi
    
    eval "docker build $BUILD_ARGS -t claude-docker:latest \"$PROJECT_ROOT\""
    
    # Clean up copied auth files
    rm -f "$PROJECT_ROOT/.claude.json"
    rm -rf "$PROJECT_ROOT/.claude"
fi

# Ensure the claude-home directory exists
mkdir -p "$HOME/.claude-docker/claude-home"

# Prepare additional mount arguments
MOUNT_ARGS=""
ENV_ARGS=""

# Mount conda installation if specified
if [ -n "$CONDA_PREFIX" ] && [ -d "$CONDA_PREFIX" ]; then
    echo "✓ Mounting conda installation from $CONDA_PREFIX"
    MOUNT_ARGS="$MOUNT_ARGS -v $CONDA_PREFIX:$CONDA_PREFIX:ro"
    ENV_ARGS="$ENV_ARGS -e CONDA_PREFIX=$CONDA_PREFIX -e CONDA_EXE=$CONDA_PREFIX/bin/conda"
else
    echo "No conda installation configured"
fi

# Mount additional conda directories if specified
if [ -n "$CONDA_EXTRA_DIRS" ]; then
    echo "✓ Mounting additional conda directories..."
    CONDA_ENVS_PATHS=""
    CONDA_PKGS_PATHS=""
    for dir in $CONDA_EXTRA_DIRS; do
        if [ -d "$dir" ]; then
            echo "  - Mounting $dir"
            MOUNT_ARGS="$MOUNT_ARGS -v $dir:$dir:ro"
            # Build comma-separated list for CONDA_ENVS_DIRS
            if [[ "$dir" == *"env"* ]]; then
                if [ -z "$CONDA_ENVS_PATHS" ]; then
                    CONDA_ENVS_PATHS="$dir"
                else
                    CONDA_ENVS_PATHS="$CONDA_ENVS_PATHS:$dir"
                fi
            fi
            # Build comma-separated list for CONDA_PKGS_DIRS
            if [[ "$dir" == *"pkg"* ]]; then
                if [ -z "$CONDA_PKGS_PATHS" ]; then
                    CONDA_PKGS_PATHS="$dir"
                else
                    CONDA_PKGS_PATHS="$CONDA_PKGS_PATHS:$dir"
                fi
            fi
        else
            echo "  - Skipping $dir (not found)"
        fi
    done
    # Set CONDA_ENVS_DIRS environment variable if we found env paths
    if [ -n "$CONDA_ENVS_PATHS" ]; then
        ENV_ARGS="$ENV_ARGS -e CONDA_ENVS_DIRS=$CONDA_ENVS_PATHS"
        echo "  - Setting CONDA_ENVS_DIRS=$CONDA_ENVS_PATHS"
    fi
    # Set CONDA_PKGS_DIRS environment variable if we found pkg paths
    if [ -n "$CONDA_PKGS_PATHS" ]; then
        ENV_ARGS="$ENV_ARGS -e CONDA_PKGS_DIRS=$CONDA_PKGS_PATHS"
        echo "  - Setting CONDA_PKGS_DIRS=$CONDA_PKGS_PATHS"
    fi
else
    echo "No additional conda directories configured"
fi

# Run Claude Code in Docker
echo "Starting Claude Code in Docker..."
docker run -it --rm \
    -v "$CURRENT_DIR:/workspace" \
    -v "$HOME/.claude-docker/claude-home:/home/claude-user/.claude:rw" \
    $MOUNT_ARGS \
    $ENV_ARGS \
    --workdir /workspace \
    --name "claude-docker-$(basename "$CURRENT_DIR")-$$" \
    claude-docker:latest "$@"