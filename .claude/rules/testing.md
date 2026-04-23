# Testing Rules

No test no PR. No exceptions.

## Minimum Coverage per PR Type
- **Feature Issue**: at least one Playwright E2E test per acceptance criterion, exercised as a real user flow. Plus Vitest unit tests for any new pure logic in `lib/`.
- **Bug Issue**: at least one regression test that fails on `main` and passes on the fix branch. Test name: `regression: issue-<N>: <short description>`.
- **Spike Issue**: no test required if the Issue carries label `spike` and produces only docs / ADR. State the exemption in the PR body.

## Test Locations
- Unit and integration: co-located as `<file>.test.ts` next to the implementation.
- E2E: `e2e/<feature>.spec.ts`.
- Fixtures: `e2e/fixtures/` and `test/fixtures/`. No hardcoded magic data inline in assertions.

## Writing Order
1. Read the Issue's acceptance criteria.
2. Draft E2E test names from each criterion as `test.skip` stubs.
3. Implement until the stubs pass.
4. Un-skip. Run the full suite. Must be green.

## Flakiness Policy
- A flaky test is a failing test. Fix the root cause or mark `test.fixme` with a linked Issue.
- Do not use `retry: 3` to mask flakes.
- Network-dependent tests mock the network via Playwright `route.fulfill()` or MSW.

## Database Tests
- Use the Neon DB branch provisioned for this worktree. The setup script handles this.
- Never hit the `main` DB branch from tests.
- Every test starts from a known fixture state. No inter-test ordering dependencies.

## CI Enforcement (Gate 1)
`.github/workflows/ci.yml` runs on every `pull_request`:
- `pnpm lint`
- `pnpm typecheck`
- `pnpm test` (Vitest)
- `pnpm test:e2e` (Playwright)
All must be green. Required status check on `main`.

## Failure Handling
If CI fails, read the structured error output posted as a PR comment, fix the specific failure, push. Do not rewrite unrelated code. Never disable or delete the failing test to make CI pass.
