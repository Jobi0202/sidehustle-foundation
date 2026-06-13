import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

import { describe, expect, it } from 'vitest'

// regression: issue-19: Gate 2 must enforce the VERDICT *content*, not just the CLI
// exit code — a reviewer that emits `VERDICT: FAIL` while exiting 0 must still fail the
// gate. This test fails against the old exit-code-only enforce and passes against the fix.
describe('regression: issue-19: Gate 2 verdict-content enforcement', () => {
  const workflow = readFileSync(
    resolve(process.cwd(), '.github/workflows/pr-gates.yml'),
    'utf8',
  )

  it('parses the VERDICT value in the Gate 2 enforce step', () => {
    expect(workflow).toMatch(/Enforce Gate 2 verdict/)
    expect(workflow).toMatch(/\^VERDICT:\[\[:space:\]\]\*\(PASS\|FAIL\|PARTIAL\)/)
  })

  it('passes Gate 2 only on VERDICT: PASS', () => {
    expect(workflow).toMatch(/only VERDICT: PASS passes/)
  })
})
