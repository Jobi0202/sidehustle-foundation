# CI Model Choice

Which model runs which review gate, why, and how to roll back. Checked by
`scripts/verify-pipeline.sh` (checks 7, 8 + 9) and required reading before touching
the gate auth in `.github/workflows/pr-gates.yml`.

## Current state (foundation)

| Gate | Job | Model / engine | Auth |
| ---- | --- | -------------- | ---- |
| Gate 2 | `claude-review` | DeepSeek (`deepseek-v4-flash`) via the Claude CLI | `ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic` + `ANTHROPIC_AUTH_TOKEN=${DEEPSEEK_API_KEY}` |
| Gate 3 | `codex-adversarial` | OpenAI Codex via `openai/codex-action@v1` (headless) | `OPENAI_API_KEY` only |

**No active Anthropic key.** Gate 2's Claude-CLI host is routed to DeepSeek (Jo's
standing order, DeepSeek-Default since 2026-06-04) to remove pay-per-use Anthropic
credit as a failure mode — the previous `Credit balance is too low` outage on Gate 2.
The `ANTHROPIC_API_KEY` line is retained **commented** in Gate 2's `env` as the
rollback path. Gate 3 carries **no Anthropic/DeepSeek env at all** — it is a pure
OpenAI stack.

Rationale for **cross-family diversity**: Gate 2 reasons with DeepSeek; Gate 3
adversarially re-reviews with OpenAI Codex. A bug one family rationalizes away, the
other is more likely to catch.

## Gate 3 — headless via openai/codex-action (Issue #13, closes #11)

Gate 3 previously installed Codex via `claude /plugin …`, which does not exist in
headless `claude -p` CI (`/plugin isn't available in this environment`) — it failed
at install regardless of backend, and was temporarily made non-blocking. It now runs
the official **`openai/codex-action@v1`** in `sandbox: read-only`: the action runs
`codex exec` against the PR diff with the rubric in `.claude/rules/review.md`, writes
its verdict to `output-file`, which is posted as a PR comment. A format-drift guard
requires a `VERDICT:` line, and the enforce step exits non-zero unless
`VERDICT: PASS` — so **Gate 3 blocks again** and is back in `gates-green`'s `needs:`.

## Rollback — Gate 2 to Anthropic (no code change beyond the env block)

In `claude-review`'s `env`: uncomment `ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}`
and comment the five DeepSeek lines (`ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`,
`ANTHROPIC_MODEL`, `ANTHROPIC_DEFAULT_HAIKU_MODEL`, `CLAUDE_CODE_SUBAGENT_MODEL`), and
restore the `--model claude-haiku-4-5-20251001` flag. Requires a funded
`ANTHROPIC_API_KEY`. Gate 3 has no Anthropic dependency to roll back.

## Planned — architect-gate model (P1)

P1 adds a tier-2 architect gate using an Anthropic Opus-class model authenticated
via `CLAUDE_CODE_OAUTH_TOKEN` (Jo's Claude Max subscription, $0 pay-per-use) rather
than `ANTHROPIC_API_KEY`. That gives three independent families across the gates
(DeepSeek / OpenAI-Codex / Anthropic-Opus). The secret `CLAUDE_CODE_OAUTH_TOKEN`
must be set before that gate goes live (not yet provisioned).
