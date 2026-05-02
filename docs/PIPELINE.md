# Pipeline Spec — sidehustle-foundation

Canonical reference for the autonomous side-hustle build pipeline. Three projects, three owners, three hops. No shared memory required.

## 3-Hop Architecture

```
PM Project (Cowork)         ->   Master Agent (Cowork)            ->   Builder (Claude Code Desktop)
[ideas, vision, PRDs, specs]    [bootstrap repos, glue, governance]    [code, tests, PRs, gates]
```

## Hop Owners

| Hop | Project | Owns | Output | Trigger to next |
|---|---|---|---|---|
| 1 | PM | Side-hustle ideation, vision, PRD-light, architecture-light, issues, tool-specs | 4 spec files in `Product Manager/Ideas/<slug>/` | One sentence to Jo: `Master Agent: bootstrap side-hustle <slug>` |
| 2 | Master Agent | Pipeline integrity, repo bootstrap, spec ingestion, governance | repo `<slug>` from `sidehustle-foundation` template, specs in `/specs/`, ready Builder-Prompt | Builder-Prompt + setup checklist for Jo |
| 3 | Builder (Claude Code Desktop) | Code, tests, PRs, gate-passes, merge | merged PRs, deployed app | (none — Visual QA on production by Jo) |

## What the Template Ships With

When Master Agent instantiates a repo from `Jobi0202/sidehustle-foundation`, the new repo includes: CLAUDE.md, .claude/rules/* (5 files), .claude/agents/reviewer.md, .claude/commands/review-pr.md, .github/workflows/pr-gates.yml, .github/workflows/enable-auto-merge.yml, .github/workflows/notify-jo.yml, .github/ISSUE_TEMPLATE/*, scripts/* (PowerShell + Bash), .gitignore, README.md.

## Required One-Time Setup per New Repo

1. Install Claude Code GitHub App: https://github.com/apps/claude
2. Install Vercel for GitHub
3. Set repo secrets: ANTHROPIC_API_KEY, OPENAI_API_KEY, NOTION_API_KEY, NOTION_DATABASE_ID, PUSHOVER_APP_TOKEN, PUSHOVER_USER_KEY
4. Branch protection on main: required check = Gates Green (Master Agent automates)
5. Repo settings: enable Auto-Merge, Squash-only (Master Agent automates)

## Anti-Patterns

- Builder creates repo from scratch -> loses every Pipeline file
- PM tells Jo to run gh repo create -> bypasses Master Agent
- Master Agent writes code -> out of scope, Builder territory
- Memory sharing between PM and Master Agent -> both stay isolated, the protocol bridges them
