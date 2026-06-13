# CI Model Choice

Which model runs which review gate, why, and how to roll back. Checked by
`scripts/verify-pipeline.sh` (checks 7 + 8) and required reading before touching
the gate auth in `.github/workflows/pr-gates.yml`.

## Current state (foundation)

| Gate | Job | Model / engine | Auth |
| ---- | --- | -------------- | ---- |
| Gate 2 | `claude-review` | DeepSeek (`deepseek-v4-flash`) via the Claude CLI | `ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic` + `ANTHROPIC_AUTH_TOKEN=${DEEPSEEK_API_KEY}` |
| Gate 3 | `codex-adversarial` | OpenAI Codex (via `codex-plugin-cc`); CLI host on DeepSeek | `OPENAI_API_KEY` for Codex + DeepSeek env for the CLI host |

**No active Anthropic key.** Both gates' Claude-CLI host is routed to DeepSeek
(Jo's standing order, DeepSeek-Default since 2026-06-04) to remove pay-per-use
Anthropic credit as a failure mode — the previous `Credit balance is too low`
outage on Gate 2. The `ANTHROPIC_API_KEY` line is retained **commented** in each
job's `env` as the rollback path.

Rationale for **cross-family diversity**: Gate 2 reasons with DeepSeek; Gate 3's
adversarial reviewer talks to the OpenAI Responses API directly. A bug one family
rationalizes away, the other is more likely to catch. The Codex engine stays on
OpenAI regardless of the CLI-host routing.

## ⚠️ Gate 3 is temporarily NON-BLOCKING (Issue #11)

`codex-adversarial` installs Codex via `claude /plugin …`, which is unavailable in
headless `claude -p` CI (`/plugin isn't available in this environment`) — it fails
at install regardless of backend. Until **Issue #11** redesigns the headless Codex
invocation, the job is removed from `gates-green`'s `needs:` (and thus the
`alls-green` aggregation). It still runs and posts its verdict; it just does not
block auto-merge. `verify-pipeline.sh` emits a tracked WARN while this holds.

## Rollback (per gate, no code change beyond the env block)

In the job's `env`: uncomment `ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}`
and comment the five DeepSeek lines (`ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`,
`ANTHROPIC_MODEL`, `ANTHROPIC_DEFAULT_HAIKU_MODEL`, `CLAUDE_CODE_SUBAGENT_MODEL`).
For Gate 2 also restore the `--model claude-haiku-4-5-20251001` flag. Requires a
funded `ANTHROPIC_API_KEY`.

## Planned — architect-gate model (P1)

P1 adds a tier-2 architect gate using an Anthropic Opus-class model authenticated
via `CLAUDE_CODE_OAUTH_TOKEN` (Jo's Claude Max subscription, $0 pay-per-use) rather
than `ANTHROPIC_API_KEY`. That gives three independent families across the gates
(DeepSeek / Codex / Anthropic-Opus). The secret `CLAUDE_CODE_OAUTH_TOKEN` must be
set before that gate goes live (not yet provisioned).
