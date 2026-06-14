# Architecture Rules

Hard boundaries. Any violation is an automatic Review FAIL on criterion 2.

## Scope of these rules
These rules — the **Layer Model**, **Tech Stack** (pnpm-only / no npm / no yarn), and the
**Forbidden Patterns** (incl. "no raw SQL outside `lib/db/migrations/`") — govern the
**application / runtime code**: `app/`, `components/`, `lib/`, `src/`, `server/`. They do
**not** govern CI plumbing or test scaffolding, which follow their own conventions:
- **CI workflows** (`.github/workflows/`) and their helper shell scripts (`scripts/`) may
  install tooling however the runner requires (e.g. `npm install -g`/`pnpm dlx` a CLI) —
  the pnpm/lockfile rule is about *project dependency management*, not CI tool bootstrap.
- **Test fixtures and test code** (`*.test.ts`, `test/fixtures/`, co-located test data) may
  contain literal SQL or other domain strings as *test inputs* — that is not application
  SQL. A SQL classifier, for instance, necessarily has SQL fixtures. testing.md governs
  fixtures; the "no raw SQL outside migrations" rule does not apply to them.
A reviewer must not FAIL criterion 2 (or Safety) for npm/SQL that lives only in CI workflows,
`scripts/`, or test fixtures.

## Layer Model
- `app/` (Next.js App Router): routing and composition only. No business logic. No direct DB calls.
- `components/`: presentational React components. Props-in, events-out. No fetch, no DB access.
- `lib/`: pure logic, domain services, utilities. No UI imports.
- `lib/db/`: database access only (Drizzle queries). No HTTP, no UI imports.
- `lib/api/`: external API clients. No DB imports.
- `app/api/` and `server/actions/`: server-only entry points. Orchestrate `lib/*`. No logic beyond orchestration.

## Dependency Direction
- Upward only: `app` `components` `lib`. Never the reverse.
- `lib/db` and `lib/api` are siblings. They never import each other. Orchestration happens in `server/actions`.
- No circular imports. If `import/no-cycle` fires, fix before opening the PR.

## Module Boundaries
- Every top-level folder under `src/` has an `index.ts` declaring its public API.
- Cross-folder imports go through `index.ts` only. Deep imports (`../components/Foo/internals/bar`) are banned.

## Tech Stack (enforced)
- Framework: Next.js App Router.
- Language: TypeScript with `strict: true`. No `any` without `// @ts-expect-error: <specific reason>`.
- Styling: Tailwind CSS. No inline `style=` except for dynamic values that cannot be expressed as classes.
- Component library: shadcn/ui. Prefer it over custom primitives.
- Testing: Vitest (unit and integration) + Playwright (E2E). No Jest.
- Package manager: pnpm. No npm, no yarn. `pnpm-lock.yaml` is committed.
- Database: Postgres via Neon + Drizzle ORM. No raw SQL in app code (migrations only).

## Forbidden Patterns
- Global singletons holding mutable state (the typed config module is the only allowed singleton).
- `useEffect` for data fetching in new code. Use React Query or server components.
- Top-level `await` in request paths.
- Inline SQL strings outside `lib/db/migrations/`.
- Secret keys anywhere except via `process.env.*` reads in `lib/config.ts`.

## Change Safety
- Schema change = migration file + regenerated typed queries + Issue labeled `migration`.
- API contract change = version bump in `lib/api/contracts.ts` + changelog entry in `CHANGELOG.md`.
- Config change = documented under `README.md#configuration` in the same PR.
