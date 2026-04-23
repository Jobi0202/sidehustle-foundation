# Boy Scout Rule

When you touch a file, leave it cleaner than you found it — strictly within your Issue scope.

## On Every File Edit
1. Scan the file for: dead code, magic numbers, unclear names, duplicated logic, missing types, missing JSDoc on exported symbols.
2. Fix items that are in scope of your current Issue.
3. For larger smells that are out of scope: open a new Issue with label `tech-debt`, referencing file and line. Do not silently refactor.

## Scope Definition
- In scope: any code path reachable from the Issue's acceptance criteria that you read while implementing.
- Out of scope: everything else, including tempting adjacent improvements.

## Hard Rules
- No scope creep. If the diff grows beyond the Issue, split into separate PRs.
- No "while I'm here" cross-module refactors. One PR, one concern.
- If a cleanup requires more than 10 changed lines outside the feature path, open an Issue instead.
- Replace magic numbers with named constants in the same file.
- Rename only if the old name is actively misleading, not merely improvable.

## Commit Discipline
- One commit = one logical change.
- Conventional Commit prefixes required: `feat:`, `fix:`, `refactor:`, `test:`, `chore:`, `docs:`.
- Refactor commits do not mix with feat commits in the same PR unless the refactor is a direct prerequisite (state that prerequisite in the commit body).

## Reviewer Signal
If the reviewer sub-agent flags scope creep, revert the out-of-scope changes and re-push. Do not argue in the PR comment.
