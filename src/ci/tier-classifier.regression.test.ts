import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

import { describe, expect, it } from 'vitest'

// regression: issue-21 (+ issue-29 relocation): risk is auto-tiered (tier-1/2/3) by the
// per-repo auto-label-risk.yml via the shared classify-tier.sh. The architect-gate +
// tier-3-schranke ENFORCEMENT moved into the central reusable workflow (Jobi0202/
// sidehustle-ci) with Schritt 2, so it is asserted there (and via reusable-caller.regression
// for delegation), not against the local thin-caller pr-gates.yml. What stays local — the
// risk classifier wiring and the labeled/unlabeled re-trigger — is asserted here.
describe('regression: issue-21: 3-tier risk classifier (local) + delegation', () => {
  const root = process.cwd()
  const risk = readFileSync(resolve(root, '.github/workflows/auto-label-risk.yml'), 'utf8')
  const gates = readFileSync(resolve(root, '.github/workflows/pr-gates.yml'), 'utf8')

  it('classifies via the shared, tested classify-tier.sh (behaviour covered in tier-classifier.test.ts)', () => {
    expect(risk).toMatch(/classify-tier\.sh/)
    for (const tier of ['tier-1', 'tier-2', 'tier-3']) expect(risk).toContain(tier)
  })

  it('delegates the gate pipeline (incl. architect-gate + tier-3 schranke) to the central reusable workflow', () => {
    expect(gates).toMatch(
      /uses:\s*Jobi0202\/sidehustle-ci\/\.github\/workflows\/pr-gates-reusable\.yml@main/,
    )
  })

  it('re-runs the gates on labeled/unlabeled so adding jo-approved clears the tier-3 block', () => {
    expect(gates).toMatch(/types:\s*\[[^\]]*\blabeled\b[^\]]*\bunlabeled\b[^\]]*\]/)
  })
})
