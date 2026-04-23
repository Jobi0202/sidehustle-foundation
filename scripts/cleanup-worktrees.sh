#!/usr/bin/env bash
# scripts/cleanup-worktrees.sh
# Remove worktrees whose branches have been merged into origin/main.
# Safe by default: prompts before removing anything. Pass --force to skip prompts.
# Usage: ./scripts/cleanup-worktrees.sh [--force]

set -euo pipefail

FORCE=0
if [ "${1:-}" = "--force" ]; then FORCE=1; fi

echo "Fetching origin/main..."
git fetch origin main >/dev/null

merged=$(git branch -r --merged origin/main | awk '{$1=$1}1')

git worktree list --porcelain | awk '
    /^worktree / { if (path) print path"|"branch; path=$2; branch="" }
    /^branch / { branch=$2; sub(/^refs\/heads\//, "", branch) }
    END { if (path) print path"|"branch }
' | while IFS="|" read -r path branch; do
    [ -z "${path}" ] && continue
    [ -z "${branch}" ] && continue
    case "${path}" in
        */.claude/worktrees/*) ;;
        *) continue ;;
    esac

    if echo "${merged}" | grep -qx "origin/${branch}"; then
        if [ "${FORCE}" -eq 0 ]; then
            read -rp "Remove merged worktree '${path}' (branch ${branch})? [y/N] " reply
            [ "${reply}" = "y" ] || { echo "Skipped."; continue; }
        fi
        echo "Removing ${path}..."
        git worktree remove "${path}" --force
        git branch -D "${branch}" 2>/dev/null || true
    else
        echo "Keeping active worktree: ${path} (branch ${branch})"
    fi
done

git worktree prune
echo
echo "Cleanup complete."
