# Pipeline Spec — sidehustle-foundation

Canonical reference for the autonomous side-hustle build pipeline. Three projects, three owners, three hops. The Builder owns Hop 2 end-to-end via `gh` CLI on Jo's local desktop. Master Agent never touches GitHub.

## 3-Hop Architecture

```
PM Project (Cowork)         ->   Master Agent (Cowork)        ->   Builder (Claude Code Desktop, local)
[ideas, vision, PRDs, specs]    [Builder-Prompt only]              [gh CLI: repo, secrets, branch, build]
```

## Hop Owners

| Hop | Project | Owns | Output |
|---|---|---|---|
| 1 | PM | Spec writing | 4 spec files in `Product Manager/Ideas/<slug>/` + trigger sentence |
| 2 | Master Agent | Prompt assembly only | Builder-Prompt (Copy-Paste-fertig) — NO GitHub API calls, NO repo creation, NO secret setting, NO branch protection |
| 3 | Builder (Claude Code, local) | Everything in GitHub via `gh` CLI | repo created, specs imported, secrets pushed, branch protection set, auto-merge enabled, build starts |

## What the Template Ships With

- CLAUDE.md (operator entrypoint)
- .claude/rules/* (6 rule files)
- .claude/agents/reviewer.md, .claude/commands/review-pr.md
- .github/workflows/pr-gates.yml (thin caller of Jobi0202/sidehustle-ci reusable pipeline), notify-jo.yml, db-deploy.yml, auto-label-risk.yml, fleet-drift-auditor.yml
- .github/ISSUE_TEMPLATE/* (feature, bug, spike)
- scripts/* (worktree, port-from-branch, cleanup) PowerShell + Bash
- scripts/set-secrets-all-repos.sh (bulk-fan-out of central secrets across all owned repos)
- .env.template (schema for the central secrets file)
- README.md, .gitignore

## Builder's `gh`-CLI Bootstrap Sequence (Hop 3)

The Builder receives the Builder-Prompt and runs lexically inside Claude Code Desktop:

1. `gh repo create Jobi0202/<slug> --private --template Jobi0202/sidehustle-foundation`
2. `gh repo clone Jobi0202/<slug>` (into local working dir)
3. `cd <slug>`
4. Copy specs from `<PM_specs_path>` to `./specs/` via `cp` or PowerShell `Copy-Item`
5. Push secrets from central `.env`: `gh secret set -f $env:USERPROFILE\.sidehustle-secrets.env --repo Jobi0202/<slug>`
6. `git add specs/ && git commit -m "feat: import specs" && git push`
7. Branch protection: `gh api --method PUT /repos/Jobi0202/<slug>/branches/main/protection -F required_status_checks[strict]=true -F required_status_checks[contexts][]="Gates Green" -F enforce_admins=false -F required_pull_request_reviews=null -F restrictions=null`
8. Repo settings: `gh api --method PATCH /repos/Jobi0202/<slug> -F allow_auto_merge=true -F delete_branch_on_merge=true -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false`
9. Read `specs/issues.md`, begin with Issue #1 (Setup Issue), follow CLAUDE.md Core-Loop strictly.

## Required One-Time Setup (per machine, NOT per repo)

Jo creates ONCE, never again:
- File: `%USERPROFILE%\.sidehustle-secrets.env` (Windows) / `~/.sidehustle-secrets.env` (WSL)
- Format: see `.env.template` in this repo
- Contents: ANTHROPIC_API_KEY, DEEPSEEK_API_KEY, OPENAI_API_KEY, NOTION_API_KEY, NOTION_DATABASE_ID, PUSHOVER_APP_TOKEN, PUSHOVER_USER_KEY
- Plus: Claude Code GitHub App pre-installed account-wide (one-time grant), Vercel for GitHub installed account-wide

## Rotating Secrets / Back-Filling Older Repos

A key changed (DeepSeek rotation, Anthropic re-issue, …) or an older repo predates a newly added secret? Don't visit each repo. One command pushes the central `.env` into every owned non-archived repo:

```bash
# Edit the value in $HOME/.sidehustle-secrets.env, then:
bash scripts/set-secrets-all-repos.sh                       # all repos
bash scripts/set-secrets-all-repos.sh --repo elternplan-studio   # one repo
bash scripts/set-secrets-all-repos.sh --dry-run             # preview targets
```

Idempotent — re-running overwrites existing values. Secret VALUES never appear in logs (only names + repo identifiers). The script lives at `scripts/set-secrets-all-repos.sh` in every project cloned from this template.

## Anti-Patterns

- Master Agent calling GitHub API for Hop 2 work — NEVER. That's Builder territory.
- Manual file-by-file template clone via API — NEVER. `gh repo create --template` is one line.
- PM telling Jo to do GitHub setup — NEVER. PM only emits trigger sentence.
- Org-Secrets migration — Free Plan doesn't need Org. Central `.env` solves it cleaner.
