import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

import { describe, expect, it } from 'vitest'

const read = (rel: string) => readFileSync(resolve(process.cwd(), rel), 'utf8')

// Encodes the operator-autonomy rule + Konflikt-Vorrang precedence and its wiring into the
// canonical read-lists, so a future edit can't silently drop it (mirrors escalation-rules.test.ts).
describe('operator autonomy + Konflikt-Vorrang', () => {
  const rule = read('.claude/rules/operator-autonomy.md')

  it('ships the operator-autonomy rule with the Konflikt-Vorrang section', () => {
    expect(rule).toMatch(/# Operator Autonomy Rule/)
    expect(rule).toMatch(/## Konflikt-Vorrang/)
  })

  it('resolves clear technical handoff-vs-rules conflicts in favour of the rules, no escalation', () => {
    expect(rule).toMatch(/TECHNIK.*the rules \+ spec WIN/s)
    expect(rule).toMatch(/No escalation, no\s+question/i)
  })

  it('escalates only product / scope / risk / cost conflicts to needs-jo', () => {
    expect(rule).toMatch(/PRODUKT.*escalate/s)
    expect(rule).toMatch(/needs-jo/)
  })

  it('does not reroute a clear tech conflict to needs-architect (that is the loop-cap)', () => {
    expect(rule).toMatch(/not a\s+`needs-architect` case/i)
  })

  it('is wired into the CLAUDE.md read-lists (session start + Rules Reference)', () => {
    const claude = read('CLAUDE.md')
    const occurrences = claude.match(/operator-autonomy\.md/g) ?? []
    expect(occurrences.length).toBeGreaterThanOrEqual(2)
  })

  it('is wired into the reviewer and bootstrap read-lists', () => {
    expect(read('.claude/agents/reviewer.md')).toMatch(/operator-autonomy\.md/)
    expect(read('templates/builder-bootstrap-prompt.md')).toMatch(/operator-autonomy\.md/)
  })
})
