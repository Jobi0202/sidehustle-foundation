import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

import { describe, expect, it } from 'vitest'

// regression: issue-25: Gate 3 (codex-action) must pin BOTH the model and the reasoning
// effort so per-review cost can't silently drift back to the action's unpinned default.
describe('regression: issue-25: Gate 3 codex model + effort pinned', () => {
  const workflow = readFileSync(
    resolve(process.cwd(), '.github/workflows/pr-gates.yml'),
    'utf8',
  )

  it('pins the codex model to gpt-5.3-codex (latest codex-specialised model)', () => {
    expect(workflow).toMatch(/^\s*model:\s*gpt-5\.3-codex\s*$/m)
  })

  it('pins the reasoning effort to medium', () => {
    expect(workflow).toMatch(/^\s*effort:\s*medium\s*$/m)
  })
})
