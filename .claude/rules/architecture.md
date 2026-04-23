# Architecture Rules

Hard boundaries. Any violation is an automatic Review FAIL on criterion 2.

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
