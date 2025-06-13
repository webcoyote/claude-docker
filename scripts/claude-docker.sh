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
    cp "$PROJECT_ROOT/templates/.claude/settings.local.json" "$CURRENT_DIR/.claude/"
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
else
    echo "⚠️  No .env file found at $ENV_FILE"
    echo "   Twilio MCP features will be unavailable."
    echo "   To enable: create .env in claude-docker directory with your credentials"
fi

# Check if we need to rebuild the image
NEED_REBUILD=false

if ! docker images | grep -q "claude-docker"; then
    echo "Building Claude Docker image with your user permissions..."
    NEED_REBUILD=true
elif ! docker image inspect claude-docker:latest | grep -q "USER_UID.*$(id -u)" 2>/dev/null; then
    echo "Rebuilding Claude Docker image to match your user permissions..."
    NEED_REBUILD=true
elif [ -f "$ENV_FILE" ]; then
    # Check if .env is newer than the Docker image
    IMAGE_CREATED=$(docker inspect -f '{{.Created}}' claude-docker:latest 2>/dev/null)
    if [ -n "$IMAGE_CREATED" ]; then
        IMAGE_TIMESTAMP=$(date -d "$IMAGE_CREATED" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${IMAGE_CREATED%%.*}" +%s 2>/dev/null)
        ENV_TIMESTAMP=$(stat -c %Y "$ENV_FILE" 2>/dev/null || stat -f %m "$ENV_FILE" 2>/dev/null)
        
        if [ -n "$IMAGE_TIMESTAMP" ] && [ -n "$ENV_TIMESTAMP" ] && [ "$ENV_TIMESTAMP" -gt "$IMAGE_TIMESTAMP" ]; then
            echo "⚠️  .env file has been updated since last build"
            echo "   Rebuilding to include new credentials..."
            NEED_REBUILD=true
        fi
    fi
fi

if [ "$NEED_REBUILD" = true ]; then
    docker build --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g) -t claude-docker:latest "$PROJECT_ROOT"
fi

# Ensure the claude-home directory exists
mkdir -p "$HOME/.claude-docker/claude-home"

# Run Claude Code in Docker
echo "Starting Claude Code in Docker..."
docker run -it --rm \
    -v "$CURRENT_DIR:/workspace" \
    -v "$HOME/.claude-docker/claude-home:/home/claude-user/.claude:rw" \
    --workdir /workspace \
    --name claude-docker-session \
    claude-docker:latest "$@"