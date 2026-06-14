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

  // Decision B: escalate by PRESENCE, never absence — any DELETE is tier-3 (even scoped),
  // because a `WHERE` token can be faked by a string literal. Unpokeable + convergent.
  it('any DELETE is tier-3, even a scoped DELETE..WHERE', () => {
    expect(classify({ 'migrations/005.sql': 'DELETE FROM s WHERE id=1;' })).toBe('tier-3')
  })

  it('a WHERE faked in a string literal cannot dodge tier-3', () => {
    expect(classify({ 'migrations/005b.sql': "DELETE FROM users RETURNING 'where';" })).toBe('tier-3')
  })

  // Decision B: any ADD COLUMN NOT NULL is tier-2 by presence — we do not check for a
  // DEFAULT (a `DEFAULT` token can be faked by a string literal / comment).
  it('ADD COLUMN NOT NULL is tier-2 regardless of DEFAULT', () => {
    expect(classify({ 'migrations/007.sql': 'ALTER TABLE u ADD COLUMN b int NOT NULL DEFAULT 0;' })).toBe('tier-2')
  })

  it('a nullable ADD COLUMN stays safe-additive -> tier-1', () => {
    expect(classify({ 'migrations/007b.sql': 'ALTER TABLE u ADD COLUMN b int;' })).toBe('tier-1')
  })

  it('TRUNCATE -> tier-3', () => {
    expect(classify({ 'migrations/008.sql': 'TRUNCATE TABLE logs;' })).toBe('tier-3')
  })

  // Payments money-movement detection is conservative + keyword-free: ANY payments
  // implementation file is tier-3, so no Stripe API needs enumerating to be caught.
  it.each([
    ['src/payments/charge.ts', 'stripe.charge(a)'],
    ['src/payments/checkout.ts', 'stripe.checkout.sessions.create()'],
    ['src/payments/subscription.ts', 'stripe.subscriptions.create()'],
    ['src/payments/invoice.ts', 'stripe.invoices.create()'],
    ['src/payments/types.ts', 'export type Money = number'],
  ])('payments implementation file %s -> tier-3', (path, content) => {
    expect(classify({ [path]: content })).toBe('tier-3')
  })

  it('non-implementation payments file (docs) -> tier-2 (path only)', () => {
    expect(classify({ 'src/payments/README.md': '# Payments' })).toBe('tier-2')
  })

  it('payments test file -> tier-2 (path, not implementation)', () => {
    expect(classify({ 'src/payments/charge.test.ts': 'test("x", () => {})' })).toBe('tier-2')
  })

  it('commented-out DROP (line comment) is ignored -> tier-1', () => {
    expect(classify({ 'migrations/009.sql': '-- DROP TABLE u;\nALTER TABLE u ADD COLUMN x text;' })).toBe('tier-1')
  })

  it('a WHERE hidden in a block comment cannot mask an unsafe DELETE -> tier-3', () => {
    expect(classify({ 'migrations/010.sql': 'DELETE FROM users /* WHERE id = 1 */;' })).toBe('tier-3')
  })

  it('a DEFAULT hidden in a block comment cannot mask a NOT NULL add -> tier-2', () => {
    expect(classify({ 'migrations/011.sql': 'ALTER TABLE u ADD COLUMN x int NOT NULL /* DEFAULT 0 */;' })).toBe('tier-2')
  })

  it('a benign block comment does not change the tier -> tier-1', () => {
    expect(classify({ 'migrations/012.sql': '/* add nickname */\nALTER TABLE u ADD COLUMN nick text;' })).toBe('tier-1')
  })

  it('docs only -> tier-1', () => {
    expect(classify({ 'README.md': '# hi' })).toBe('tier-1')
  })

  it('a deleted/absent migration file fails safe -> tier-2', () => {
    // The path matches migrations/*.sql but no file exists on disk (deleted/renamed away),
    // so its safety cannot be inspected — it must not silently become tier-1.
    const out = execFileSync('bash', [SCRIPT], { input: 'migrations/deleted.sql' }).toString().trim()
    expect(out).toBe('tier-2')
  })

  // Fail-safe allow-list: any non-additive or unrecognised statement is at least tier-2,
  // so an unsafe SQL form can never slip to tier-1 — no need to enumerate every form.
  it.each([
    ['CREATE UNIQUE INDEX', 'CREATE UNIQUE INDEX idx ON u(email);'],
    ['unnamed ADD UNIQUE', 'ALTER TABLE u ADD UNIQUE (email);'],
    ['ADD CONSTRAINT UNIQUE', 'ALTER TABLE u ADD CONSTRAINT uq UNIQUE (email);'],
    ['ALTER COLUMN TYPE', 'ALTER TABLE u ALTER COLUMN x TYPE bigint;'],
    ['RENAME COLUMN', 'ALTER TABLE u RENAME COLUMN a TO b;'],
    ['a future/unknown DDL form', 'CLUSTER u USING idx;'],
  ])('non-additive migration (%s) is at least tier-2', (_name, sql) => {
    expect(classify({ 'migrations/x.sql': sql })).toBe('tier-2')
  })
})
