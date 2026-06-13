# CI Model Choice

Which model runs which review gate, why, and how to roll back. Checked by
`scripts/verify-pipeline.sh` (check 7) and required reading before touching the
gate auth in `.github/workflows/pr-gates.yml`.

## Current state (foundation, as of this PR)

| Gate | Job | Model / engine | Auth secret |
| ---- | --- | -------------- | ----------- |
| Gate 2 | `claude-review` | Claude Haiku (`claude-haiku-4-5-20251001`) | `ANTHROPIC_API_KEY` |
| Gate 3 | `codex-adversarial` | OpenAI Codex (via `codex-plugin-cc`) | `OPENAI_API_KEY` (+ `ANTHROPIC_API_KEY` to run the CLI host) |

Rationale for **cross-family diversity**: Gate 2 and Gate 3 must not share a
failure mode. Gate 2 reasons with an Anthropic model; Gate 3 adversarially
re-reviews with an OpenAI model. A bug that one family rationalizes away, the
other is more likely to catch.

## Planned switch — DeepSeek for Gate 2 (Issue #4)

Issue #4 ("DeepSeek default for Gate 2 + Gate 3 (CLI-wrapper)") moves the
Anthropic-CLI-hosted gates onto DeepSeek to cut pay-per-use cost, by pointing the
Claude CLI at the DeepSeek-compatible endpoint:

```
# Target (Issue #4 — NOT yet in foundation):
ANTHROPIC_BASE_URL: <deepseek endpoint>
ANTHROPIC_AUTH_TOKEN: ${{ secrets.DEEPSEEK_API_KEY }}
# ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}   # rollback: uncomment to revert
```

Gate 3's Codex engine stays on OpenAI regardless — the DeepSeek switch only
affects the Anthropic-CLI-hosted gates. `verify-pipeline.sh` WARNs (does not
fail) on the missing DeepSeek block until Issue #4 lands, then the check flips to
a hard FAIL.

`DEEPSEEK_API_KEY` is already provisioned as a repo secret; the switch is held
until the migration is reviewed and applied by Jo (the gate-routing change is
intentionally not auto-pushed).

## Planned — architect-gate model (P1)

P1 adds a tier-2 architect gate that uses an Anthropic Opus-class model
authenticated via `CLAUDE_CODE_OAUTH_TOKEN` (Jo's Claude Max subscription, $0
pay-per-use) rather than `ANTHROPIC_API_KEY`. That gives three independent model
families across the three gates (DeepSeek / Codex / Anthropic-Opus). The secret
`CLAUDE_CODE_OAUTH_TOKEN` must be set before that gate goes live.

## Rollback

To revert any gate to Anthropic pay-per-use: uncomment the `ANTHROPIC_API_KEY`
line in the job env and remove the `ANTHROPIC_BASE_URL` / `ANTHROPIC_AUTH_TOKEN`
pair. No code change beyond the workflow env block is required.
