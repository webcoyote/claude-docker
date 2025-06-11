#!/bin/bash
# ABOUTME: Installation script for claude-docker
# ABOUTME: Sets up alias and creates config directory

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Create config directory
mkdir -p "$HOME/.claude-docker/config"

# Copy example env file if doesn't exist
if [ ! -f "$HOME/.claude-docker/.env" ]; then
    cp "$PROJECT_ROOT/.env.example" "$HOME/.claude-docker/.env"
    echo "⚠️  Created .env file at $HOME/.claude-docker/.env"
    echo "   Please edit it with your API keys!"
fi

# Add alias to .zshrc
ALIAS_LINE="alias claude='$PROJECT_ROOT/scripts/claude-docker.sh'"

if ! grep -q "alias claude=" "$HOME/.zshrc"; then
    echo "" >> "$HOME/.zshrc"
    echo "# Claude Docker alias" >> "$HOME/.zshrc"
    echo "$ALIAS_LINE" >> "$HOME/.zshrc"
    echo "✓ Added 'claude' alias to .zshrc"
else
    echo "✓ Claude alias already exists in .zshrc"
fi

# Make scripts executable
chmod +x "$PROJECT_ROOT/scripts/claude-docker.sh"
chmod +x "$PROJECT_ROOT/scripts/startup.sh"

echo ""
echo "Installation complete! 🎉"
echo ""
echo "Next steps:"
echo "1. Edit $HOME/.claude-docker/.env with your API keys"
echo "2. Run 'source ~/.zshrc' or start a new terminal"
echo "3. Navigate to any project and run 'claude' to start"