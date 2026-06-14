import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

import { describe, expect, it } from 'vitest'

// regression: issue-29: the foundation's pr-gates.yml is a THIN CALLER of the shared
// reusable pipeline in the public repo Jobi0202/sidehustle-ci. The deep gate contract
// (Gate 2 verdict enforcement, Gate 3 model pin, architect-gate, tier-3 schranke,
// auto-merge) now lives ONCE in that reusable workflow; here we assert correct delegation
// so a central change propagates and the local caller can't silently drift out of it.
describe('regression: issue-29: pr-gates is a thin caller of sidehustle-ci', () => {
  const workflow = readFileSync(
    resolve(process.cwd(), '.github/workflows/pr-gates.yml'),
    'utf8',
  )

  it('keeps the workflow name "PR Gates" (notify-jo workflow_run trigger depends on it)', () => {
    expect(workflow).toMatch(/^name:\s*PR Gates\s*$/m)
  })

  it('delegates to the public reusable workflow pinned to @main', () => {
    expect(workflow).toMatch(
      /uses:\s*Jobi0202\/sidehustle-ci\/\.github\/workflows\/pr-gates-reusable\.yml@main/,
    )
  })

  it('passes repo secrets through via secrets: inherit', () => {
    expect(workflow).toMatch(/secrets:\s*inherit/)
  })

  // Reusable job checks are prefixed "gates / ...", so the caller must re-export a
  // top-level "Gates Green" job to satisfy main's required-status-check of that name
  // without any branch-protection edit.
  it('exposes a caller-level "Gates Green" job that needs the reusable', () => {
    expect(workflow).toMatch(/^ {2}gates-green:/m)
    expect(workflow).toMatch(/name:\s*Gates Green/)
    expect(workflow).toMatch(/needs:\s*\[gates\]/)
  })

  it('triggers on pull_request incl. labeled/unlabeled (so jo-approved re-runs the gates)', () => {
    expect(workflow).toMatch(/pull_request:/)
    expect(workflow).toMatch(/types:\s*\[[^\]]*\blabeled\b[^\]]*\bunlabeled\b[^\]]*\]/)
  })

  it('cancels stale runs via a per-PR concurrency group', () => {
    expect(workflow).toMatch(
      /concurrency:[\s\S]*group:\s*pr-gates-\$\{\{\s*github\.event\.pull_request\.number\s*\}\}/,
    )
    expect(workflow).toMatch(/cancel-in-progress:\s*true/)
  })

  // A called workflow's permissions are capped by the caller's grant (repo default is
  // read-only), so the caller must grant the union the reusable's jobs need — else the run
  // fails at startup. Pin it so this can't regress.
  it('grants the permissions the reusable jobs require (else startup failure)', () => {
    expect(workflow).toMatch(/^permissions:/m)
    expect(workflow).toMatch(/contents:\s*write/)
    expect(workflow).toMatch(/pull-requests:\s*write/)
    expect(workflow).toMatch(/issues:\s*write/)
    expect(workflow).toMatch(/id-token:\s*write/)
  })
})
