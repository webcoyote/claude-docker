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

# Check if .env file exists in user's home claude-docker directory
ENV_FILE="$HOME/.claude-docker/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "⚠️  No .env file found at $ENV_FILE"
    echo "Please create it with your API keys. See .env.example for reference."
    exit 1
fi

# Build the Docker image if it doesn't exist
if ! docker images | grep -q "claude-docker"; then
    echo "Building Claude Docker image..."
    docker build -t claude-docker:latest "$PROJECT_ROOT"
fi

# Ensure the claude-home directory exists
mkdir -p "$HOME/.claude-docker/claude-home"

# Run Claude Code in Docker
echo "Starting Claude Code in Docker..."
docker run -it --rm \
    -v "$CURRENT_DIR:/workspace" \
    -v "$ENV_FILE:/app/.env:ro" \
    -v "$HOME/.claude-docker/config:/app/.claude:rw" \
    -v "$HOME/.claude-docker/claude-home:/home/claude-user/.claude:rw" \
    --workdir /workspace \
    --name claude-docker-session \
    claude-docker:latest "$@"