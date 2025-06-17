#!/bin/bash
# ABOUTME: Setup script to create ~/.claude-docker/.env with Twilio credentials
# ABOUTME: Run this once on your host machine to configure Twilio for all projects

CLAUDE_DOCKER_DIR="$HOME/.claude-docker"
ENV_FILE="$CLAUDE_DOCKER_DIR/.env"

# Create directory if it doesn't exist
mkdir -p "$CLAUDE_DOCKER_DIR"

# Check if .env already exists
if [ -f "$ENV_FILE" ]; then
    echo "⚠️  $ENV_FILE already exists!"
    read -p "Do you want to update it? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

echo "Setting up Twilio credentials for Claude Docker..."
echo "You'll need your Twilio account information."
echo

# Collect Twilio credentials
read -p "Enter your Twilio Account SID: " TWILIO_ACCOUNT_SID
read -sp "Enter your Twilio Auth Token: " TWILIO_AUTH_TOKEN
echo
read -p "Enter your Twilio phone number (with country code, e.g., +1234567890): " TWILIO_FROM_NUMBER
read -p "Enter the phone number to receive SMS (with country code): " TWILIO_TO_NUMBER

# Create .env file
cat > "$ENV_FILE" << EOF
# Twilio credentials for Claude Docker
TWILIO_ACCOUNT_SID=$TWILIO_ACCOUNT_SID
TWILIO_AUTH_TOKEN=$TWILIO_AUTH_TOKEN
TWILIO_FROM_NUMBER=$TWILIO_FROM_NUMBER
TWILIO_TO_NUMBER=$TWILIO_TO_NUMBER
EOF

# Set restrictive permissions
chmod 600 "$ENV_FILE"

echo
echo "✅ Twilio credentials saved to $ENV_FILE"
echo "These credentials will be available to all Claude Docker sessions."
echo
echo "To test, run claude-docker from any project directory and use:"
echo "  node /workspace/test-twilio.js"