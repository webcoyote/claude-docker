# Claude Docker Project Scratchpad

## Project Overview
Building a Docker container that runs Claude Code with full autonomous permissions and Twilio SMS notifications upon task completion.

## What Was Done ✅
**Phase 1 - Complete MVP:**
- GitHub repository created: https://github.com/VishalJ99/claude-docker
- Docker setup with Claude Code + Twilio MCP integration
- Wrapper script (`claude-docker.sh`) for easy invocation
- Auto .claude directory setup with MCP configuration
- Installation script for zshrc alias
- SMS notifications via Twilio MCP server
- Full autonomous permissions with --dangerously-skip-permissions
- Context persistence via scratchpad.md files
- Complete documentation and examples

## Next Steps 🎯
**Phase 2 - Security & Persistence Enhancements:**

### 1. Network Security (High Priority)
- Implement firewall to restrict network access
- Whitelist only essential domains:
  - api.anthropic.com (Claude API)
  - api.twilio.com (SMS notifications)
  - github.com, raw.githubusercontent.com (git operations)
  - npm registry domains (package management)
  - Common documentation sites (if needed)
- Block all other outbound connections for security

### 2. Shell History Persistence (Medium Priority)
- Add persistent bash/zsh history between container sessions
- Mount history file to host directory
- Implement history management similar to Claude dev container
- Ensure commands persist across sessions

### 3. Additional Persistence Features (Medium Priority)
- Persistent npm cache for faster startups
- Git configuration persistence
- Custom shell aliases and environment

## Direction & Vision
**Security-First Autonomous Environment:**
- Maintain full Claude autonomy within projects
- Add network security layer to prevent unauthorized access
- Enhance user experience with persistent shell history
- Keep container lightweight and fast
- Ensure easy setup and maintenance

## Decisions Log
- Using MCP (Model Context Protocol) for Twilio integration instead of direct API
- Single container approach (no Docker Compose needed)
- API keys via .env file
- Context persistence via scratchpad.md files
- Simplified settings.json to only include MCP config (no redundant allowedTools)
- **NEW:** Adding firewall for network security
- **NEW:** Adding shell history persistence like Claude dev container

## Notes & Context
- Repository: https://github.com/VishalJ99/claude-docker
- Using --dangerously-skip-permissions flag for full autonomy
- Twilio MCP server runs via Claude's MCP config (not as separate process)
- Uses @twilio-alpha/mcp package with API Key/Secret authentication
- Container auto-removes on exit for clean state
- Project directory mounted at /workspace
- Need to research Claude dev container's init-firewall.sh implementation
- Need to research their history persistence mechanism
- **Fixed startup issues (Dec 2024):**
  - Changed executable from `claude-code` to `claude` in startup.sh
  - Fixed .env parsing to handle comments properly using `set -a`/`source`
  - Added explicit PATH for npm global binaries
  - Maintained separation: `claude-docker` (host) vs `claude` (container)

## Quick References
- Install: `./scripts/install.sh`
- Usage: `claude-docker` (from any project directory)
- Config: `~/.claude-docker/.env`
- Repo: https://github.com/VishalJ99/claude-docker
- Claude dev container: https://github.com/anthropics/claude-code/tree/main/.devcontainer