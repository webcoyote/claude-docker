# Docker Container Environment Variable Issue

## Problem
The `env` section in Claude's `settings.json` doesn't automatically export environment variables to the shell in Docker containers. These settings are meant for Claude Code's internal use when executing commands through its Bash tool.

## Workaround
Modified `/workspace/scripts/startup.sh` to parse `settings.json` and export the env vars as actual shell environment variables before starting Claude Code.

### Implementation
The script now:
1. Checks if `$HOME/.claude/settings.json` exists
2. Uses `jq` if available to parse the JSON and extract env vars
3. Falls back to grep/sed parsing if `jq` is not installed
4. Exports each variable found in the `env` section

### Example
For a settings.json with:
```json
{
  "env": {
    "BASH_DEFAULT_TIMEOUT_MS": "86400000",
    "BASH_MAX_TIMEOUT_MS": "86400000"
  }
}
```

The startup script will export:
- `BASH_DEFAULT_TIMEOUT_MS=86400000`
- `BASH_MAX_TIMEOUT_MS=86400000`

## Note
This is a temporary workaround. The proper solution would be for Claude Code to handle these environment variables correctly in containerized environments.

## To Apply Changes
Run `claude-docker --rebuild` to rebuild the container with the updated startup script.