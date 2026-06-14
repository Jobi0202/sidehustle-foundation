# Review Criteria Canon

Every reviewer (Claude sub-agent in Gate 2, Codex plugin in Gate 3) applies this rubric. The Builder self-applies it before opening the PR.

## 6 Criteria (PASS / FAIL each)

1. **Issue Match** — The diff implements exactly the acceptance criteria, no more, no less. Evidence: map each AC bullet to a code location.
2. **Architecture Compliance** — The diff respects `architecture.md`. No circular dependencies. No forbidden patterns.
3. **Test Sufficiency** — Tests cover every acceptance criterion. At least one E2E for user-facing changes. Regression test for bugs.
4. **Code Health** — No new magic numbers. No new `any`. No new lint warnings. No unlinked TODO / FIXME. File and function sizes within `anti-spaghetti.md` caps.
5. **Boy Scout** — In-scope smells in touched files are addressed or logged as `tech-debt` Issues. No silent scope creep.
6. **Safety** — No secrets. No disabled security checks. No raw SQL outside `lib/db/migrations/`. **Risk paths are auto-labeled, not hand-set:** `.github/workflows/auto-label-risk.yml` stamps `risk:requires-review` on any PR touching migrations, `auth/`, `payments/`, `rls/`, or a write API route (POST/PUT/PATCH/DELETE handler). When that label is present, branch protection requires an architect review before merge — FAIL this criterion if a risk-path change lacks it. Reviewers no longer apply the label manually. For non-risk PRs, just verify no secrets / disabled checks / out-of-migration SQL.

## Severity Gate (Gate 3 — only CRITICAL blocks)

Gate 3 (the `codex-adversarial` job) applies a severity threshold so the gate converges
instead of looping on nits. Every finding is classified as exactly one of:

- **CRITICAL** — a security vulnerability, a correctness/logic bug, or a violation of an
  architecture invariant in `architecture.md` (a forbidden pattern, a layer or
  dependency-direction break, a missing module `index.ts`, raw SQL outside
  `lib/db/migrations/`, a committed secret, or a risk-path change missing its required
  label). Only CRITICAL findings cause `VERDICT: FAIL`.
- **ADVISORY** — everything else: style, naming, magic numbers, documentation drift, test
  rigor/coverage suggestions, robustness/edge-case hardening, performance, "nice to have".
  ADVISORY findings are posted for the Builder but **never** cause FAIL and never reset the
  review loop.

Gate 3 emits `VERDICT: FAIL` iff at least one CRITICAL finding is open, else `VERDICT: PASS`,
plus a machine-readable `SEVERITY_SUMMARY: CRITICAL=<n> ADVISORY=<m>` line that the workflow
parses as the authoritative gate.

## Verdict Format (reviewer must emit exactly this)

```
VERDICT: PASS | FAIL | PARTIAL

CRITERIA:
- Issue Match: PASS | FAIL — <one-line evidence>
- Architecture: PASS | FAIL — <one-line evidence>
- Test Sufficiency: PASS | FAIL — <one-line evidence>
- Code Health: PASS | FAIL — <one-line evidence>
- Boy Scout: PASS | FAIL — <one-line evidence>
- Safety: PASS | FAIL — <one-line evidence>

BLOCKING FINDINGS:
1. <path:line> — <specific fix required>
2. ...

NON-BLOCKING SUGGESTIONS:
- <optional polish items, Builder may ignore>
```

## PASS Requires
- All 6 criteria marked PASS.
- Zero BLOCKING findings.

## FAIL Requires Action
Builder reads the structured verdict, addresses every BLOCKING finding, pushes. The reviewer workflow re-runs automatically on the new push.

## Re-Review Delta (every cycle after the first)
On a re-review, the reviewer reads its previous VERDICT on the PR and checks EACH prior
blocking finding against the CURRENT diff — marking it `BEHOBEN` (with file/SHA evidence)
or `WEITERHIN OFFEN` — then recomputes the verdict from the current state. Do not repeat
a first-snapshot judgment, and do not open new side-quest findings when the prior ones are
resolved. This is what makes the loop converge instead of surfacing a fresh nit each cycle.

## Merge Discrepancy (Gate 2 vs Gate 3)
When Gate 2 and Gate 3 contradict each other on the same criterion (one PASS, one FAIL),
the later gate posts a short **discrepancy note** as a PR comment — naming the criterion,
the file/line, and the SHA it judged — and applies the `review-bot-drift` label so the
divergence is visible rather than silently resolved by merge order. This does not change
the merge rule (Gate 3's severity gate still decides) and does not duplicate the **Loop
Cap** below — it only records that the two reviewers disagreed.

## Loop Cap & Escalation Routing
Maximum 3 review cycles per PR. Before the cap forces an escalation, apply these rules.

### Recurring bug-class → restructure, don't keep guessing
If Gate 3 surfaces the **same class of bug ≥ 2 times** (e.g. an aggregate check that a
later statement masks, an edge case in the same parser), do NOT keep guessing one fix per
Gate-3 cycle. **Autonomously restructure** the offending logic into a separately
**unit-tested** unit — extract a script or module and add tests against fixtures so the
whole class is caught **locally**, then push once. This is "restructure rather than thrash";
it is the expected behaviour, not an escalation.

### Technical loop-cap → `needs-architect` (NOT `needs-jo`)
On 3 consecutive FAILs that are purely **technical** (code correctness, classifier/parse
logic, workflow mechanics, architecture-rule interpretation), label the PR
**`needs-architect`** and post a **structured decision request** in the PR body: the precise
options, the trade-offs, and your recommendation. This routes to the architect process —
**Jo only forwards it, Jo does not decide** the technical call.

### `needs-jo` is reserved
Apply **`needs-jo`** ONLY for: a **tier-3** risk decision (money/data-loss/consent), a
**cost/billing/quota** blocker, or a **product/strategy** question. Never for a technical
loop-cap.
