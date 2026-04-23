# Review Criteria Canon

Every reviewer (Claude sub-agent in Gate 2, Codex plugin in Gate 3) applies this rubric. The Builder self-applies it before opening the PR.

## 6 Criteria (PASS / FAIL each)

1. **Issue Match** — The diff implements exactly the acceptance criteria, no more, no less. Evidence: map each AC bullet to a code location.
2. **Architecture Compliance** — The diff respects `architecture.md`. No circular dependencies. No forbidden patterns.
3. **Test Sufficiency** — Tests cover every acceptance criterion. At least one E2E for user-facing changes. Regression test for bugs.
4. **Code Health** — No new magic numbers. No new `any`. No new lint warnings. No unlinked TODO / FIXME. File and function sizes within `anti-spaghetti.md` caps.
5. **Boy Scout** — In-scope smells in touched files are addressed or logged as `tech-debt` Issues. No silent scope creep.
6. **Safety** — No secrets. No disabled security checks. No raw SQL outside `lib/db/migrations/`. No new production-writing code without Issue label `jo-approved`.

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
