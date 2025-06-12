#!/bin/bash
# ABOUTME: Startup script for Claude Code container with MCP server
# ABOUTME: Configures environment and starts Claude Code with Twilio MCP integration

# Load environment variables from .env if it exists
if [ -f /app/.env ]; then
    set -a
    source /app/.env 2>/dev/null || true
    set +a
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

# Start Claude Code with permissions bypass
echo "Starting Claude Code..."
if [ -n "$TWILIO_ACCOUNT_SID" ] && [ -n "$TWILIO_API_KEY" ]; then
    echo "Twilio MCP integration enabled"
else
    echo "No Twilio credentials found, MCP features will be unavailable"
fi
exec claude --dangerously-skip-permissions "$@"