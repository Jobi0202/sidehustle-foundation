import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

import { describe, expect, it } from 'vitest'

const read = (rel: string) => readFileSync(resolve(process.cwd(), rel), 'utf8')

// Encodes the escalation-routing + rule-scope policy so a future edit can't silently drop it.
describe('escalation routing + rule scope', () => {
  const review = read('.claude/rules/review.md')
  const architecture = read('.claude/rules/architecture.md')

  it('routes a technical loop-cap to needs-architect, not needs-jo', () => {
    expect(review).toMatch(/needs-architect/)
    expect(review).toMatch(/recurring bug-class|restructure rather than thrash/i)
  })

  it('reserves needs-jo for tier-3 / cost / product', () => {
    expect(review).toMatch(/`needs-jo` is reserved/i)
  })

  it('scopes the stack/SQL rules to application code, exempting CI + test fixtures', () => {
    expect(architecture).toMatch(/## Scope of these rules/)
    expect(architecture).toMatch(/test fixtures/i)
    expect(architecture).toMatch(/\.github\/workflows/)
  })
})
