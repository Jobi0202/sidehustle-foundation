#!/usr/bin/env bash
#
# classify-tier.sh — read the list of changed file PATHS from stdin (one per line)
# and print the risk tier: tier-1 | tier-2 | tier-3.
#
# Used by .github/workflows/auto-label-risk.yml and unit-tested by
# src/ci/tier-classifier.test.ts. Every SQL check is evaluated PER STATEMENT (split
# on ';') so a safe statement can never mask a dangerous one in the same migration.
# Classification is conservative: when in doubt, the higher tier.
#
#   tier-2 = auth/rls/payments path, or destructive/locking DDL
#            (DROP / TRUNCATE / DELETE / RENAME / ALTER..TYPE /
#             ADD COLUMN..NOT NULL without DEFAULT / ADD CONSTRAINT..UNIQUE)
#   tier-3 = DROP TABLE, TRUNCATE, DELETE without WHERE, payments money movement,
#            or a consent/GDPR/Art-9 path
#   tier-1 = everything else
#
set -uo pipefail

files="$(cat)"

sql_files="$(printf '%s\n' "$files" | grep -E '(^|/)migrations/.*\.sql$' || true)"
payments_files="$(printf '%s\n' "$files" | grep -E '(^|/)payments/' || true)"

# Read and upper-case the contents of a newline list of files (on stdin).
read_up() {
  while IFS= read -r f; do
    [ -n "$f" ] && [ -f "$f" ] && cat "$f"
  done | tr '[:lower:]' '[:upper:]'
}

sql_up="$(printf '%s\n' "$sql_files" | read_up)"
pay_up="$(printf '%s\n' "$payments_files" | read_up)"

# Normalise SQL to ONE statement per line: strip line comments, join lines, split on ';'.
sql_stmts="$(printf '%s\n' "$sql_up" | sed 's/--.*$//' | tr '\n' ' ' | tr ';' '\n')"

# True if any single statement matches the pattern.
stmt() { printf '%s\n' "$sql_stmts" | grep -qE "$1"; }

tier="tier-1"

# ---- tier-2: structural risk paths ----
printf '%s\n' "$files" | grep -qE '(^|/)(auth|rls|payments)/' && tier="tier-2"

# ---- tier-2: destructive / locking DDL (per statement) ----
stmt '\bDROP\b'                            && tier="tier-2"
stmt '\bTRUNCATE\b'                         && tier="tier-2"
stmt '\bDELETE[[:space:]]+FROM\b'          && tier="tier-2"
stmt '\bRENAME\b'                          && tier="tier-2"
stmt 'ALTER[[:space:]].*[[:space:]]TYPE\b' && tier="tier-2"
stmt 'ADD[[:space:]]+CONSTRAINT[^,]*UNIQUE' && tier="tier-2"
# ADD COLUMN ... NOT NULL without DEFAULT — per statement: the SAME statement that
# adds a NOT NULL column must not also carry a DEFAULT.
if printf '%s\n' "$sql_stmts" | grep -E 'ADD[[:space:]]+COLUMN' | grep -E 'NOT[[:space:]]+NULL' | grep -qvE 'DEFAULT'; then
  tier="tier-2"
fi

# ---- tier-3 overrides (conservative, per statement) ----
stmt 'DROP[[:space:]]+TABLE' && tier="tier-3"
stmt '\bTRUNCATE\b'          && tier="tier-3"   # unconditional data loss
# DELETE without WHERE — any single DELETE statement lacking a WHERE.
if printf '%s\n' "$sql_stmts" | grep -E '\bDELETE[[:space:]]+FROM\b' | grep -qvE '\bWHERE\b'; then
  tier="tier-3"
fi
printf '%s\n' "$files" | grep -qE '(^|/)(consent|gdpr|art9)/' && tier="tier-3"
# Payments money movement — from the changed payments files' content (code or SQL).
if [ -n "$payments_files" ] && printf '%s' "$sql_up$pay_up" | grep -qE 'TRANSFER|CHARGE|PAYOUT|REFUND|BALANCE|AMOUNT'; then
  tier="tier-3"
fi

echo "$tier"
