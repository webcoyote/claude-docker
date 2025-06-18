# Claude Docker Project Scratchpad

## Project Overview
Docker container for Claude Code with full autonomous permissions, authentication persistence, and Twilio SMS notifications.

## ✅ COMPLETED PHASES

### Phase 1 - MVP (Complete)
- Docker setup with Claude Code + Twilio MCP integration
- Wrapper script for easy invocation
- Auto .claude directory setup 
- Full autonomous permissions with --dangerously-skip-permissions
- Context persistence via scratchpad.md files

### Phase 2 - Authentication Persistence (Complete) 
- **SOLVED**: Authentication files copied during Docker build
- **SOLVED**: MCP servers persist with user scope
- **SOLVED**: No unnecessary rebuilds
- **RESULT**: Zero-friction experience - no login prompts, SMS ready instantly

## 🎯 CURRENT FOCUS
**CRITICAL ISSUE TO RESOLVE NEXT SESSION:**

### CLAUDE.md Template Not Being Copied to Container
**Problem:** The CLAUDE.md template file is not appearing in `~/.claude/CLAUDE.md` inside the container, so Claude doesn't read the project instructions.

**Root Cause Identified:** In Dockerfile line 65, the cleanup command `rm -rf /tmp/.claude*` is deleting `/tmp/CLAUDE.md` BEFORE it can be copied to the final location.

**Solution Applied (needs testing):**
- Fixed order: copy CLAUDE.md BEFORE cleanup in same RUN block
- Line 64: `cp /tmp/CLAUDE.md /home/claude-user/.claude/CLAUDE.md &&`
- Line 65: `rm -rf /tmp/.claude* /tmp/CLAUDE.md`

**Test Command:** 
```bash
docker rmi claude-docker:latest && claude-docker
# Then: ls -la ~/.claude/CLAUDE.md
```

**Impact:** Without this file, Claude doesn't know:
- How to use conda environments properly
- When/how to send SMS notifications  
- Context persistence guidelines
- Available tools and capabilities

## 📚 KEY INSIGHTS FROM AUTHENTICATION JOURNEY

### Critical Discovery: ~/.claude.json + MCP Scope
- Claude Code requires BOTH `~/.claude.json` (user profile) AND `~/.claude/.credentials.json` (tokens)
- MCP servers default to "local" scope (project-specific) - need "user" scope for persistence
- Authentication can be baked into Docker image during build
- Simple rebuild logic (only if image missing) prevents unnecessary rebuilds

### Technical Implementation 
- Copy auth files during Docker build, not runtime mounting
- Use `-s user` flag for MCP persistence across sessions
- Files placed at correct locations before user switch in Dockerfile

## 🔮 FUTURE ENHANCEMENTS
- Network security with firewall (iptables + ipset)
- Shell history persistence between sessions
- Git configuration persistence

## 📋 DECISIONS LOG
- MCP integration using user scope for persistence
- Authentication files baked into Docker image at build time
- Single container approach (no Docker Compose)
- Simplified rebuild logic (only when image missing)
- SMS via `@yiyang.1i/sms-mcp-server` with Auth Token

## 🔗 QUICK REFERENCES
- **Install:** `./scripts/install.sh`
- **Usage:** `claude-docker` (from any project directory)
- **Config:** `~/.claude-docker/.env` 
- **Force rebuild:** `docker rmi claude-docker:latest`
- **SMS command:** `twilio__send_text`
- **Repository:** https://github.com/VishalJ99/claude-docker