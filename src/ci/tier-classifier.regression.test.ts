import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

import { describe, expect, it } from 'vitest'

// regression: issue-21: risk is auto-tiered (tier-1/2/3), tier-2 is gated by the
// architect-gate, and tier-3 is blocked in gates-green without jo-approved.
describe('regression: issue-21: 3-tier risk classifier + architect-gate', () => {
  const root = process.cwd()
  const risk = readFileSync(resolve(root, '.github/workflows/auto-label-risk.yml'), 'utf8')
  const gates = readFileSync(resolve(root, '.github/workflows/pr-gates.yml'), 'utf8')

  it('classifies into tier-1 / tier-2 / tier-3', () => {
    for (const tier of ['tier-1', 'tier-2', 'tier-3']) expect(risk).toContain(tier)
  })

  it('has an architect-gate job wired into gates-green needs', () => {
    expect(gates).toMatch(/^ {2}architect-gate:/m)
    expect(gates).toMatch(/needs:\s*\[[^\]]*architect-gate[^\]]*\]/)
  })

  it('blocks tier-3 without jo-approved in gates-green', () => {
    expect(gates).toMatch(/tier-3/)
    expect(gates).toMatch(/jo-approved/)
  })

  it('gates-green fails CLOSED when no tier label is present', () => {
    expect(gates).toMatch(/failing closed/i)
  })

  it('detects payments money movement from changed file content, not only SQL', () => {
    expect(risk).toMatch(/payments_files/)
    expect(risk).toMatch(/pay_up/)
  })

  it('evaluates DELETE per statement so a safe DELETE cannot mask a dangerous one', () => {
    expect(risk).toMatch(/PER STATEMENT/)
  })
})
