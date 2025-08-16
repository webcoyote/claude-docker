#!/bin/bash
# ABOUTME: Setup script for macOS native build SSH keys
# ABOUTME: Configures SSH keys for container-to-host communication

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}macOS Native Build SSH Setup${NC}"
echo "This script will configure SSH keys for container-to-host communication."
echo ""

# Check if we're on macOS
if [ "$(uname)" != "Darwin" ]; then
    echo -e "${RED}Error: This script must be run on macOS${NC}"
    exit 1
fi

# Define paths
CLAUDE_DOCKER_DIR="$HOME/.claude-docker"
SSH_DIR="$CLAUDE_DOCKER_DIR/ssh"
HOST_KEYS_DIR="$SSH_DIR/host_keys"
PRIVATE_KEY="$HOST_KEYS_DIR/id_rsa"
PUBLIC_KEY="$HOST_KEYS_DIR/id_rsa.pub"
AUTHORIZED_KEYS="$HOME/.ssh/authorized_keys"

# Create directories
echo "Creating SSH directories..."
mkdir -p "$HOST_KEYS_DIR"
mkdir -p "$HOME/.ssh"

# Generate SSH key pair if it doesn't exist
if [ ! -f "$PRIVATE_KEY" ] || [ ! -f "$PUBLIC_KEY" ]; then
    echo -e "${YELLOW}Generating SSH key pair for container-to-host communication...${NC}"
    ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY" -N '' -C "claude-docker-host-access"
    echo -e "${GREEN}✓ SSH key pair generated${NC}"
else
    echo -e "${GREEN}✓ SSH key pair already exists${NC}"
fi

# Set proper permissions
chmod 600 "$PRIVATE_KEY"
chmod 644 "$PUBLIC_KEY"

# Add public key to authorized_keys
echo "Adding public key to authorized_keys..."
if [ ! -f "$AUTHORIZED_KEYS" ]; then
    touch "$AUTHORIZED_KEYS"
    chmod 600 "$AUTHORIZED_KEYS"
fi

# Check if the key is already in authorized_keys
PUBLIC_KEY_CONTENT=$(cat "$PUBLIC_KEY")
if ! grep -Fq "$PUBLIC_KEY_CONTENT" "$AUTHORIZED_KEYS"; then
    echo "$PUBLIC_KEY_CONTENT" >> "$AUTHORIZED_KEYS"
    echo -e "${GREEN}✓ Public key added to authorized_keys${NC}"
else
    echo -e "${GREEN}✓ Public key already in authorized_keys${NC}"
fi

# Check if Remote Login is enabled
echo "Checking macOS Remote Login status..."
REMOTE_LOGIN_STATUS=$(sudo systemsetup -getremotelogin 2>/dev/null | grep -o "On\|Off")

if [ "$REMOTE_LOGIN_STATUS" = "On" ]; then
    echo -e "${GREEN}✓ Remote Login is enabled${NC}"
else
    echo -e "${YELLOW}⚠️  Remote Login is disabled${NC}"
    echo ""
    echo "To enable Remote Login:"
    echo "1. Go to System Preferences/Settings > Sharing"
    echo "2. Enable 'Remote Login'"
    echo "3. Or run: sudo systemsetup -setremotelogin on"
    echo ""
    read -p "Would you like to enable Remote Login now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Enabling Remote Login..."
        sudo systemsetup -setremotelogin on
        echo -e "${GREEN}✓ Remote Login enabled${NC}"
    else
        echo -e "${YELLOW}⚠️  Remote Login remains disabled. Native macOS builds will not work.${NC}"
    fi
fi

# Test SSH connection
echo ""
echo "Testing SSH connection..."
USERNAME=$(whoami)
SSH_TEST_CMD="ssh -i $PRIVATE_KEY -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR $USERNAME@localhost echo 'SSH test successful'"

if eval "$SSH_TEST_CMD" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ SSH connection test successful${NC}"
else
    echo -e "${RED}✗ SSH connection test failed${NC}"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Ensure Remote Login is enabled in System Preferences > Sharing"
    echo "2. Check that your user account allows SSH access"
    echo "3. Verify authorized_keys file permissions: chmod 600 ~/.ssh/authorized_keys"
    echo "4. Check SSH service: sudo launchctl list | grep ssh"
    echo ""
    echo "Manual test command:"
    echo "$SSH_TEST_CMD"
    exit 1
fi

# Create SSH config for container
SSH_CONFIG="$HOST_KEYS_DIR/config"
cat > "$SSH_CONFIG" << EOF
Host host.docker.internal
    HostName host.docker.internal
    User $USERNAME
    IdentityFile ~/.ssh/host_keys/id_rsa
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR

Host localhost
    HostName localhost
    User $USERNAME
    IdentityFile ~/.ssh/host_keys/id_rsa
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF

echo -e "${GREEN}✓ SSH config created for container${NC}"

# Update .env file if it exists
ENV_FILE="$(dirname "$(dirname "$0")")/.env"
if [ -f "$ENV_FILE" ]; then
    echo ""
    echo "Updating .env file with macOS build settings..."
    
    # Check if ENABLE_MACOS_BUILDS is already in .env
    if grep -q "ENABLE_MACOS_BUILDS" "$ENV_FILE"; then
        # Update existing line
        sed -i.backup "s/^ENABLE_MACOS_BUILDS=.*/ENABLE_MACOS_BUILDS=true/" "$ENV_FILE"
    else
        # Add new line
        echo "" >> "$ENV_FILE"
        echo "# macOS Native Build Support" >> "$ENV_FILE"
        echo "ENABLE_MACOS_BUILDS=true" >> "$ENV_FILE"
    fi
    
    # Check if MACOS_USERNAME is already in .env
    if grep -q "MACOS_USERNAME" "$ENV_FILE"; then
        # Update existing line
        sed -i.backup "s/^MACOS_USERNAME=.*/MACOS_USERNAME=$USERNAME/" "$ENV_FILE"
    else
        echo "MACOS_USERNAME=$USERNAME" >> "$ENV_FILE"
    fi
    
    echo -e "${GREEN}✓ .env file updated${NC}"
    echo -e "${YELLOW}⚠️  You must rebuild the Docker image: claude-docker --rebuild${NC}"
fi

echo ""
echo -e "${GREEN}✓ macOS SSH setup complete!${NC}"
echo ""
echo "Summary:"
echo "  • SSH key pair: $HOST_KEYS_DIR/"
echo "  • Public key added to: $AUTHORIZED_KEYS"
echo "  • SSH config: $SSH_CONFIG"
echo "  • Username: $USERNAME"
echo ""
echo "Next steps:"
echo "1. Rebuild Docker image: claude-docker --rebuild"
echo "2. Test native builds from container:"
echo "   python3 ~/scripts/macos_builder.py status"
echo "   python3 ~/scripts/macos_builder.py test"
echo ""
echo "Example usage in Claude:"
echo '  from macos_builder import execute_native_command'
echo '  result = execute_native_command("xcodebuild -version")'