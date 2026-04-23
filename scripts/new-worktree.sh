#!/usr/bin/env bash
# scripts/new-worktree.sh
# Create an isolated git worktree for an Issue and install dependencies.
# Usage: ./scripts/new-worktree.sh <issue-number> [base-branch]

set -euo pipefail

ISSUE_NUMBER="${1:?Usage: new-worktree.sh <issue-number> [base-branch]}"
BASE_BRANCH="${2:-main}"
WORKTREE_NAME="issue-${ISSUE_NUMBER}"
WORKTREE_PATH=".claude/worktrees/${WORKTREE_NAME}"
BRANCH_NAME="feature/issue-${ISSUE_NUMBER}"

if [ ! -d ".git" ]; then
    echo "Error: not in a git repository root." >&2
    exit 1
fi

if [ -d "${WORKTREE_PATH}" ]; then
    echo "Error: worktree ${WORKTREE_PATH} already exists." >&2
    exit 1
fi

echo "Fetching latest ${BASE_BRANCH}..."
git fetch origin "${BASE_BRANCH}"

echo "Creating worktree ${WORKTREE_PATH} (branch ${BRANCH_NAME} from origin/${BASE_BRANCH})..."
git worktree add -b "${BRANCH_NAME}" "${WORKTREE_PATH}" "origin/${BASE_BRANCH}"

(
    cd "${WORKTREE_PATH}"
    echo "Installing dependencies with pnpm..."
    pnpm install
)

echo
echo "Worktree ready."
echo "  Path:   ${WORKTREE_PATH}"
echo "  Branch: ${BRANCH_NAME}"
echo "  Issue:  #${ISSUE_NUMBER}"
echo
echo "Next:"
echo "  cd ${WORKTREE_PATH}"
echo "  claude -w ${WORKTREE_NAME}"
