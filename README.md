# Claude Docker

A Docker container setup for running Claude Code with full autonomous permissions and SMS notifications via Twilio MCP integration.

## What This Does

- Runs Claude Code in an isolated Docker container with full autonomy
- Integrates Twilio MCP for SMS notifications when tasks complete
- Provides persistent context across sessions via scratchpad files
- Auto-configures Claude settings for seamless operation
- Simple one-command setup and usage

## Quick Start

1. **Clone and install:**
   ```bash
   git clone https://github.com/VishalJ99/claude-docker.git
   cd claude-docker
   ./scripts/install.sh
   ```

2. **Configure your API keys:**
   ```bash
   # Edit ~/.claude-docker/.env with your keys
   ANTHROPIC_API_KEY=your_anthropic_key
   
   # For Twilio MCP integration:
   TWILIO_ACCOUNT_SID=your_twilio_sid  
   TWILIO_API_KEY=your_twilio_api_key
   TWILIO_API_SECRET=your_twilio_api_secret
   TWILIO_FROM_NUMBER=your_twilio_number
   TWILIO_TO_NUMBER=your_phone_number
   ```
   
   > **Note**: Twilio MCP requires API Key/Secret instead of Auth Token. Create API keys in your Twilio Console under Account → API keys & tokens.

3. **Use from any project directory:**
   ```bash
   claude-docker
   ```

## Features

### 🤖 Full Autonomy
- Claude runs with `--dangerously-skip-permissions` for complete access
- Can read, write, execute, and modify any files in your project
- No permission prompts or restrictions

### 📱 SMS Notifications  
- Automatic SMS via Twilio when Claude completes tasks
- Configurable via MCP integration
- Optional - works without if Twilio not configured

### 🗂️ Context Persistence
- Maintains scratchpad.md files for project memory
- Persistent across container sessions
- Helps Claude remember project context

### 🔑 Authentication Persistence
- Login once, use forever - authentication tokens persist across sessions
- No need to re-authenticate every time you start claude-docker
- Credentials stored securely in `~/.claude-docker/claude-home`

### 🐳 Clean Environment
- Each session runs in fresh Docker container
- Container auto-removes on exit
- No system pollution or conflicts

## How It Works

1. **Wrapper Script**: `claude-docker.sh` handles container lifecycle
2. **Auto-Setup**: Creates `.claude` directory with proper config on first run
3. **MCP Integration**: Twilio MCP server runs alongside Claude Code
4. **Project Mounting**: Your project directory mounts to `/workspace`
5. **Clean Exit**: Container removes itself when Claude session ends

## Directory Structure

```
claude-docker/
├── Dockerfile              # Main container definition
├── scripts/
│   ├── claude-docker.sh   # Wrapper script for container
│   ├── install.sh         # Installation script  
│   └── startup.sh         # Container startup script
├── config/
│   └── mcp-config.json   # MCP server configuration
└── templates/
    └── scratchpad.md     # Template for project context
```

## Configuration

The setup creates `~/.claude-docker/` with:
- `.env` - API keys and configuration
- `claude-home/` - Persistent Claude authentication and settings
- `config/` - MCP server configuration

Each project gets:
- `.claude/settings.json` - Claude Code settings with MCP
- `.claude/CLAUDE.md` - Instructions for Claude behavior
- `scratchpad.md` - Project context file

## Requirements

- Docker installed and running
- Anthropic API key (or Claude subscription)
- (Optional) Twilio account with API Key/Secret for SMS notifications

## Next Steps

**Phase 2 - Security Enhancements:**
- Network firewall to whitelist only essential domains
- Shell history persistence between sessions
- Additional security features

## Repository

https://github.com/VishalJ99/claude-docker