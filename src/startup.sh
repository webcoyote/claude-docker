#!/bin/bash
# ABOUTME: Startup script for claude-docker container with MCP server
# ABOUTME: Loads twilio env vars, checks for .credentials.json, copies CLAUDE.md template if no claude.md in claude-docker/claude-home.
# ABOUTME: Starts claude code with permissions bypass and continues from last session.
# NOTE: Need to call claude-docker --rebuild to integrate changes.

# Load environment variables from .env if it exists
# Use the .env file baked into the image at build time
if [ -f /app/.env ]; then
    echo "Loading environment from baked-in .env file"
    set -a
    source /app/.env 2>/dev/null || true
    set +a
    
    # Export Twilio variables for runtime use
    export TWILIO_ACCOUNT_SID
    export TWILIO_AUTH_TOKEN
    export TWILIO_FROM_NUMBER
    export TWILIO_TO_NUMBER
else
    echo "WARNING: No .env file found in image."
fi

# Check for existing authentication
if [ -f "$HOME/.claude/.credentials.json" ]; then
    echo "Found existing Claude authentication"
else
    echo "No existing authentication found - you will need to log in"
    echo "Your login will be saved for future sessions"
fi

# Handle CLAUDE.md template
if [ ! -f "$HOME/.claude/CLAUDE.md" ]; then
    echo "✓ No CLAUDE.md found at $HOME/.claude/CLAUDE.md - copying template"
    # Copy from the template that was baked into the image
    if [ -f "/app/.claude/CLAUDE.md" ]; then
        cp "/app/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    elif [ -f "/home/claude-user/.claude.template/CLAUDE.md" ]; then
        # Fallback for existing images
        cp "/home/claude-user/.claude.template/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    fi
    echo "  Template copied to: $HOME/.claude/CLAUDE.md"
else
    echo "✓ Using existing CLAUDE.md from $HOME/.claude/CLAUDE.md"
    echo "  This maps to: ~/.claude-docker/claude-home/CLAUDE.md on your host"
    echo "  To reset to template, delete this file and restart"
fi

# Handle git worktree mounting scenario
if [ "$WORKTREE_DETECTED" = "true" ]; then
    echo "✓ Git worktree environment detected"
    echo "  Main repository mounted at: $MAIN_REPO_PATH"
    echo "  Current worktree at: $WORKTREE_PATH"
    
    # Setup git worktree integration
    if [ -d "$MAIN_REPO_PATH/.git" ]; then
        echo "  Setting up git worktree integration..."
        
        if [ -f "/workspace/.git" ]; then
            # Existing .git file - update paths for container
            WORKTREE_GIT_DIR=$(cat /workspace/.git | cut -d' ' -f2)
            CONTAINER_WORKTREE_GIT_DIR=$(echo "$WORKTREE_GIT_DIR" | sed "s|$MAIN_REPO_PATH|/main-repo|g")
        elif [ -d "/main-repo/.git/worktrees" ]; then
            # Missing .git file - find and create it
            WORKTREE_NAME=$(ls /main-repo/.git/worktrees/ | head -n1)
            if [ -n "$WORKTREE_NAME" ]; then
                CONTAINER_WORKTREE_GIT_DIR="/main-repo/.git/worktrees/$WORKTREE_NAME"
                echo "  Creating missing .git file for worktree: $WORKTREE_NAME"
            fi
        fi
        
        # Create or update the .git file
        if [ -n "$CONTAINER_WORKTREE_GIT_DIR" ] && [ -d "$CONTAINER_WORKTREE_GIT_DIR" ]; then
            echo "gitdir: $CONTAINER_WORKTREE_GIT_DIR" > /workspace/.git
            echo "  ✓ Git worktree paths configured for container"
        fi
    fi
fi

# Detect and export git repository information
echo "Detecting git repository status..."
if command -v python3 >/dev/null 2>&1 && [ -f "/home/claude-user/scripts/git_utils.py" ]; then
    # Export git environment variables
    eval $(python3 /home/claude-user/scripts/git_utils.py env)
    
    # Display git status information
    if [ "$CLAUDE_GIT_IS_REPO" = "true" ]; then
        echo "✓ Git repository detected"
        echo "  Root: $CLAUDE_GIT_ROOT_PATH"
        echo "  Branch: $CLAUDE_GIT_CURRENT_BRANCH"
        
        if [ "$CLAUDE_GIT_IS_WORKTREE" = "true" ]; then
            echo "✓ Git worktree detected"
            echo "  Main worktree: $CLAUDE_GIT_MAIN_WORKTREE"
            echo "  Total worktrees: $CLAUDE_GIT_WORKTREE_COUNT"
        fi
        
        if [ -n "$CLAUDE_GIT_REMOTE_URL" ]; then
            echo "  Remote: $CLAUDE_GIT_REMOTE_URL"
        fi
        
        # Test git functionality
        echo "  Testing git operations..."
        if git status >/dev/null 2>&1; then
            echo "  ✓ Git commands working properly"
        else
            echo "  ⚠️  Git commands may have issues"
        fi
    else
        echo "No git repository detected in current directory"
    fi
else
    echo "Git detection unavailable - git_utils.py not found"
fi

# Check macOS native build availability and project configuration
echo "Checking macOS native build support..."
if [ "${ENABLE_MACOS_BUILDS:-false}" = "true" ]; then
    if command -v python3 >/dev/null 2>&1 && [ -f "/home/claude-user/scripts/macos_builder.py" ]; then
        # Test macOS build availability and load project configuration
        BUILD_STATUS=$(python3 /home/claude-user/scripts/macos_builder.py status 2>/dev/null)
        if echo "$BUILD_STATUS" | grep -q "Connection Available: True"; then
            echo "✓ macOS native builds available"
            echo "  SSH connection to host verified"
            if [ -n "$MACOS_USERNAME" ]; then
                echo "  Username: $MACOS_USERNAME"
            fi
            
            # Show project type if detected
            PROJECT_TYPE=$(echo "$BUILD_STATUS" | grep "Project Type:" | cut -d: -f2- | xargs)
            if [ -n "$PROJECT_TYPE" ]; then
                echo "  Project type: $PROJECT_TYPE"
            fi
            
            # Show configured build commands
            CONFIGURED_COMMANDS=$(echo "$BUILD_STATUS" | grep "Configured Commands:" | cut -d: -f2- | xargs)
            if [ -n "$CONFIGURED_COMMANDS" ]; then
                echo "  Available commands: $CONFIGURED_COMMANDS"
                echo "  Usage: python3 ~/scripts/macos_builder.py [command]"
                echo "  Examples: 'run the build', 'start dev mode', 'run tests'"
            else
                echo "  No build commands configured"
                echo "  Create .env file or claude-build.json in project directory"
                echo "  Or commands will be auto-detected from project structure"
            fi
        else
            echo "⚠️  macOS native builds configured but not available"
            echo "  SSH connection to host failed"
            echo "  Run: python3 ~/scripts/macos_builder.py status (for details)"
        fi
    else
        echo "⚠️  macOS native builds enabled but macos_builder.py not found"
    fi
else
    echo "macOS native builds disabled (set ENABLE_MACOS_BUILDS=true to enable)"
fi

# Verify Twilio MCP configuration
if [ -n "$TWILIO_ACCOUNT_SID" ] && [ -n "$TWILIO_AUTH_TOKEN" ]; then
    echo "✓ Twilio MCP server configured - SMS notifications enabled"
else
    echo "No Twilio credentials found - SMS notifications disabled"
fi

# # Export environment variables from settings.json
# # This is a workaround for Docker container not properly exposing these to Claude
# if [ -f "$HOME/.claude/settings.json" ] && command -v jq >/dev/null 2>&1; then
#     echo "Loading environment variables from settings.json..."
#     # First remove comments from JSON, then extract env vars
#     # Using sed to remove // comments before parsing with jq
#     while IFS='=' read -r key value; do
#         if [ -n "$key" ] && [ -n "$value" ]; then
#             export "$key=$value"
#             echo "  Exported: $key=$value"
#         fi
#     done < <(sed 's://.*$::g' "$HOME/.claude/settings.json" | jq -r '.env // {} | to_entries | .[] | "\(.key)=\(.value)"' 2>/dev/null)
# fi

# Start Claude Code with permissions bypass
echo "Starting Claude Code..."
exec claude $CLAUDE_CONTINUE_FLAG --dangerously-skip-permissions "$@"