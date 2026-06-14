# sidehustle-foundation

🟢 **Live:** _set automatically by Builder Step 8.5 in cloned repos_

Template repository for autonomous side-hustle MVP development with Claude Code.

## Quick Start

For a new side-hustle, paste into a Master Agent (Cowork) session:

```
Master Agent: bootstrap side-hustle <slug>
Specs liegen in: Product Manager/Ideas/<slug>/
```

Master Agent returns the Builder-Prompt; paste it into Claude Code Desktop. Builder runs `gh repo create --template`, imports specs, sets up the pipeline, and starts Issue #1. You QA on production, that's it.

## Requirements (one-time per machine)

- `gh` CLI authenticated (`gh auth login`)
- `~/.sidehustle-secrets.env` filled (see `.env.template`)
- Claude Code GitHub App installed account-wide: https://github.com/apps/claude
- Vercel for GitHub installed account-wide

## Pipeline (what this template ships)

- `CLAUDE.md` operator manual
- `.claude/rules/*` — 6 rule files (architecture, boy-scout, testing, review, anti-spaghetti, operator-autonomy)
- `.claude/agents/reviewer.md` + `.claude/commands/review-pr.md`
- `.github/workflows/pr-gates.yml` — thin caller of the shared reusable pipeline `Jobi0202/sidehustle-ci/.github/workflows/pr-gates-reusable.yml@main` (`secrets: inherit`); the 9 gate jobs + alls-green live there, once, for the whole fleet
- `.github/workflows/enable-auto-merge.yml` — squash-auto-merge on PR open
- `.github/workflows/notify-jo.yml` — Notion + Pushover post-merge
- `.github/ISSUE_TEMPLATE/*` — feature, bug, spike
- `scripts/*` — worktree, port-from-branch, cleanup (PowerShell + Bash)
- `.husky/pre-push` — main-branch protection (Free-Plan local Türsteher while server-side Branch Protection is paused)
- `.env.template` — schema for the central secrets file

Full architecture: [`docs/PIPELINE.md`](docs/PIPELINE.md). Handoff protocol: [`docs/HANDOFF-PROTOCOL.md`](docs/HANDOFF-PROTOCOL.md).

## Trade-offs (locked 2026-04-23, reviewed 2026-05-02)

- **Review depth:** Double-Gate (Claude review + Codex adversarial). Both must pass.
- **Notification:** Notion task + Pushover push, post-merge.
- **Branch protection:** Husky local hook (server-side Branch Protection paused on Free Plan until incorporation; see `feedback_branch_protection_private_free.md` in Master Agent memory for re-eval triggers).

## Use this template

GitHub UI: "Use this template" button. Or:

```
gh repo create <org>/<slug> --private --template Jobi0202/sidehustle-foundation --clone
```

The full bootstrap sequence (specs import, secrets push, auto-merge enable, build start) is in `templates/builder-bootstrap-prompt.md` — Master Agent fills it in for you.
