# ABOUTME: Docker image for Claude Code with Twilio MCP server
# ABOUTME: Provides autonomous Claude Code environment with SMS notifications

FROM node:20-slim

# Install required system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    python3 \
    build-essential \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -s /bin/bash claude-user && \
    echo "claude-user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create app directory
WORKDIR /app

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Ensure npm global bin is in PATH
ENV PATH="/usr/local/bin:${PATH}"

# Install Twilio MCP server
RUN npm install -g @twilio-alpha/mcp

# Create directories for configuration
RUN mkdir -p /app/config /app/.claude /home/claude-user/.claude

# Copy MCP configuration
COPY config/mcp-config.json /app/config/

# Copy startup script
COPY scripts/startup.sh /app/
RUN chmod +x /app/startup.sh

# Set proper ownership
RUN chown -R claude-user:claude-user /app /home/claude-user

# Switch to non-root user
USER claude-user

# Set working directory to mounted volume
WORKDIR /workspace

# Environment variables will be passed from host
ENV NODE_ENV=production
ENV HOME=/home/claude-user

# Start both MCP server and Claude Code
ENTRYPOINT ["/app/startup.sh"]