#!/bin/bash
# ABOUTME: Startup script for Claude Code container with MCP server
# ABOUTME: Loads environment and starts Claude Code with pre-configured Twilio MCP

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

# Verify Twilio MCP configuration
if [ -n "$TWILIO_ACCOUNT_SID" ] && [ -n "$TWILIO_AUTH_TOKEN" ]; then
    echo "✓ Twilio MCP server configured - SMS notifications enabled"
else
    echo "No Twilio credentials found - SMS notifications disabled"
fi

# Git configuration is handled during Docker build from host git config

# Start Claude Code with permissions bypass
echo "Starting Claude Code..."
exec claude --dangerously-skip-permissions "$@"