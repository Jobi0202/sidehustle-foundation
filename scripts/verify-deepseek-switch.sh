#!/usr/bin/env bash
# Verifies Gate 2 + Gate 3 use DeepSeek backend, not Anthropic.
# Exits non-zero if drift detected. Called by Master-Agent-Bootstrap post-clone.
set -euo pipefail
WF=".github/workflows/pr-gates.yml"
fail=0
grep -q "ANTHROPIC_BASE_URL: https://api.deepseek.com/anthropic" "$WF" || { echo "MISS: ANTHROPIC_BASE_URL"; fail=1; }
grep -q "ANTHROPIC_AUTH_TOKEN: \${{ secrets.DEEPSEEK_API_KEY }}" "$WF" || { echo "MISS: ANTHROPIC_AUTH_TOKEN"; fail=1; }
grep -qE "ANTHROPIC_MODEL: deepseek-v[0-9]" "$WF" || { echo "MISS: ANTHROPIC_MODEL"; fail=1; }
grep -qE "^\s*#\s*ANTHROPIC_API_KEY:" "$WF" || { echo "WARN: ANTHROPIC_API_KEY rollback-line missing — add as comment"; }
grep -qE "^[^#]*ANTHROPIC_API_KEY:" "$WF" && { echo "DRIFT: ANTHROPIC_API_KEY still active (not commented)"; fail=1; } || true
[ $fail -eq 0 ] && echo "OK: DeepSeek switch verified" || exit 1
