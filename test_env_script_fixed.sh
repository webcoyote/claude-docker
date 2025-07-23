#\!/bin/bash
# Export environment variables from settings.json
# This is a workaround for Docker container not properly exposing these to Claude
if [ -f "$HOME/.claude/settings.json" ] && command -v jq >/dev/null 2>&1; then
    echo "Loading environment variables from settings.json..."
    # First remove comments from JSON, then extract env vars
    # Using sed to remove // comments before parsing with jq
    while IFS='=' read -r key value; do
        if [ -n "$key" ] && [ -n "$value" ]; then
            export "$key=$value"
            echo "  Exported: $key=$value"
        fi
    done < <(sed 's://.*$::g' "$HOME/.claude/settings.json"  < /dev/null |  jq -r '.env // {} | to_entries | .[] | "\(.key)=\(.value)"' 2>/dev/null)
fi
