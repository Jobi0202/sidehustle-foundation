# Anti-Spaghetti Rules

Size and naming caps. Violations fail Review criterion 4 (Code Health).

## File Size Caps
- Source files (`.ts`, `.tsx`): max 300 lines.
- Test files: max 500 lines. Prefer splitting by `describe` block into smaller files.
- Config files (`*.config.ts`): max 150 lines.
- Over cap: split by responsibility into `<name>/<name>.ts` + `<name>/<concern>.ts`.

## Function Complexity
- Max 50 lines per function body. Over extract.
- Max cyclomatic complexity 10 (enforced by ESLint `complexity` rule).
- Max 4 parameters. More pass an object.
- Max 3 levels of nesting. Deeper extract or early-return.

## Naming
- Files: `kebab-case.ts` for modules. `PascalCase.tsx` for React components.
- Components: `PascalCase`. Hooks: `useXxx`. Server actions: `xxxAction`.
- Variables: `camelCase`. Module-top constants: `SCREAMING_SNAKE_CASE`. Local constants: `camelCase`.
- Types and interfaces: `PascalCase`. No `I` prefix. Suffix `Props` for React props, `Input` / `Output` for action signatures.
- Booleans: `is`, `has`, `should`, `can` prefix. Never bare `flag` or `status`.
- Functions: verb-first (`getUser`, `computeTotal`). No `handleXxxThing` unless it is an event handler bound to a DOM node.

## Directory Layout
- Max 10 files per directory (excluding `index.ts` and adjacent tests). Over subfolder.
- Co-locate tests and type files with the module they cover.
- No `utils/` dumping ground. Every utility belongs to a domain folder.

## Import Hygiene
- Absolute imports via `@/` alias (configured in `tsconfig.json`).
- Import group order: (1) std / framework, (2) third-party, (3) `@/`, (4) relative. Blank line between groups. Enforced by ESLint `import/order`.
- No wildcard re-exports (`export *`) from `index.ts`. Enumerate exported symbols.

## Comments
- Comments explain *why*, never *what*.
- JSDoc required on every exported symbol in `lib/`.
- No commented-out code in PRs. Delete it. Git history remembers.
- TODOs must link an Issue: `// TODO(#123): <reason>`. Unlinked TODOs fail Review criterion 4.
