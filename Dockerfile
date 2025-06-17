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

# Create a non-root user with matching host UID/GID
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd -g $USER_GID claude-user && \
    useradd -m -s /bin/bash -u $USER_UID -g $USER_GID claude-user && \
    echo "claude-user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create app directory
WORKDIR /app

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Ensure npm global bin is in PATH
ENV PATH="/usr/local/bin:${PATH}"

# Create directories for configuration
RUN mkdir -p /app/.claude /home/claude-user/.claude

# Copy startup script
COPY scripts/startup.sh /app/
RUN chmod +x /app/startup.sh

# Copy .env file during build to bake credentials into the image
# This enables one-time setup - no need for .env in project directories
COPY .env /app/.env

# Set proper ownership
RUN chown -R claude-user:claude-user /app /home/claude-user

# Switch to non-root user
USER claude-user

# Configure MCP server during build if Twilio credentials are provided
RUN bash -c 'source /app/.env && \
    if [ -n "$TWILIO_ACCOUNT_SID" ] && [ -n "$TWILIO_AUTH_TOKEN" ]; then \
        echo "Configuring Twilio MCP server..." && \
        /usr/local/bin/claude mcp add-json twilio \
        "{\"command\":\"npx\",\"args\":[\"-y\",\"@yiyang.1i/sms-mcp-server\"],\"env\":{\"ACCOUNT_SID\":\"$TWILIO_ACCOUNT_SID\",\"AUTH_TOKEN\":\"$TWILIO_AUTH_TOKEN\",\"FROM_NUMBER\":\"$TWILIO_FROM_NUMBER\"}}"; \
    else \
        echo "No Twilio credentials found, skipping MCP configuration"; \
    fi'

# Set working directory to mounted volume
WORKDIR /workspace

# Environment variables will be passed from host
ENV NODE_ENV=production
ENV HOME=/home/claude-user

# Start both MCP server and Claude Code
ENTRYPOINT ["/app/startup.sh"]