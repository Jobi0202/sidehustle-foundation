#!/usr/bin/env bash
#
# bootstrap-identity.sh — pin this repo's git identity to the fleet canonical.
# Run EXACTLY ONCE per fresh clone (the template bootstrap calls it). Idempotent.
#
# Canonical identity = owner of every repo + the Vercel team:
#   Jobi0202 <tomorrow.tech.lab@gmail.com>
# johannes.rentsch.jr@gmail.com (the dead Giro22 account, no Vercel) is WRONG and
# must never author commits. The .husky/pre-push author guard enforces this on push.
#
set -euo pipefail

CANONICAL_EMAIL="tomorrow.tech.lab@gmail.com"
CANONICAL_NAME="Jobi0202"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$ROOT"

git config user.email "$CANONICAL_EMAIL"
git config user.name "$CANONICAL_NAME"

echo "==> git identity pinned (repo-local): $(git config user.name) <$(git config user.email)>"
echo "    The .husky/pre-push author guard rejects any other author on push."
