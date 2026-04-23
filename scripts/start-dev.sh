#!/usr/bin/env bash
# scripts/start-dev.sh
# Start the dev server with a unique port derived from the current branch name.
# Port = 4000 + (SHA256(branch) first 4 bytes as uint32) % 200

set -euo pipefail

branch=$(git rev-parse --abbrev-ref HEAD)
if [ -z "$branch" ]; then
    echo "Not in a git repository." >&2
    exit 1
fi

hash=$(printf "%s" "$branch" | sha256sum | cut -c1-8)
int_hash=$((16#${hash}))
port=$((4000 + int_hash % 200))

echo "Branch: ${branch}"
echo "Port:   ${port}"
echo
export PORT="${port}"
pnpm dev
