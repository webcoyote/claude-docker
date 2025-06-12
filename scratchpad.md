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
- **✅ WORKING** - All startup issues resolved, Docker container launches Claude Code successfully

## Next Steps 🎯
**Phase 2 - Security & Persistence Enhancements:**

### 1. Authentication Persistence (HIGH Priority) - ✅ COMPLETED
**Problem:** Need to re-login to Claude Code every time container starts

**Research Findings:**
- Claude Code stores auth tokens in `~/.claude/.credentials.json`
- Known issues: #1222 (persistent auth warnings), #1676 (logout after restart)
- The devcontainer mounts `/home/node/.claude` for config persistence
- But auth tokens are NOT persisted properly even in devcontainer

**Implementation Completed:**
1. **Created persistent directory structure:**
   - Host: `~/.claude-docker/claude-home` 
   - Container: `/home/claude-user/.claude`
   - Mounted with read/write permissions

2. **Updated Docker setup:**
   - Created non-root user `claude-user` for better security
   - Set proper ownership and permissions
   - Added volume mount for Claude home directory

3. **Enhanced startup script:**
   - Checks for existing `.credentials.json` on startup
   - Notifies user if auth exists or login needed
   - Credentials persist across container restarts

**Result:** Users now login once and authentication persists forever!

### 2. Network Security (High Priority) - PLANNED
**Implementation based on devcontainer's init-firewall.sh:**

**Key Components:**
1. **Firewall Script Features:**
   - Uses iptables with default DROP policy
   - ipset for managing allowed IP ranges
   - Dynamic IP resolution for allowed domains
   - Verification of connectivity post-setup

2. **Allowed Domains Configuration:**
   ```yaml
   allowed_domains:
     - api.anthropic.com      # Claude API
     - api.twilio.com         # SMS notifications
     - github.com             # Git operations
     - raw.githubusercontent.com
     - registry.npmjs.org     # Package management
     - pypi.org               # Python packages
     
   blocked_paths:           # File system restrictions
     - /etc
     - /root
     - ~/.ssh
   ```

3. **User-Friendly Setup:**
   - Simple YAML config file for rules
   - Easy enable/disable of firewall
   - Logging of blocked attempts
   - Graceful degradation if firewall fails

### 3. Shell History Persistence (Medium Priority)
- Add persistent bash/zsh history between container sessions
- Mount history file to host directory
- Implement history management similar to Claude dev container
- Ensure commands persist across sessions

### 4. Additional Persistence Features (Medium Priority)
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
- **NEW (2024-12-06):** Focus on auth persistence first before firewall implementation
- **COMPLETED (2024-12-06):** Auth persistence via mounted ~/.claude directory

## Notes & Context
- Repository: https://github.com/VishalJ99/claude-docker
- Using --dangerously-skip-permissions flag for full autonomy
- Twilio MCP server runs via Claude's MCP config (not as separate process)
- Uses @twilio-alpha/mcp package with API Key/Secret authentication
- Container auto-removes on exit for clean state
- Project directory mounted at /workspace
- Need to research Claude dev container's init-firewall.sh implementation
- Need to research their history persistence mechanism
- **Fixed startup issues:**
  - Changed executable from `claude-code` to `claude` in startup.sh
  - Fixed .env parsing to handle comments properly using `set -a`/`source`
  - Added explicit PATH for npm global binaries
  - Maintained separation: `claude-docker` (host) vs `claude` (container)
- **Current working state:** Container launches successfully, authentication required each session
- **Auth Persistence Research (2024-12-06):**
  - Claude Code has known issues with auth persistence
  - Tokens stored in temp locations that get cleared
  - Need to find exact token storage location and persist it

## Quick References
- Install: `./scripts/install.sh`
- Usage: `claude-docker` (from any project directory)
- Config: `~/.claude-docker/.env`
- Repo: https://github.com/VishalJ99/claude-docker
- Claude dev container: https://github.com/anthropics/claude-code/tree/main/.devcontainer