#!/usr/bin/env bash
# Bulk-fan-out the central secrets file to every owned GitHub repo.
#
# Use this whenever a key rotates (ANTHROPIC, OPENAI, DEEPSEEK, etc.) or whenever
# an older repo is missing a freshly added key. Idempotent: re-running overwrites
# existing values, which is the intended behaviour for rotation.
#
# Usage:
#   bash scripts/set-secrets-all-repos.sh                       # all non-archived repos owned by gh-authed user
#   bash scripts/set-secrets-all-repos.sh --repo elternplan-studio   # only that repo
#   bash scripts/set-secrets-all-repos.sh --repo Jobi0202/elternplan-studio  # explicit owner/name
#   bash scripts/set-secrets-all-repos.sh --env-file /custom/path.env        # alternate source
#   bash scripts/set-secrets-all-repos.sh --user Jobi0202                    # override gh login
#   bash scripts/set-secrets-all-repos.sh --dry-run             # list targets, set nothing
#
# Reads from $HOME/.sidehustle-secrets.env by default (= %USERPROFILE% on Git Bash on Windows).
#
# Security:
#   - Secret VALUES never appear in logs. Only NAMES and repo identifiers are printed.
#   - The script aborts loudly if the env file is missing.
#   - Make sure .sidehustle-secrets.env is in .gitignore — this repo ships with it pre-ignored.

set -euo pipefail

ENV_FILE="${HOME}/.sidehustle-secrets.env"
REPO_FILTER=""
GH_USER=""
DRY_RUN=0

print_help() {
  sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env-file)  ENV_FILE="$2"; shift 2 ;;
    --repo)      REPO_FILTER="$2"; shift 2 ;;
    --user)      GH_USER="$2"; shift 2 ;;
    --dry-run)   DRY_RUN=1; shift ;;
    -h|--help)   print_help; exit 0 ;;
    *)           echo "Unknown arg: $1" >&2; print_help; exit 2 ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI not found in PATH. Install: https://cli.github.com/" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: gh is not authenticated. Run: gh auth login" >&2
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: env file not found: $ENV_FILE" >&2
  echo "Hint: copy .env.template to \"$ENV_FILE\" and fill real values." >&2
  exit 1
fi

if [[ -z "$GH_USER" ]]; then
  GH_USER="$(gh api user --jq .login)"
fi

# Pull just the NAMES from the env file for the banner — never the values.
secret_names="$(grep -E '^[A-Z_][A-Z0-9_]*=' "$ENV_FILE" | cut -d= -f1 | paste -sd, -)"
if [[ -z "$secret_names" ]]; then
  echo "ERROR: env file has no KEY=VALUE lines: $ENV_FILE" >&2
  exit 1
fi

echo "User:      $GH_USER"
echo "Env file:  $ENV_FILE"
echo "Secrets:   $secret_names"
echo

# Build repo list.
if [[ -n "$REPO_FILTER" ]]; then
  if [[ "$REPO_FILTER" == */* ]]; then
    repo_list="$REPO_FILTER"
  else
    repo_list="$GH_USER/$REPO_FILTER"
  fi
else
  repo_list="$(gh repo list "$GH_USER" --limit 1000 --no-archived --json nameWithOwner --jq '.[].nameWithOwner')"
fi

repo_count="$(printf '%s\n' "$repo_list" | grep -c .)"
echo "Targets:   $repo_count repo(s)"
echo

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '%s\n' "$repo_list" | sed 's/^/  (dry-run) /'
  echo
  echo "Dry-run only. Re-run without --dry-run to apply."
  exit 0
fi

ok=0
fail=0
failed_repos=()
while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue
  echo "→ $repo"
  if gh secret set -f "$ENV_FILE" --repo "$repo"; then
    ok=$((ok + 1))
  else
    fail=$((fail + 1))
    failed_repos+=("$repo")
  fi
done <<< "$repo_list"

echo
echo "Done: $ok ok, $fail failed (of $repo_count)"
if (( fail > 0 )); then
  echo "Failed repos:" >&2
  printf '  %s\n' "${failed_repos[@]}" >&2
  exit 1
fi
