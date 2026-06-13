#!/usr/bin/env bash
#
# verify-pipeline.sh — machine check that an Idea-Repo's CI surface matches the
# sidehustle-foundation pipeline contract. Exit non-zero on drift.
#
# Run it twice:
#   1. At bootstrap — right after cloning the template, before the first PR.
#   2. As a CI job in every Idea-Repo — wire it into pr-gates (or a nightly) so
#      drift from the foundation contract fails loudly instead of rotting.
#
# This replaces the older scripts/verify-deepseek-switch.sh (single verifier for
# the whole pipeline, not just the model switch). If that file ever reappears in
# a downstream repo, soft-delete it into scripts/_archive/.
#
# Two severities:
#   FAIL  — drift from the CURRENT foundation contract. Exits 1.
#   WARN  — a forward contract item that has not landed in foundation yet
#           (tracked below). Informational only; does NOT affect exit code, so
#           the verifier stays green against the present foundation state.
#           Each WARN names the Issue/stage that flips it to a hard FAIL.
#
set -uo pipefail

ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || echo .)"
GATES="$ROOT/.github/workflows/pr-gates.yml"
MODEL_DOC="$ROOT/docs/CI-MODEL-CHOICE.md"

REQUIRED_JOBS="workflow-lint lint typecheck unit e2e claude-review codex-adversarial gates-green"

fail_count=0
warn_count=0

pass() { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; fail_count=$((fail_count + 1)); }
warn() { printf '  \033[33mWARN\033[0m  %s\n' "$1"; warn_count=$((warn_count + 1)); }

# grep helper scoped to the gates file; returns 0 on match.
in_gates() { grep -qE "$1" "$GATES"; }

echo "verify-pipeline.sh — checking $ROOT"
echo

# --- 1. pr-gates.yml exists -------------------------------------------------
echo "[1/7] Workflow file"
if [ -f "$GATES" ]; then
  pass ".github/workflows/pr-gates.yml present"
else
  fail ".github/workflows/pr-gates.yml missing — no pipeline at all"
  echo
  echo "RESULT: FAIL ($fail_count failing) — cannot continue without pr-gates.yml"
  exit 1
fi

# --- 2. Required jobs present ----------------------------------------------
echo "[2/7] Required jobs"
for job in $REQUIRED_JOBS; do
  if grep -qE "^[[:space:]]{2}${job}:" "$GATES"; then
    pass "job '$job' defined"
  else
    fail "job '$job' missing from pr-gates.yml"
  fi
done

# --- 3. Gate 2 (claude-review) posts + enforces a verdict -------------------
echo "[3/7] Gate 2 — Claude review verdict"
if in_gates 'gh pr comment .* -F'; then
  pass "Gate 2 posts the verdict back to the PR (gh pr comment -F)"
else
  fail "Gate 2 does not post a verdict comment — reviewer output is invisible"
fi
if in_gates 'Enforce Gate 2 verdict'; then
  pass "Gate 2 has an 'Enforce' step"
else
  fail "Gate 2 has no enforce step — a failing review cannot block merge"
fi

# --- 4. Gate 3 (codex-adversarial) posts + enforces ------------------------
echo "[4/7] Gate 3 — Codex adversarial verdict"
if in_gates 'codex:adversarial-review'; then
  pass "Gate 3 invokes /codex:adversarial-review"
else
  fail "Gate 3 does not invoke the codex adversarial review"
fi
if in_gates 'Enforce gate verdict'; then
  pass "Gate 3 has an 'Enforce' step"
else
  fail "Gate 3 has no enforce step"
fi

# --- 5. gates-green aggregates + merges -------------------------------------
echo "[5/7] gates-green — aggregate + auto-merge"
if in_gates 'alls-green'; then
  pass "gates-green uses the alls-green aggregate"
else
  fail "gates-green missing alls-green aggregate"
fi
if in_gates 'gh pr merge .* --squash'; then
  pass "gates-green squash-merges only after green"
else
  fail "gates-green does not squash-merge — auto-merge will never fire"
fi

# --- 6. workflow-lint runs actionlint --------------------------------------
echo "[6/7] workflow-lint — actionlint guard"
if in_gates 'rhysd/actionlint'; then
  pass "workflow-lint shellchecks run-blocks via actionlint"
else
  fail "workflow-lint missing actionlint — shell syntax bugs ship unguarded"
fi

# --- 7. Model-choice documentation -----------------------------------------
echo "[7/7] Model-choice docs"
if [ -f "$MODEL_DOC" ]; then
  pass "docs/CI-MODEL-CHOICE.md present"
else
  fail "docs/CI-MODEL-CHOICE.md missing — gate model choice is undocumented"
fi

# --- Forward contract (WARN until the owning stage lands) -------------------
# These two items are part of the TARGET pipeline contract but are not in the
# current foundation yet. They WARN (not FAIL) so this verifier is green against
# the present state; flip each to fail() once its owning stage merges.
echo "[+] Forward contract (not yet landed — informational)"

# Verdict-CONTENT parsing — lands in P1 (Befund 1). Today the enforce steps only
# check the CLI exit code, not the VERDICT: PASS|FAIL|PARTIAL line.
if in_gates 'VERDICT:.*(PASS|FAIL|PARTIAL)'; then
  pass "enforce steps parse the VERDICT content (P1 Befund 1 landed)"
else
  warn "enforce steps do not parse VERDICT content yet — lands in P1 (Befund 1)"
fi

# DeepSeek model switch — lands in Issue #4 (Gate 2/3 CLI-wrapper -> DeepSeek).
# Today the gates authenticate with ANTHROPIC_API_KEY directly.
if in_gates 'ANTHROPIC_BASE_URL' && in_gates 'ANTHROPIC_AUTH_TOKEN'; then
  pass "Gate 2/3 routed via DeepSeek (ANTHROPIC_BASE_URL/_AUTH_TOKEN) — Issue #4 landed"
else
  warn "Gate 2/3 still on ANTHROPIC_API_KEY — DeepSeek switch lands in Issue #4"
fi

# --- Summary ----------------------------------------------------------------
echo
if [ "$fail_count" -eq 0 ]; then
  echo "RESULT: PASS — 0 failing, $warn_count pending forward-contract warning(s)"
  exit 0
fi
echo "RESULT: FAIL — $fail_count failing check(s), $warn_count warning(s)"
exit 1
