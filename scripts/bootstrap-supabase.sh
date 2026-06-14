#!/usr/bin/env bash
#
# bootstrap-supabase.sh — run EXACTLY ONCE per Idea-Repo, before the first db-deploy.
#
# What it does (idempotent, safe to re-run):
#   1. `supabase init`            — only if there is no supabase/ project yet.
#   2. `supabase link`            — bind this repo to its remote project.
#   3. `supabase migration repair`— mark migrations that are ALREADY applied on the
#      remote as "applied" in the tracking table, so the first `supabase db push`
#      from db-deploy.yml does not try to re-run history.
#
# After this, NEVER hand-write SQL against the remote again. Every schema change is a
# committed migration under supabase/migrations/**, applied by .github/workflows/db-deploy.yml
# on merge to main. This script is the ONLY place migration-repair lives — db-deploy itself
# applies unconditionally and never repairs (repair masks real drift outside bootstrap).
#
# Required env (from the repo's secrets / your shell, never committed):
#   SUPABASE_ACCESS_TOKEN  — personal access token (supabase login alternative)
#   SUPABASE_PROJECT_ID    — the project ref to link
#   SUPABASE_DB_PASSWORD   — db password for the linked project
#
set -euo pipefail

if ! command -v supabase >/dev/null 2>&1; then
  echo "::error::supabase CLI not found — install it first (https://supabase.com/docs/guides/cli)." >&2
  exit 1
fi

if [ -z "${SUPABASE_PROJECT_ID:-}" ]; then
  echo "::error::SUPABASE_PROJECT_ID is not set — export it (and SUPABASE_ACCESS_TOKEN/SUPABASE_DB_PASSWORD) before bootstrapping." >&2
  exit 1
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$ROOT"

# 1. init only if no project config yet — re-running must not clobber an existing one.
if [ ! -f "supabase/config.toml" ]; then
  echo "==> supabase init"
  supabase init
else
  echo "==> supabase/config.toml already present — skipping init"
fi

# 2. link this checkout to the remote project.
echo "==> supabase link --project-ref $SUPABASE_PROJECT_ID"
supabase link --project-ref "$SUPABASE_PROJECT_ID"

# 3. repair tracking for migrations that already ran on the remote. Mark each committed
#    migration version as `applied` so the first db-deploy push starts from a clean,
#    in-sync history. We DO NOT invent gap versions — only versions we actually have a
#    migration file for. If there are no migrations yet, there is nothing to repair.
shopt -s nullglob
migration_files=(supabase/migrations/*.sql)
shopt -u nullglob

if [ "${#migration_files[@]}" -eq 0 ]; then
  echo "==> no committed migrations yet — nothing to repair. Bootstrap complete."
  exit 0
fi

echo "==> repairing migration tracking (marking committed versions as applied)"
for f in "${migration_files[@]}"; do
  base="$(basename "$f")"
  # Migration filenames are <timestamp>_<name>.sql — the version is the leading digits.
  version="${base%%_*}"
  case "$version" in
    *[!0-9]*|"")
      echo "  skip (no numeric version): $base"
      continue
      ;;
  esac
  echo "  repair --status applied $version  ($base)"
  supabase migration repair --status applied "$version"
done

echo "==> Bootstrap complete. From here on: schema changes = committed migrations only, never hand-SQL."
