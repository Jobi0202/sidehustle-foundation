# sidehustle-foundation

Autonomous Claude Code operator template for side-hustle MVP development.

This repository is the canonical starting point for any new side-hustle project. Use it as a GitHub template — it ships a pre-configured Claude Code harness with strict architectural rules, an AI-AI double-gate review pipeline, and parallel-agent worktree tooling.

## What This Is

A template repository for building MVPs under the following operating model:
- Claude Code is the autonomous operator (v2.1.49+).
- GitHub Issues are the single source of truth for work.
- Pull Requests are the delivery unit.
- All code review is AI-AI (Claude sub-agent + OpenAI Codex plugin). The Product Owner does Visual QA only.
- Merge gate = CI (Playwright + Vitest + lint + typecheck) + Claude review + Codex adversarial review, all green.

## Structure

```
CLAUDE.md                     operator entrypoint, max 200 lines
.claude/
  rules/
    architecture.md           layer boundaries, stack constraints
    boy-scout.md              in-scope cleanup on every edit
    testing.md                no PR without tests
    review.md                 6-criteria verdict canon
    anti-spaghetti.md         size caps, naming rules
  agents/
    reviewer.md               fresh-context adversarial sub-agent
  commands/
    review-pr.md              custom /review-pr command
.github/
  ISSUE_TEMPLATE/
    feature.yml, bug.yml, spike.yml
scripts/
  new-worktree.{ps1,sh}       worktree + pnpm install
  start-dev.{ps1,sh}          dev server with branch-hashed port
  cleanup-worktrees.{ps1,sh}  remove merged worktrees
```

## Bootstrapping a New Project

1. Create from template: GitHub "Use this template" new repo.
2. Clone locally.
3. Scaffold Next.js into the repo, run `pnpm install` at the root.
4. Configure branch protection on `main`: require the three gates (CI, Claude review, Codex adversarial).
5. Install Codex plugin: `/plugin marketplace add openai/codex-plugin-cc` then `/plugin install codex@openai`.
6. Open your first Issue from a template and let Claude Code take over: `claude -w issue-1`.

## Runtime Target

Optimized for Claude Code CLI v2.1.49+ on Windows (PowerShell) and WSL/Linux. Scripts provided in both `.ps1` and `.sh` variants.

## Status

- M1 — rules, templates, sub-agent, command: delivered
- M2 — worktree + port + cleanup scripts: delivered
- M3 — CI pipeline (Playwright, lint, typecheck), auto-return-to-builder: pending
- M4 — Claude review + Codex adversarial + Notion/Pushover notifications: pending

## Trade-Off Decisions (locked 2026-04-23)

- T1 Review depth: Double-Gate (Claude + Codex both required).
- T2 Notification channel: Notion API update + Pushover webhook alert, fires only after all three gates pass.
