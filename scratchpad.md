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
**Phase 3 - Smart SMS Notifications:**

### Next Task: Prompt Engineering for SMS Notifications
**Goal:** Configure Claude to automatically send completion SMS to `$TWILIO_TO_NUMBER`

**Implementation Plan:**
1. Update CLAUDE.md template with SMS notification instructions
2. Add completion detection logic
3. Integrate with existing Twilio MCP server
4. Test notification flow

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