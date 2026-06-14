import { execFileSync } from 'node:child_process'
import { mkdirSync, mkdtempSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join } from 'node:path'

import { describe, expect, it } from 'vitest'

const SCRIPT = join(process.cwd(), 'scripts/classify-tier.sh')

// Run scripts/classify-tier.sh against a set of fixture files (created on disk so the
// script can read their contents) and return the printed tier.
function classify(files: Record<string, string>): string {
  const dir = mkdtempSync(join(tmpdir(), 'tier-'))
  const paths: string[] = []
  for (const [rel, content] of Object.entries(files)) {
    const abs = join(dir, rel)
    mkdirSync(dirname(abs), { recursive: true })
    writeFileSync(abs, content)
    paths.push(abs)
  }
  return execFileSync('bash', [SCRIPT], { input: paths.join('\n') }).toString().trim()
}

describe('classify-tier.sh', () => {
  it('additive ADD COLUMN -> tier-1', () => {
    expect(classify({ 'migrations/001.sql': 'ALTER TABLE u ADD COLUMN nick text;' })).toBe('tier-1')
  })

  it('DROP COLUMN -> tier-2', () => {
    expect(classify({ 'migrations/002.sql': 'ALTER TABLE u DROP COLUMN nick;' })).toBe('tier-2')
  })

  it('DROP TABLE -> tier-3', () => {
    expect(classify({ 'migrations/003.sql': 'DROP TABLE u;' })).toBe('tier-3')
  })

  it('a safe DELETE..WHERE cannot mask an unsafe DELETE -> tier-3', () => {
    expect(classify({ 'migrations/004.sql': 'DELETE FROM users; DELETE FROM s WHERE id=1;' })).toBe('tier-3')
  })

  it('every DELETE has a WHERE -> tier-2', () => {
    expect(classify({ 'migrations/005.sql': 'DELETE FROM s WHERE id=1;' })).toBe('tier-2')
  })

  it('a safe ADD COLUMN..DEFAULT cannot mask an unsafe NOT NULL add -> tier-2', () => {
    expect(
      classify({
        'migrations/006.sql':
          'ALTER TABLE u ADD COLUMN a int NOT NULL; ALTER TABLE u ADD COLUMN b int NOT NULL DEFAULT 0;',
      }),
    ).toBe('tier-2')
  })

  it('ADD COLUMN NOT NULL DEFAULT -> tier-1', () => {
    expect(classify({ 'migrations/007.sql': 'ALTER TABLE u ADD COLUMN b int NOT NULL DEFAULT 0;' })).toBe('tier-1')
  })

  it('TRUNCATE -> tier-3', () => {
    expect(classify({ 'migrations/008.sql': 'TRUNCATE TABLE logs;' })).toBe('tier-3')
  })

  it('payments code with money movement -> tier-3', () => {
    expect(classify({ 'src/payments/charge.ts': 'export const charge = (a: number) => stripe.charge(a)' })).toBe('tier-3')
  })

  it('payments code without money movement -> tier-2', () => {
    expect(classify({ 'src/payments/types.ts': 'export type Money = number' })).toBe('tier-2')
  })

  it('commented-out DROP is ignored -> tier-1', () => {
    expect(classify({ 'migrations/009.sql': '-- DROP TABLE u;\nALTER TABLE u ADD COLUMN x text;' })).toBe('tier-1')
  })

  it('docs only -> tier-1', () => {
    expect(classify({ 'README.md': '# hi' })).toBe('tier-1')
  })
})
