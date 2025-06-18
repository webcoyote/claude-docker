# Claude Docker

A Docker container setup for running Claude Code with full autonomous permissions and SMS notifications via Twilio MCP integration.

### CLAUDE.md Configuration

This codebase includes a custom `CLAUDE.md` template that configures Claude as an autonomous task executor. Located at `/templates/.claude/CLAUDE.md`, this file provides detailed instructions for how Claude should behave when executing tasks.

**Default Design:** The claude-docker agent expects a detailed `plan.md` file in your project root containing task specifications and which conda env to use. Claude will read this plan and execute it as faithfully as possible, documenting progress in `task_log.md`, send a text on completion if you set up your twilio credentials (optional). Simply tell it to make sure it has read the user scope claude md file and to execute. 

## What This Does
- Runs Claude Code in an isolated Docker container with full autonomy.
- Integrates Twilio MCP for SMS notifications when tasks complete.
- Simple one-command setup and usage.
- Integrates existing conda environments to avoid custom env instructions in the Dockerfile.
- Documents work in a file `task_log.md`.

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
Git configuration is automatically loaded from your host system during Docker build:
- Make sure you have configured git on your host system first:
  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "your.email@example.com"
  ```
- **Important**: Claude Docker will commit to your current branch - make sure you're on the correct branch before starting

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
- Has access to your conda envs so do not need to add build instructions to the Dockerfile
- Supports custom conda installations (ideal for academic/lab environments)
- Mounts conda directories to preserve original paths and configurations

### 🔑 Authentication Persistence
- Login once, use forever - authentication tokens persist across sessions
- No need to re-authenticate every time you start claude-docker
- Credentials stored securely in `~/.claude-docker/claude-home`
- Automatic UID/GID mapping ensures perfect file permissions between host and container

### 📝 Task Execution Logging  
- Generates `task_log.md` documenting agent's execution process
- Stores assumptions, insights, and challenges encountered
- Acts as a simple summary to quickly understand what the agent accomplished

### 🐳 Clean Environment
- Each session runs in fresh Docker container
- Only current working directory mounted (along with conda directories specified in `.env`).

## How It Works

1. **Wrapper Script**: `claude-docker.sh` handles container lifecycle
2. **Auto-Setup**: Creates `.claude` directory with proper config on first run
3. **MCP Integration**: Twilio MCP server runs alongside Claude Code
4. **Project Mounting**: Your project directory mounts to `/workspace`
5. **Clean Exit**: Container removes itself when Claude session ends


## How This Differs from Anthropic's DevContainer

We provide a different approach than [Anthropic's official .devcontainer](https://github.com/anthropics/claude-code/tree/main/.devcontainer), optimized for autonomous task execution:

### Key Advantages

**🐍 Seamless Conda Integration**
- **claude-docker**: Your existing conda environments work out-of-the-box - no setup needed per project
- **Anthropic**: Requires environment setup in each DevContainer's Dockerfile

**🧠 Custom Prompt Engineering**
- **claude-docker**: Includes carefully engineered CLAUDE.md prompts for agentic task execution
- **Anthropic**: Basic Claude Code functionality without task-specific optimization

**🔑 One-Time Authentication**
- **claude-docker**: Authenticate once, use forever across all projects
- **Anthropic**: Re-authenticate for each new DevContainer

**📱 Additional Features**
- **claude-docker**: Built-in Twilio MCP for SMS notifications on task completion
- **Anthropic**: No notification system included

### Feature Comparison

| Feature | claude-docker | Anthropic's DevContainer |
|---------|--------------|-------------------------|
| **IDE Support** | Any editor/IDE | VSCode-specific |
| **Authentication** | Once per machine, persists forever | Per-devcontainer setup |
| **Conda Environments** | Direct access to all host envs | Manual setup in Dockerfile |
| **Prompt Engineering** | Optimized CLAUDE.md for tasks | Standard behavior |
| **Network Access** | Full access (firewall coming soon) | Configurable firewall |
| **SMS Notifications** | Built-in Twilio MCP | Not available |
| **Permissions** | Auto (--dangerously-skip-permissions) | Auto (--dangerously-skip-permissions) |

### When to Use Each

**Use claude-docker for:**
- 🚀 Autonomous task execution with optimized prompts
- 🐍 Projects requiring conda environments without Docker setup
- 📱 Long-running tasks with SMS completion notifications
- 🔧 Quick start without per-project configuration
- 💻 Non-VSCode development environments

**Use Anthropic's DevContainer for:**
- 🔒 Network-restricted environments (domain whitelisting)
- 🆚 Teams standardizing on VSCode
- 🛡️ Projects requiring strict network isolation today

**Note**: Network firewall functionality similar to Anthropic's implementation is our next planned feature.

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
- Network firewall to whitelist specific domains (similar to Anthropic's DevContainer)
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