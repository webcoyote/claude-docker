# Claude Docker

A Docker container setup for running Claude Code with full autonomous permissions and SMS notifications via Twilio MCP integration.

## What This Does

- Runs Claude Code in an isolated Docker container with full autonomy
- Integrates Twilio MCP for SMS notifications when tasks complete
- Provides persistent context across sessions
- Auto-configures Claude settings for seamless operation
- Simple one-command setup and usage

## Prerequisites

⚠️ **IMPORTANT**: Complete these steps BEFORE using claude-docker:

### 1. Claude Code Authentication (Required)
You must authenticate Claude Code on your host system first:
```bash
# Install Claude Code globally
npm install -g @anthropic-ai/claude-code

# Run and complete authentication
claude

# Verify authentication files exist
ls ~/.claude.json ~/.claude/
```

📖 **Full Claude Code Setup Guide**: https://docs.anthropic.com/en/docs/claude-code

### 2. Docker Installation (Required)
- **Docker Desktop**: https://docs.docker.com/get-docker/
- Ensure Docker daemon is running before proceeding

### 3. Git Configuration (Required)
For any git commits made inside the container, you'll need to provide:
- Your name and email address
- These will be configured in the `.env` file
- Used for `git config --global user.name` and `git config --global user.email`

### 4. Twilio Account (Optional - for SMS notifications)
If you want SMS notifications when tasks complete:
- Create free trial account: https://www.twilio.com/docs/usage/tutorials/how-to-use-your-free-trial-account
- Get your Account SID and Auth Token from the Twilio Console
- Get a phone number for sending SMS

### Why Pre-authentication?
The Docker container needs your existing Claude authentication to function. This approach:
- ✅ Uses your existing Claude subscription/API access
- ✅ Maintains secure credential handling
- ✅ Enables persistent authentication across container restarts

## Quick Start

```bash
# 1. Clone and enter directory
git clone https://github.com/VishalJ99/claude-docker.git
cd claude-docker

# 2. Setup environment
cp .env.example .env
nano .env  # Add your API keys (see below)

# 3. Install
./scripts/install.sh

# 4. Run from any project
cd ~/your-project
claude-docker
```

### Environment Variables (.env)
```bash
# Required
ANTHROPIC_API_KEY=your_anthropic_key

# Required - Git configuration for commits
GIT_USER_NAME=Your Name
GIT_USER_EMAIL=your.email@example.com

# Optional - SMS notifications
TWILIO_ACCOUNT_SID=your_twilio_sid  
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_FROM_NUMBER=+1234567890
TWILIO_TO_NUMBER=+0987654321

# Optional - Custom conda paths
CONDA_PREFIX=/path/to/your/conda
CONDA_EXTRA_DIRS="/path/to/envs /path/to/pkgs"

# Optional - System packages
SYSTEM_PACKAGES="libopenslide0 libgdal-dev"
```

⚠️ **Security Note**: Credentials are baked into the Docker image. Keep your image secure!

## How This Differs from Anthropic's DevContainer

We provide a different approach than [Anthropic's official .devcontainer](https://github.com/anthropics/claude-code/tree/main/.devcontainer):

| Feature | claude-docker | Anthropic's DevContainer |
|---------|--------------|-------------------------|
| **IDE Integration** | Standalone - works with any editor | VSCode-specific |
| **Authentication** | Persistent across all projects | Per-devcontainer |
| **Security Model** | Full autonomy (dangerously-skip-permissions) | Restrictive firewall whitelist |
| **Network Access** | Unrestricted | Limited to specific domains |
| **Conda Support** | Full integration with custom paths | Standard Node.js environment |
| **SMS Notifications** | Built-in Twilio MCP | Not included |
| **Setup Complexity** | One-time install, works everywhere | Per-project configuration |
| **Use Case** | Autonomous task execution | Secure development environment |

### When to Use Each

**Use claude-docker when you want:**
- 🚀 Maximum autonomy and flexibility
- 📱 SMS notifications for long-running tasks
- 🐍 Integration with existing conda environments
- 🔧 Quick setup without per-project configuration
- 💻 Editor/IDE independence

**Use Anthropic's DevContainer when you want:**
- 🔒 Maximum security with network restrictions
- 🆚 Deep VSCode integration
- 🛡️ Controlled environment with explicit whitelisting
- 👥 Team-standardized development environments

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

### 🐍 Conda Integration
- Supports custom conda installations (ideal for academic/lab environments)
- Mounts conda directories to preserve original paths and configurations
- Automatic environment variable configuration for seamless conda usage
- Works with environments and package caches in non-standard locations

### 🗂️ Context Persistence
- Maintains project-specific Claude configuration
- Persistent across container sessions
- Helps Claude remember project context

### 🔑 Authentication Persistence
- Login once, use forever - authentication tokens persist across sessions
- No need to re-authenticate every time you start claude-docker
- Credentials stored securely in `~/.claude-docker/claude-home`
- Automatic UID/GID mapping ensures perfect file permissions between host and container

### 🐳 Clean Environment
- Each session runs in fresh Docker container
- Only current working directory mounted (along with conda directories specified in `.env`).

## How It Works

1. **Wrapper Script**: `claude-docker.sh` handles container lifecycle
2. **Auto-Setup**: Creates `.claude` directory with proper config on first run
3. **MCP Integration**: Twilio MCP server runs alongside Claude Code
4. **Project Mounting**: Your project directory mounts to `/workspace`
5. **Clean Exit**: Container removes itself when Claude session ends

## Directory Structure

```
claude-docker/
├── Dockerfile             # Main container definition
├── .env.example           # Template for environment variables
├── scripts/
│   ├── claude-docker.sh   # Wrapper script for container
│   ├── install.sh         # Installation script  
│   └── startup.sh         # Container startup script
└── templates/
    └── .claude/
        └── CLAUDE.md      # Claude behavior instructions
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

### Conda Configuration

For custom conda installations (common in academic/lab environments), add these to your `.env` file:

```bash
# Main conda installation
CONDA_PREFIX=/vol/lab/username/miniconda3

# Additional conda directories (space-separated)
CONDA_EXTRA_DIRS="/vol/lab/username/.conda/envs /vol/lab/username/conda_envs /vol/lab/username/.conda/pkgs /vol/lab/username/conda_pkgs"
```

**How it works:**
- `CONDA_PREFIX`: Mounts your conda installation to the same path in container
- `CONDA_EXTRA_DIRS`: Mounts additional directories and automatically configures conda

**Automatic Detection:**
- Paths containing `*env*` → Added to `CONDA_ENVS_DIRS` (conda environment search)
- Paths containing `*pkg*` → Added to `CONDA_PKGS_DIRS` (package cache search)

**Result:** All your conda environments and packages work exactly as they do on your host system.

### System Package Installation

For scientific computing packages that require system libraries, add them to your `.env` file:

```bash
# Install OpenSlide for medical imaging
SYSTEM_PACKAGES="libopenslide0"

# Install multiple packages (space-separated)
SYSTEM_PACKAGES="libopenslide0 libgdal-dev libproj-dev libopencv-dev"
```

**Note:** Adding system packages requires rebuilding the Docker image (`docker rmi claude-docker:latest`).


## Next Steps

**Phase 2 - Security Enhancements:**
- Network firewall to whitelist only essential domains
- Shell history persistence between sessions
- Additional security features

## Attribution & Dependencies

### Core Dependencies
- **Claude Code**: Anthropic's official CLI - https://github.com/anthropics/claude-code
- **Twilio MCP Server**: SMS integration by @yiyang.1i - https://github.com/yiyang1i/sms-mcp-server
- **Docker**: Container runtime - https://www.docker.com/

### Inspiration & References
- Anthropic's DevContainer implementation: https://github.com/anthropics/claude-code/tree/main/.devcontainer
- MCP (Model Context Protocol): https://modelcontextprotocol.io/

### Created By
- **Repository**: https://github.com/VishalJ99/claude-docker
- **Author**: Vishal J (@VishalJ99)

## License

This project is open source. See the LICENSE file for details.