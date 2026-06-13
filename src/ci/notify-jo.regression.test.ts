import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

import { describe, expect, it } from 'vitest'

import { NOTIFY_JO_TRIGGER_WORKFLOW } from './notify-jo-contract'

// regression: issue-15: notify-jo must fire after a GITHUB_TOKEN auto-merge.
// A `pull_request: closed` (or `push: main`) trigger is suppressed by GitHub's
// recursion guard for merges performed with GITHUB_TOKEN, so notify-jo must be
// driven by `workflow_run` on "PR Gates" completion. This test fails against the
// old workflow definition and passes against the fix.
describe('regression: issue-15: notify-jo auto-merge trigger', () => {
  const workflow = readFileSync(
    resolve(process.cwd(), '.github/workflows/notify-jo.yml'),
    'utf8',
  )

  it('is triggered by workflow_run of the PR Gates workflow', () => {
    expect(workflow).toMatch(/workflow_run:/)
    expect(workflow).toContain(`"${NOTIFY_JO_TRIGGER_WORKFLOW}"`)
  })

  it('does not use the suppressed pull_request: closed trigger', () => {
    expect(workflow).not.toMatch(/pull_request:\s*\n\s*types:\s*\[\s*closed\s*\]/)
  })

  it('only notifies once the PR has actually merged', () => {
    expect(workflow).toMatch(/steps\.pr\.outputs\.merged == 'true'/)
  })
})
