# ABOUTME: Docker image for Claude Code with Twilio MCP server
# ABOUTME: Provides autonomous Claude Code environment with SMS notifications

FROM node:20-slim

# Install required system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    python3 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Install Twilio MCP server
RUN npm install -g @twilioalpha/mcp-server-twilio

# Create directories for configuration
RUN mkdir -p /app/config /app/.claude

# Copy MCP configuration
COPY config/mcp-config.json /app/config/

# Copy startup script
COPY scripts/startup.sh /app/
RUN chmod +x /app/startup.sh

# Set working directory to mounted volume
WORKDIR /workspace

# Environment variables will be passed from host
ENV NODE_ENV=production

# Start both MCP server and Claude Code
ENTRYPOINT ["/app/startup.sh"]