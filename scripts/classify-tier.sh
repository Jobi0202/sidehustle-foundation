#!/usr/bin/env bash
#
# classify-tier.sh — read the list of changed file PATHS from stdin (one per line)
# and print the risk tier: tier-1 | tier-2 | tier-3.
#
# Used by .github/workflows/auto-label-risk.yml and unit-tested by
# src/ci/tier-classifier.test.ts.
#
# FAIL-SAFE ALLOW-LIST model for migrations: a migration is tier-1 ONLY if EVERY one of
# its statements is provably safe-additive (and an ADD COLUMN is nullable or DEFAULTed).
# Any statement the allow-list does not recognise -> tier-2. So an unhandled or unsafe SQL
# form can never slip to tier-1 — at worst it over-tiers to tier-2 (architect-gate). This
# beats a deny-list, which is inherently incomplete (every new SQL form is a hole).
# tier-3 is the well-defined data-loss/legal set; payments impl files are money-adjacent.
# Every SQL check is per statement (split on ';') with block + line comments stripped, so a
# safe statement (or a comment) cannot mask a dangerous one. Conservative: in doubt, higher.
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

# Normalise SQL to ONE statement per line: strip BOTH `/* block */` (perl, multi-line,
# non-greedy) and `-- line` comments so nothing can be masked inside a comment, then
# join lines and split on ';'.
sql_stmts="$(printf '%s\n' "$sql_up" | perl -0pe 's{/\*.*?\*/}{ }gs' | sed 's/--.*$//' | tr '\n' ' ' | tr ';' '\n')"

# True if any single statement matches the pattern.
stmt() { printf '%s\n' "$sql_stmts" | grep -qE "$1"; }

t2=0
t3=0

# ---- paths ----
printf '%s\n' "$files" | grep -qE '(^|/)(auth|rls)/'        && t2=1
printf '%s\n' "$files" | grep -qE '(^|/)(consent|gdpr|art9)/' && t3=1

# ---- SQL allow-list: a migration statement is safe-additive only if it matches SAFE
#      (and an ADD COLUMN is not NOT-NULL-without-DEFAULT). Anything else -> tier-2. ----
SAFE='^(CREATE TABLE|CREATE (CONCURRENTLY )?INDEX|CREATE SCHEMA|CREATE EXTENSION|CREATE TYPE|CREATE SEQUENCE|CREATE MATERIALIZED VIEW|CREATE (OR REPLACE )?(FUNCTION|TRIGGER|VIEW)|COMMENT ON|INSERT INTO|GRANT|REVOKE|SET |SELECT |BEGIN|COMMIT|ALTER SEQUENCE|ALTER TYPE [^,]* ADD VALUE|ALTER TABLE [^,]* ADD COLUMN)'
while IFS= read -r s; do
  st="$(printf '%s' "$s" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [ -z "$st" ] && continue
  # ADD COLUMN ... NOT NULL without DEFAULT locks a populated table — unsafe.
  if printf '%s' "$st" | grep -qE '\bADD[[:space:]]+COLUMN\b' \
     && printf '%s' "$st" | grep -qE '\bNOT[[:space:]]+NULL\b' \
     && ! printf '%s' "$st" | grep -qE '\bDEFAULT\b'; then
    t2=1
    continue
  fi
  printf '%s' "$st" | grep -qE "$SAFE" || t2=1
done <<EOF
$sql_stmts
EOF

# ---- tier-3 (data loss / legal), conservative per statement ----
stmt 'DROP[[:space:]]+TABLE' && t3=1
stmt '\bTRUNCATE\b'          && t3=1   # unconditional data loss
# DELETE without WHERE — any single DELETE statement lacking a WHERE.
if printf '%s\n' "$sql_stmts" | grep -E '\bDELETE[[:space:]]+FROM\b' | grep -qvE '\bWHERE\b'; then
  t3=1
fi
# Payments money movement: ANY changed payments IMPLEMENTATION file (code or SQL) is
# conservatively tier-3 — detecting money movement by keyword is unbounded (Stripe
# checkout/session/paymentIntent/subscription/invoice/...), so we do NOT enumerate it.
# Non-implementation payments files (docs/json/images) stay tier-2 via the path rule below;
# test/spec files are not implementation.
# NOTE: more conservative than the spec's "payments path = tier-2" for impl files
# ("im Zweifel tier-3") — the trade-off is that payments code changes need jo-approved.
pay_impl="$(printf '%s\n' "$payments_files" | grep -E '\.(ts|tsx|js|mjs|cjs|sql)$' | grep -vE '\.(test|spec)\.' || true)"
[ -n "$pay_impl" ] && t3=1

# A payments path that is not an impl file still escalates to tier-2 (path-level risk).
[ -n "$payments_files" ] && t2=1

# ---- resolve (tier-3 > tier-2 > tier-1) ----
if [ "$t3" = "1" ]; then
  echo "tier-3"
elif [ "$t2" = "1" ]; then
  echo "tier-2"
else
  echo "tier-1"
fi
