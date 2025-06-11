#!/bin/bash
# ABOUTME: Startup script for Claude Code container with MCP server
# ABOUTME: Launches Twilio MCP server then starts Claude Code with permissions bypass

# Load environment variables from .env if it exists
if [ -f /app/.env ]; then
    export $(cat /app/.env | grep -v '^#' | xargs)
fi

# Start Twilio MCP server in the background
echo "Starting Twilio MCP server..."
npx @twilioalpha/mcp-server-twilio &
MCP_PID=$!

# Give MCP server time to start
sleep 2

# Configure Claude Code to use the MCP server
export CLAUDE_MCP_CONFIG=/app/config/mcp-config.json

# Start Claude Code with permissions bypass
echo "Starting Claude Code..."
exec claude-code --dangerously-skip-permissions "$@"