#!/usr/bin/env bash
#
# verify-pipeline.sh — machine check that an Idea-Repo's CI surface matches the
# sidehustle-foundation pipeline contract. Exit non-zero on drift.
#
# Since Schritt 2 of the reusable-inheritance rollout, the gate PIPELINE lives ONCE in the
# public repo Jobi0202/sidehustle-ci (.github/workflows/pr-gates-reusable.yml, on:
# workflow_call). Every repo's own pr-gates.yml is a THIN CALLER of it. So this script no
# longer greps gate job bodies locally — it verifies (a) correct DELEGATION to the central
# reusable workflow and (b) the still-local, per-repo surface (auto-label-risk, db-deploy).
# The deep gate contract (verdict enforcement, model pin, severity gate, ...) is owned and
# pinned centrally in sidehustle-ci.
#
# Run it twice:
#   1. At bootstrap — right after cloning the template, before the first PR.
#   2. As a CI job in every Idea-Repo (or a nightly) so drift fails loudly instead of rotting.
#
# Two severities:
#   FAIL  — drift from the foundation contract. Exits 1.
#   WARN  — a known, tracked manual-confirm state (set outside the repo at rollout).
#           Informational only; does NOT affect the exit code.
#
set -uo pipefail

ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || echo .)"
GATES="$ROOT/.github/workflows/pr-gates.yml"
DB_DEPLOY="$ROOT/.github/workflows/db-deploy.yml"
RISK="$ROOT/.github/workflows/auto-label-risk.yml"
MODEL_DOC="$ROOT/docs/CI-MODEL-CHOICE.md"

# The reusable workflow every caller must delegate to (path; pin checked separately).
REUSABLE_PATH='Jobi0202/sidehustle-ci/.github/workflows/pr-gates-reusable.yml'

fail_count=0
warn_count=0

pass() { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; fail_count=$((fail_count + 1)); }
warn() { printf '  \033[33mWARN\033[0m  %s\n' "$1"; warn_count=$((warn_count + 1)); }

in_gates() { grep -qE "$1" "$GATES"; }
in_db_deploy() { grep -qE "$1" "$DB_DEPLOY"; }

echo "verify-pipeline.sh — checking $ROOT"
echo

# --- 1. pr-gates.yml exists -------------------------------------------------
echo "[1/5] Workflow file"
if [ -f "$GATES" ]; then
  pass ".github/workflows/pr-gates.yml present"
else
  fail ".github/workflows/pr-gates.yml missing — no pipeline at all"
  echo
  echo "RESULT: FAIL ($fail_count failing) — cannot continue without pr-gates.yml"
  exit 1
fi

# --- 2. Thin-caller delegation to the central reusable workflow -------------
echo "[2/5] Thin-caller delegation (single source: sidehustle-ci)"
if grep -qE "uses:[[:space:]]*${REUSABLE_PATH}@" "$GATES"; then
  pass "pr-gates.yml delegates to ${REUSABLE_PATH}"
  if grep -qE "uses:[[:space:]]*${REUSABLE_PATH}@(main|v[0-9]+)" "$GATES"; then
    pass "delegation is pinned (@main or @v<N>) so central changes propagate"
  else
    fail "reusable workflow reference is not pinned to @main or a @v<N> tag"
  fi
  if in_gates 'secrets:[[:space:]]*inherit'; then
    pass "secrets: inherit (repo secrets passed to the reusable workflow)"
  else
    fail "missing 'secrets: inherit' — the reusable workflow gets no secrets"
  fi
  # A called workflow's permissions are capped by the caller's grant (repo default is
  # read-only), so the caller must grant the union the reusable jobs need or the run fails
  # at startup.
  if in_gates '^permissions:' && in_gates 'contents:[[:space:]]*write' && in_gates 'pull-requests:[[:space:]]*write' && in_gates 'issues:[[:space:]]*write' && in_gates 'id-token:[[:space:]]*write'; then
    pass "caller grants the permissions the reusable jobs require (contents/PR/issues/id-token write)"
  else
    fail "caller does not grant the reusable's required permissions — the run will fail at startup"
  fi
else
  fail "pr-gates.yml is NOT a thin caller of ${REUSABLE_PATH} — un-migrated drift (run Schritt 2/3)"
fi
if grep -qE '^name:[[:space:]]*PR Gates[[:space:]]*$' "$GATES"; then
  pass "workflow name is 'PR Gates' (notify-jo workflow_run trigger matches)"
else
  fail "workflow name is not 'PR Gates' — notify-jo's workflow_run trigger will not fire"
fi

# --- 3. PR trigger + concurrency (caller owns the trigger) ------------------
echo "[3/5] Trigger + concurrency"
if in_gates 'pull_request:' && in_gates 'types:[[:space:]]*\[[^]]*labeled[^]]*unlabeled[^]]*\]'; then
  pass "on: pull_request with labeled/unlabeled (jo-approved re-runs the gates)"
else
  fail "pr-gates.yml does not trigger on pull_request with labeled/unlabeled types"
fi
if in_gates 'group:[[:space:]]*pr-gates-' && in_gates 'cancel-in-progress:[[:space:]]*true'; then
  pass "per-PR concurrency group with cancel-in-progress (stale runs cancelled)"
else
  fail "missing per-PR concurrency group / cancel-in-progress"
fi

# --- 4. Risk tiering (still per-repo: auto-label-risk.yml) ------------------
echo "[4/5] Risk tiering (local)"
if [ -f "$RISK" ] && grep -q 'tier-1' "$RISK" && grep -q 'tier-2' "$RISK" && grep -q 'tier-3' "$RISK"; then
  pass "auto-label-risk classifies into tier-1/tier-2/tier-3 (via classify-tier.sh)"
else
  fail "auto-label-risk.yml does not emit the three tier labels"
fi
if [ -f "$MODEL_DOC" ]; then
  pass "docs/CI-MODEL-CHOICE.md present"
else
  warn "docs/CI-MODEL-CHOICE.md absent — model choice is now documented centrally in sidehustle-ci"
fi

# --- 5. db-deploy template: 0-touch migration deploy on merge to main -------
echo "[5/5] db-deploy — 0-touch migration deploy"
if [ -f "$DB_DEPLOY" ]; then
  pass ".github/workflows/db-deploy.yml present"
  if in_db_deploy '^[[:space:]]*branches:[[:space:]]*\[main\]' || in_db_deploy '^[[:space:]]*-[[:space:]]*main[[:space:]]*$'; then
    pass "db-deploy triggers on push to main"
  else
    fail "db-deploy does not trigger on push to main — migrations would never apply"
  fi
  if in_db_deploy "supabase/migrations/\*\*"; then
    pass "db-deploy is path-filtered to supabase/migrations/** (no-op when no migration changed)"
  else
    fail "db-deploy missing the supabase/migrations/** paths filter — it would run on every main push"
  fi
  if in_db_deploy 'supabase db push'; then
    pass "db-deploy applies migrations via 'supabase db push'"
  else
    fail "db-deploy does not run 'supabase db push' — nothing gets applied"
  fi
  if in_db_deploy 'migration repair'; then
    fail "db-deploy contains 'migration repair' — repair is a one-time bootstrap op, not a per-deploy step"
  else
    pass "db-deploy has no migration-repair (correct — repair is bootstrap-only)"
  fi
else
  fail ".github/workflows/db-deploy.yml missing — no 0-touch DB deploy"
fi

for s in bootstrap-supabase.sh bootstrap-vercel.sh; do
  if [ -f "$ROOT/scripts/$s" ]; then
    pass "scripts/$s present"
  else
    fail "scripts/$s missing — repo cannot be bootstrapped for 0-touch deploy"
  fi
done

# Set OUTSIDE the repo at rollout time → MANUAL-CONFIRM warnings, not hard fails.
warn "MANUAL-CONFIRM: SUPABASE_ACCESS_TOKEN / SUPABASE_DB_PASSWORD / SUPABASE_PROJECT_ID set in repo secrets (needed before the first migration merges)"
warn "MANUAL-CONFIRM: Vercel Production Branch = main (so green main-merges auto-promote to prod)"
warn "MANUAL-CONFIRM: DEEPSEEK_API_KEY / OPENAI_API_KEY / CLAUDE_CODE_OAUTH_TOKEN set in repo secrets (the reusable workflow reads them via secrets: inherit)"

# --- Summary ----------------------------------------------------------------
echo
if [ "$fail_count" -eq 0 ]; then
  echo "RESULT: PASS — 0 failing, $warn_count warning(s) (see above)"
  exit 0
fi
echo "RESULT: FAIL — $fail_count failing check(s), $warn_count warning(s)"
exit 1
