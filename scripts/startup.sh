#!/bin/bash
# ABOUTME: Startup script for Claude Code container with MCP server
# ABOUTME: Configures environment and starts Claude Code with Twilio MCP integration

# Load environment variables from .env if it exists
# Use the .env file baked into the image at build time
if [ -f /app/.env ]; then
    echo "Loading credentials from baked-in .env file"
    set -a
    source /app/.env 2>/dev/null || true
    set +a
    
    # Export Twilio variables for MCP server
    export TWILIO_ACCOUNT_SID
    export TWILIO_API_KEY
    export TWILIO_API_SECRET
    export TWILIO_FROM_NUMBER
    export TWILIO_TO_NUMBER
else
    echo "WARNING: No .env file found in image. Twilio features will be unavailable."
    echo "To enable Twilio: create .env in claude-docker directory before building the image."
fi

# Configure Claude Code to use the MCP server
export CLAUDE_MCP_CONFIG=/app/config/mcp-config.json

# Check for existing authentication
if [ -f "$HOME/.claude/.credentials.json" ]; then
    echo "Found existing Claude authentication"
else
    echo "No existing authentication found - you will need to log in"
    echo "Your login will be saved for future sessions"
fi

# Verify Twilio MCP configuration
if [ -n "$TWILIO_ACCOUNT_SID" ] && [ -n "$TWILIO_API_KEY" ] && [ -n "$TWILIO_API_SECRET" ]; then
    echo "Twilio MCP pre-configured with:"
    echo "  - Account SID: ${TWILIO_ACCOUNT_SID:0:10}..."
    echo "  - From Number: $TWILIO_FROM_NUMBER"
    echo "  - To Number: $TWILIO_TO_NUMBER"
    echo "  - MCP Config: $CLAUDE_MCP_CONFIG"
else
    echo "No Twilio credentials found, MCP features will be unavailable"
fi

# Start Claude Code with permissions bypass
echo "Starting Claude Code..."
exec claude --dangerously-skip-permissions "$@"