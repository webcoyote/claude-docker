# Claude Docker Slash Command: reload-context

## Overview
A custom slash command that reloads your user-level CLAUDE.md configuration into the current Claude session.

## Usage
```
/user:reload-context
```

## What it does
- Reads the user-level CLAUDE.md file from `/home/claude-user/.claude/CLAUDE.md`
- Loads all configuration, instructions, and context into the current session
- Ensures your autonomous task executor settings, coding standards, and operational guidelines are active

## Installation
The command is automatically available in any claude-docker instance since:
1. The command file is located at `~/.claude-docker/claude-home/commands/reload-context.md` on your host
2. This directory is automatically mounted to `/home/claude-user/.claude/commands/` in the container
3. Claude Code automatically discovers and registers commands in this location

## When to use
- At the start of a new claude-docker session to load your configuration
- When you want to ensure your user-level instructions are active
- After making changes to your CLAUDE.md file and want to reload it

## Technical Details
- Command file: `~/.claude-docker/claude-home/commands/reload-context.md`
- Command syntax: Personal command using `/user:` prefix
- Mounted automatically via existing docker volume configuration