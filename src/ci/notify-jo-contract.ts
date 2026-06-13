/**
 * Contract constants for the post-merge notification workflow, asserted by the
 * co-located regression test.
 *
 * @remarks
 * `notify-jo.yml` must be driven by `workflow_run` of the {@link NOTIFY_JO_TRIGGER_WORKFLOW}
 * workflow. A `pull_request: closed` or `push: main` trigger is suppressed by
 * GitHub's recursion guard when the merge is performed with `GITHUB_TOKEN`
 * (the foundation's `gh pr merge --auto`), which is why notify-jo previously never
 * fired after an auto-merge (Issue #15).
 */
export const NOTIFY_JO_TRIGGER_WORKFLOW = 'PR Gates' as const
