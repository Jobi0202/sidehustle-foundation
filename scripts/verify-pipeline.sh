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
#   FAIL  — drift from the foundation contract. Exits 1.
#   WARN  — a known, tracked temporary state (e.g. a gate intentionally made
#           non-blocking under an open Issue). Informational only; does NOT affect
#           the exit code. Each WARN names the Issue that clears it.
#
set -uo pipefail

ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || echo .)"
GATES="$ROOT/.github/workflows/pr-gates.yml"
MODEL_DOC="$ROOT/docs/CI-MODEL-CHOICE.md"

REQUIRED_JOBS="workflow-lint lint typecheck unit e2e claude-review codex-adversarial architect-gate gates-green"

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
echo "[1/10] Workflow file"
if [ -f "$GATES" ]; then
  pass ".github/workflows/pr-gates.yml present"
else
  fail ".github/workflows/pr-gates.yml missing — no pipeline at all"
  echo
  echo "RESULT: FAIL ($fail_count failing) — cannot continue without pr-gates.yml"
  exit 1
fi

# --- 2. Required jobs present ----------------------------------------------
echo "[2/10] Required jobs"
for job in $REQUIRED_JOBS; do
  if grep -qE "^[[:space:]]{2}${job}:" "$GATES"; then
    pass "job '$job' defined"
  else
    fail "job '$job' missing from pr-gates.yml"
  fi
done

# --- 3. Gate 2 (claude-review) posts + enforces a verdict -------------------
echo "[3/10] Gate 2 — Claude review verdict"
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
if in_gates 'only VERDICT: PASS passes'; then
  pass "Gate 2 enforce parses the VERDICT content (not just the CLI exit code)"
else
  fail "Gate 2 enforce does not parse VERDICT content — a FAIL verdict with exit 0 would pass"
fi

# --- 4. Gate 3 (codex-adversarial) posts + enforces ------------------------
echo "[4/10] Gate 3 — Codex adversarial verdict"
if in_gates 'openai/codex-action'; then
  pass "Gate 3 runs openai/codex-action (headless OpenAI)"
else
  fail "Gate 3 does not run openai/codex-action"
fi
if in_gates 'model:[[:space:]]*gpt-5\.3-codex' && in_gates 'effort:[[:space:]]*medium'; then
  pass "Gate 3 pins the codex model (gpt-5.3-codex) + effort (medium) for predictable cost"
else
  fail "Gate 3 codex model/effort not pinned — cost drifts with the action default"
fi
if in_gates 'Enforce gate verdict'; then
  pass "Gate 3 has an 'Enforce' step"
else
  fail "Gate 3 has no enforce step"
fi
if in_gates 'steps\.codex\.outcome'; then
  pass "Gate 3 enforce checks the codex-action outcome (no continue-on-error masking)"
else
  fail "Gate 3 does not verify codex-action succeeded — continue-on-error could mask a failure"
fi
if in_gates 'SEVERITY_SUMMARY' && in_gates 'CRITICAL finding'; then
  pass "Gate 3 carries the severity gate (only CRITICAL findings block; advisories do not)"
else
  fail "Gate 3 missing the severity gate — non-critical findings would still block merge"
fi
if in_gates 'head -n1 codex-output'; then
  pass "Gate 3 pins the verdict to the canonical first line (head -n1)"
else
  fail "Gate 3 does not pin the verdict to line 1 — preamble/duplicate VERDICT could be honored"
fi

# --- 5. gates-green aggregates + merges -------------------------------------
echo "[5/10] gates-green — aggregate + auto-merge"
if in_gates 'alls-green'; then
  pass "gates-green uses the alls-green aggregate"
else
  fail "gates-green missing alls-green aggregate"
fi
if in_gates 'gh pr merge .* --auto --squash'; then
  pass "gates-green enables auto-merge (--auto --squash) only after green"
else
  fail "gates-green must use 'gh pr merge --auto --squash' — an immediate merge deadlocks on the Gates Green required check"
fi

# --- 6. workflow-lint runs actionlint --------------------------------------
echo "[6/10] workflow-lint — actionlint guard"
if in_gates 'rhysd/actionlint'; then
  pass "workflow-lint shellchecks run-blocks via actionlint"
else
  fail "workflow-lint missing actionlint — shell syntax bugs ship unguarded"
fi

# --- 7. Model-choice documentation -----------------------------------------
echo "[7/10] Model-choice docs"
if [ -f "$MODEL_DOC" ]; then
  pass "docs/CI-MODEL-CHOICE.md present"
else
  fail "docs/CI-MODEL-CHOICE.md missing — gate model choice is undocumented"
fi

# --- 8. DeepSeek routing + VERDICT format guard ----------------------------
# Both landed in the DeepSeek/P0 reconcile PR — now part of the hard contract.
echo "[8/10] DeepSeek routing + VERDICT guard"
if in_gates 'ANTHROPIC_BASE_URL' && in_gates 'ANTHROPIC_AUTH_TOKEN'; then
  pass "Gate 2 routed via DeepSeek (ANTHROPIC_BASE_URL + ANTHROPIC_AUTH_TOKEN)"
else
  fail "Gate 2 not on DeepSeek — expected ANTHROPIC_BASE_URL + ANTHROPIC_AUTH_TOKEN"
fi
if in_gates 'Verify VERDICT format present'; then
  pass "Gate 2/3 have a VERDICT format-drift guard"
else
  fail "missing VERDICT format-drift guard in Gate 2/3"
fi

# --- 9. Gate 3 is blocking (in gates-green needs) ---------------------------
echo "[9/10] Gate 3 blocking"
gg_needs="$(grep -A8 '^  gates-green:' "$GATES" | grep -E '^[[:space:]]*needs:' | head -1)"
case "$gg_needs" in
  *codex-adversarial*) pass "Gate 3 (codex-adversarial) is in gates-green needs: — blocking" ;;
  *) fail "Gate 3 (codex-adversarial) NOT in gates-green needs: — auto-merge ignores Gate 3" ;;
esac

# --- 10. Risk tiering: classifier + architect-gate + tier-3 schranke ---------
echo "[10/10] Risk tiering"
RISK="$ROOT/.github/workflows/auto-label-risk.yml"
if [ -f "$RISK" ] && grep -q 'tier-1' "$RISK" && grep -q 'tier-2' "$RISK" && grep -q 'tier-3' "$RISK"; then
  pass "auto-label-risk classifies into tier-1/tier-2/tier-3"
else
  fail "auto-label-risk does not emit the three tier labels"
fi
case "$gg_needs" in
  *architect-gate*) pass "architect-gate is in gates-green needs: — tier-2 is blocking" ;;
  *) fail "architect-gate NOT in gates-green needs: — tier-2 changes would not be gated" ;;
esac
if in_gates 'tier-3' && in_gates 'jo-approved'; then
  pass "gates-green has the tier-3 + jo-approved schranke"
else
  fail "gates-green missing the tier-3 schranke"
fi

# --- Summary ----------------------------------------------------------------
echo
if [ "$fail_count" -eq 0 ]; then
  echo "RESULT: PASS — 0 failing, $warn_count warning(s) (see above)"
  exit 0
fi
echo "RESULT: FAIL — $fail_count failing check(s), $warn_count warning(s)"
exit 1
