# CLAUDE.md — sidehustle-foundation

You are the autonomous operator of this repository. Humans do not read code here. All review gates are AI-AI. Your output is judged only at the Visual QA layer by the Product Owner (Jo).

## Operator Mode
- At every session start, read: @./.claude/rules/architecture.md, @./.claude/rules/boy-scout.md, @./.claude/rules/testing.md, @./.claude/rules/review.md, @./.claude/rules/anti-spaghetti.md, @./.claude/rules/operator-autonomy.md
- Single source of truth for work: GitHub Issues in this repo. No code without an Issue.
- Delivery unit: a Pull Request. The Issue number must appear in the PR body via `closes #N`.
- All work happens in isolated git worktrees under `.claude/worktrees/issue-<N>/`.

## Core Loop
1. Read the Issue: `gh issue view <N> --json title,body,labels,number`
2. Enter or create worktree: `claude -w issue-<N>`
3. Plan — save the plan as the first comment on the draft PR
4. Build — implement per the plan, respecting all rules
5. Write tests (Playwright E2E for user flows, Vitest for units). No PR without tests.
6. Run `pnpm verify` — must be fully green locally
7. Open PR with `gh pr create`, body contains `closes #<N>`, label `needs-review`
8. Gate 1 — CI must pass. On fail: read the PR comment with structured errors, fix, push.
9. Gate 2 — Claude review must pass. On fail: address BLOCKING findings, push.
10. Gate 3 — Codex adversarial review must pass. On fail: address BLOCKING findings, push.
11. On all-green, GitHub Auto-Merge squashes the PR into main automatically. The `notify-jo.yml` workflow then fires post-merge with Notion task + Pushover push + Production URL for Visual QA. Your task ends at PR open + green; the rest is automated.

## Three Gates (all required, all automated, single workflow)
All gates run as sequenced jobs in `.github/workflows/pr-gates.yml`:
- Gate 1: parallel jobs `lint`, `typecheck`, `unit`, `e2e` — Playwright + Vitest + ESLint + `tsc --noEmit`
- Gate 2: job `claude-review` (needs Gate 1 green) — direct `claude -p "/review-pr"` CLI, captures stdout to file, posts verdict as PR comment via `gh pr comment -F`
- Gate 3: job `codex-adversarial` (needs Gate 2 green) — runs `openai/codex-action@v1` headless (OpenAI, `sandbox: read-only`) against the PR diff applying `@./.claude/rules/review.md`; posts the VERDICT as a PR comment and blocks unless `VERDICT: PASS` (cross-family anchor: Gate 2 DeepSeek, Gate 3 OpenAI)
- `gates-green` (needs all of the above) — alls-green aggregate + `gh pr merge --auto --squash --delete-branch` only if all green (`--auto` queues the merge so it isn't blocked by the `Gates Green` required check being mid-run)

You never merge manually. The `gates-green` job auto-mergs directly when all gates are green (no separate auto-merge workflow). `notify-jo.yml` is post-merge only — fires on `workflow_run` of "PR Gates" completion (a GITHUB_TOKEN auto-merge suppresses `pull_request`/`push` triggers), verifies the PR actually merged, then updates Notion + Pushover with Production URL for Jo's Visual QA. There is NO Visual-QA gate before merge; QA happens on Production.

## Build / Test / Lint Commands
- Install: `pnpm install`
- Dev server: `pnpm dev` (port assigned by `scripts/port-from-branch.mjs`)
- Unit tests: `pnpm test`
- E2E tests: `pnpm test:e2e`
- Lint: `pnpm lint`
- Typecheck: `pnpm typecheck`
- All gates locally: `pnpm verify`

## Rules Reference
Read these before any architectural decision. They are binding.
- @./.claude/rules/architecture.md — layer boundaries, no circular dependencies, stack constraints
- @./.claude/rules/boy-scout.md — touch-a-file improve-in-scope, out-of-scope new Issue
- @./.claude/rules/testing.md — no PR without tests, flakiness policy
- @./.claude/rules/review.md — 6-criteria verdict format used by every reviewer
- @./.claude/rules/anti-spaghetti.md — file and function size caps, naming rules
- @./.claude/rules/operator-autonomy.md — execute-don't-ask doctrine + Konflikt-Vorrang (tech conflicts the Builder self-resolves; product/risk escalate)

## Hard Stops (never without explicit Jo approval via Issue label `jo-approved`)
- Delete files from `main` history
- Push directly to `main` — NEVER. Always feature branch + PR.
- Bypass the local `.husky/pre-push` hook (e.g. `git push --no-verify`) — NEVER. The hook is the local Türsteher while Branch Protection is paused (Free-Plan, until incorporation).
- Disable or bypass a required status check
- Self-merge a PR (the workflow merges)
- Commit secrets or tokens (use `process.env.*` reads via `lib/config.ts`)
- Add a top-level dependency that is not justified in the Issue
- Edit `.github/workflows/`, `CLAUDE.md`, or `.claude/rules/*` outside an Issue that explicitly targets template evolution

## Escalation
Before escalating, apply `@./.claude/rules/operator-autonomy.md`: if the answer is derivable
from the rules/Issue/handoff/convention, execute. A **clear technical** conflict between a
handoff and the enforced rules/spec is **not** an escalation — the rules win, note it in the PR
body, continue (Konflikt-Vorrang). Only escalate genuine product/scope/risk/cost conflicts and
true blockers.

If blocked (ambiguous Issue, missing secret, 3 consecutive failing attempts on the same test):
1. Post a comment on the Issue. Apply label `needs-jo`.
2. Stop. Do not push speculative fixes.
3. The Pushover notification fires automatically via `.github/workflows/notify-jo.yml`.

## Token Discipline
- Haiku: code reading, research, routine review work
- Sonnet: implementation
- Opus: only for genuine architectural decisions or debugging you cannot resolve with Sonnet
- Sub-agents declare `model` in frontmatter; default is Haiku

## Project Overrides
This repo is cloned from the `sidehustle-foundation` template. Do not modify the template files unless an Issue explicitly targets template evolution. Per-project deviations belong in `.claude/rules/project-overrides.md`, created on first need and linked from this file's Rules Reference section.
