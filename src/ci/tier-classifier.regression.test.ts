import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

import { describe, expect, it } from 'vitest'

// regression: issue-21: risk is auto-tiered (tier-1/2/3), tier-2 is gated by the
// architect-gate, and tier-3 is blocked in gates-green without jo-approved.
describe('regression: issue-21: 3-tier risk classifier + architect-gate', () => {
  const root = process.cwd()
  const risk = readFileSync(resolve(root, '.github/workflows/auto-label-risk.yml'), 'utf8')
  const gates = readFileSync(resolve(root, '.github/workflows/pr-gates.yml'), 'utf8')

  it('classifies via the shared, tested classify-tier.sh (behaviour covered in tier-classifier.test.ts)', () => {
    expect(risk).toMatch(/classify-tier\.sh/)
    for (const tier of ['tier-1', 'tier-2', 'tier-3']) expect(risk).toContain(tier)
  })

  it('has an architect-gate job wired into gates-green needs', () => {
    expect(gates).toMatch(/^ {2}architect-gate:/m)
    expect(gates).toMatch(/needs:\s*\[[^\]]*architect-gate[^\]]*\]/)
  })

  it('blocks tier-3 without jo-approved and fails CLOSED on a missing label', () => {
    expect(gates).toMatch(/tier-3/)
    expect(gates).toMatch(/jo-approved/)
    expect(gates).toMatch(/failing closed/i)
  })

  it('re-runs the gates on labeled/unlabeled so adding jo-approved clears the tier-3 block', () => {
    expect(gates).toMatch(/types:\s*\[[^\]]*\blabeled\b[^\]]*\bunlabeled\b[^\]]*\]/)
  })
})
