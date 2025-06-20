#!/bin/bash
# ABOUTME: Installs MCP servers from mcp-servers.txt with environment variable substitution
# ABOUTME: Reads commands from file, substitutes env vars, and executes each MCP installation

set -e

echo "Installing MCP servers..."

# Source .env file if it exists
if [ -f /app/.env ]; then
    set -a
    source /app/.env
    set +a
    echo "Loaded environment variables from .env"
else
    echo "No .env file found, skipping environment variable loading"
fi

# Read mcp-servers.txt and process each line
if [ ! -f /app/mcp-servers.txt ]; then
    echo "No mcp-servers.txt file found, skipping MCP server installation"
    exit 0
fi

# Process each line in mcp-servers.txt
while IFS= read -r line; do
    # Skip empty lines and comments
    if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # Check if line contains environment variables that might not be set
    if [[ "$line" =~ \$\{([^}]+)\} ]]; then
        # Extract variable names
        var_names=$(echo "$line" | grep -o '\${[^}]*}' | sed 's/[${}]//g')
        missing_vars=""
        
        for var in $var_names; do
            if [ -z "${!var}" ]; then
                missing_vars="$missing_vars $var"
            fi
        done
        
        if [ -n "$missing_vars" ]; then
            echo "⚠ Skipping MCP server - missing environment variables:$missing_vars"
            continue
        fi
    fi
    
    # Substitute environment variables
    # This uses envsubst if available, otherwise falls back to shell expansion
    if command -v envsubst >/dev/null 2>&1; then
        expanded_line=$(echo "$line" | envsubst)
    else
        # Fallback: use eval for variable expansion (less safe but works)
        expanded_line=$(eval echo "$line")
    fi
    
    echo "Executing: $expanded_line"
    
    # Execute the command
    if eval "$expanded_line"; then
        echo "✓ Successfully installed MCP server"
    else
        echo "✗ Failed to install MCP server (continuing with next)"
        # Continue with next server instead of failing entire build
    fi
    
    echo "---"
done < /app/mcp-servers.txt

echo "MCP server installation complete"