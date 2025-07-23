#\!/bin/bash
# Export environment variables from settings.json
# This is a workaround for Docker container not properly exposing these to Claude
if [ -f "$HOME/.claude/settings.json" ] && command -v jq >/dev/null 2>&1; then
    echo "Loading environment variables from settings.json..."
    # Extract and export each env var from the JSON
    while IFS='=' read -r key value; do
        if [ -n "$key" ] && [ -n "$value" ]; then
            export "$key=$value"
            echo "  Exported: $key=$value"
        fi
    done < <(jq -r '.env // {}  < /dev/null |  to_entries | .[] | "\(.key)=\(.value)"' "$HOME/.claude/settings.json" 2>/dev/null)
fi
