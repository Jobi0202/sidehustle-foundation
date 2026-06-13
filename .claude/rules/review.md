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

## Loop Cap
Maximum 3 review cycles per PR. On the 4th consecutive FAIL, the workflow labels the PR `needs-jo` and triggers Pushover. The Builder stops pushing and waits.
