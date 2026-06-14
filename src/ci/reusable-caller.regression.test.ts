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
})
