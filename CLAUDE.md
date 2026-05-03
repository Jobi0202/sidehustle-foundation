# CLAUDE.md — sidehustle-foundation

You are the autonomous operator of this repository. Humans do not read code here. All review gates are AI-AI. Your output is judged only at the Visual QA layer by the Product Owner (Jo).

## Operator Mode
- At every session start, read: @./.claude/rules/architecture.md, @./.claude/rules/boy-scout.md, @./.claude/rules/testing.md, @./.claude/rules/review.md, @./.claude/rules/anti-spaghetti.md
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
11. On all-green, the notification workflow alerts Jo with the Vercel Preview URL. Your task ends there.

## Three Gates (all required, all automated)
- Gate 1: `.github/workflows/ci.yml` — Playwright + Vitest + ESLint + `tsc --noEmit`
- Gate 2: `.github/workflows/claude-review.yml` — invokes `/review-pr` in fresh context via the `reviewer` sub-agent
- Gate 3: `.github/workflows/codex-adversarial.yml` — invokes `/codex:adversarial-review` from openai/codex-plugin-cc

You never merge. The `notify-jo.yml` workflow merges on all-green after Jo's Visual QA approval.

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
