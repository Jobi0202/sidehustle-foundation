---
description: Fresh-context adversarial review of the current branch's PR. Invokes the reviewer sub-agent in an isolated worktree. Emits PASS/FAIL verdict as a PR comment.
argument-hint: "[pr-number-optional]"
allowed-tools: Bash, Task, Read
model: haiku
---

# /review-pr

Run a fresh-context code review of a Pull Request.

## Context Reset Check
Before invoking the reviewer, `/clear` must have been applied by the calling workflow. If you detect any prior conversation content, STOP and exit non-zero — the command is being misused.

## Execution

1. Determine the target PR number.
   - If `$1` is provided, use it.
   - Otherwise: `gh pr view --json number -q .number` for the current branch.
2. Verify the PR exists and is open: `gh pr view $PR --json state -q .state` must equal `OPEN`. If not, exit 1.
3. Invoke the `reviewer` sub-agent via the Task tool:
   - `subagent_type`: `reviewer`
   - `isolation`: `worktree`
   - `prompt`: "Review PR #$PR strictly against @./.claude/rules/review.md. Follow the workflow in your sub-agent definition. Post the verdict as a PR comment. Exit 0 on PASS, 1 on FAIL or PARTIAL."
4. Capture the sub-agent's exit code and propagate it as the command's exit code.

## Prohibited
- Do not run implementation code, "just to check".
- Do not edit the diff.
- Do not post PR comments outside the verdict format.
- Do not merge the PR under any circumstances.

## Called By
`.github/workflows/claude-review.yml`, headless: `claude -p "/review-pr $PR_NUMBER" --output-format=stream-json`
