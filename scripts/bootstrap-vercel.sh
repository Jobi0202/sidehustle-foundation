#!/usr/bin/env bash
#
# bootstrap-vercel.sh — run EXACTLY ONCE per Idea-Repo, to wire Vercel for 0-touch deploys.
#
# What it does:
#   1. `vercel link`        — bind this directory to a Vercel project (creates it if needed).
#   2. `vercel git connect`  — connect the project to the GitHub repo so pushes deploy.
#   3. Ensure the Production Branch is `main` — so every green merge to main auto-promotes
#      to Production. Visual QA then happens on the Production URL (no pre-merge QA gate).
#
# After this, deploys are 0-touch: merge to main -> Vercel builds + promotes to prod.
# Idempotent: re-running re-links and re-asserts the production branch without harm.
#
# Required env (never committed):
#   VERCEL_TOKEN  — a Vercel access token (or run `vercel login` interactively first)
# Optional:
#   VERCEL_ORG_ID / VERCEL_PROJECT_ID — pre-bind a known project non-interactively.
#
set -euo pipefail

if ! command -v vercel >/dev/null 2>&1; then
  echo "::error::vercel CLI not found — install it first (npm i -g vercel)." >&2
  exit 1
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$ROOT"

TOKEN_ARG=()
if [ -n "${VERCEL_TOKEN:-}" ]; then
  TOKEN_ARG=(--token "$VERCEL_TOKEN")
fi

# 1. link this checkout to its Vercel project.
echo "==> vercel link"
vercel link --yes "${TOKEN_ARG[@]}"

# 2. connect the project to its GitHub repo so commits trigger deploys.
echo "==> vercel git connect"
vercel git connect --yes "${TOKEN_ARG[@]}"

# 3. assert Production Branch = main. The CLI does not expose this directly; surface it as a
#    manual-confirm so the operator sets it in the Vercel dashboard (Settings -> Git ->
#    Production Branch) if it is not already `main`.
echo
echo "==> MANUAL-CONFIRM: Vercel Production Branch must be 'main'."
echo "    Dashboard -> Project -> Settings -> Git -> Production Branch = main."
echo "    With that set, every green merge to main auto-promotes to Production (0-touch)."
echo
echo "==> Vercel bootstrap complete."
