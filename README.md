# Claude Docker

A Docker container setup for running Claude Code with full autonomous permissions and SMS notifications via Twilio MCP integration.

## What This Does

- Runs Claude Code in an isolated Docker container with full autonomy
- Integrates Twilio MCP for SMS notifications when tasks complete
- Provides persistent context across sessions via scratchpad files
- Auto-configures Claude settings for seamless operation
- Simple one-command setup and usage

## Prerequisites

**Important**: Before building the Docker image, you must authenticate Claude Code on your host system:
1. Install Claude Code: `npm install -g @anthropic-ai/claude-code`
2. Run `claude` and complete the authentication flow
3. Verify authentication files exist: `ls ~/.claude.json ~/.claude/`

The Docker build will copy your authentication from these locations.

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/VishalJ99/claude-docker.git
   cd claude-docker
   ```

2. **Configure your API keys:**
   ```bash
   # Copy the example file
   cp .env.example .env
   
   # Edit .env with your credentials
   nano .env
   ```
   
   Add your credentials to the `.env` file:
   ```bash
   ANTHROPIC_API_KEY=your_anthropic_key
   
   # For Twilio MCP integration (optional):
   TWILIO_ACCOUNT_SID=your_twilio_sid  
   TWILIO_AUTH_TOKEN=your_twilio_auth_token
   TWILIO_FROM_NUMBER=your_twilio_number
   TWILIO_TO_NUMBER=your_phone_number
   ```
   
   > **Important**: The `.env` file will be baked into the Docker image during build. This means:
   > - Your credentials are embedded in the image
   > - You can use the image from any directory without needing the .env file
   > - Keep your image secure since it contains your credentials
   
   > **Note**: Twilio MCP uses Account SID and Auth Token. You can find these in your Twilio Console.

3. **Build and install:**
   ```bash
   ./scripts/install.sh
   ```
   
   This will:
   - Build the Docker image with your credentials baked in
   - Install the `claude-docker` command to your PATH

4. **Use from any project directory:**
   ```bash
   claude-docker
   ```

## Usage Patterns

### One-Time Setup Per Project
For the best experience, run `claude-docker` once per project and leave it running:

1. **Start Claude Docker:**
   ```bash
   cd your-project
   claude-docker
   ```

2. **Detach from the session (keep it running):**
   - **Mac/Linux**: `Ctrl + P`, then `Ctrl + Q`
   - Hold Control key, press P, then Q while still holding Control
   - Container keeps running in background

3. **Reattach when needed:**
   ```bash
   docker ps                           # Find your container ID
   docker attach claude-docker-session # Reattach to the session
   ```

4. **Stop when done with project:**
   ```bash
   docker stop claude-docker-session
   ```

This workflow gives you:
- ✅ Persistent authentication (login once per machine)
- ✅ Persistent project context (one session per project)  
- ✅ Perfect file permissions between host and container
- ✅ No repeated setup or authentication

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
- Automatic UID/GID mapping ensures perfect file permissions between host and container

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
└── templates/
    └── scratchpad.md     # Template for project context
```

## Configuration

During build, the `.env` file from the claude-docker directory is baked into the image:
- Credentials are embedded at `/app/.env` inside the container
- No need to manage .env files in each project
- The image contains everything needed to run

The setup creates `~/.claude-docker/` in your home directory with:
- `claude-home/` - Persistent Claude authentication and settings
- `config/` - MCP server configuration

Each project gets:
- `.claude/settings.json` - Claude Code settings with MCP
- `.claude/CLAUDE.md` - Instructions for Claude behavior
- `scratchpad.md` - Project context file

### Rebuilding the Image

The Docker image is built only once when you first run `claude-docker`. To force a rebuild:

```bash
# Remove the existing image
docker rmi claude-docker:latest

# Next run of claude-docker will rebuild
claude-docker
```

Rebuild when you:
- Update your .env file with new credentials
- Update the Claude Docker repository
- Want to refresh the authentication files

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