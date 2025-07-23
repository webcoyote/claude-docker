#\!/bin/bash
echo "=== Test: Docker inherits parent environment ==="
export PARENT_VAR="from_parent"
echo "Parent shell: PARENT_VAR=$PARENT_VAR"
echo "Parent shell: BASH_DEFAULT_TIMEOUT_MS=$BASH_DEFAULT_TIMEOUT_MS"

echo -e "\n=== Running docker without -e flag ==="
docker run --rm alpine sh -c 'echo "Container: PARENT_VAR=$PARENT_VAR"'
docker run --rm alpine sh -c 'echo "Container: BASH_DEFAULT_TIMEOUT_MS=$BASH_DEFAULT_TIMEOUT_MS"'

echo -e "\n=== Running docker WITH -e flag ==="
docker run --rm -e PARENT_VAR alpine sh -c 'echo "Container with -e: PARENT_VAR=$PARENT_VAR"'
