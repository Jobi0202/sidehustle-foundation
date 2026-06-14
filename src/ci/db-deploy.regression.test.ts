import { existsSync, readFileSync } from 'node:fs'
import { resolve } from 'node:path'

import { describe, expect, it } from 'vitest'

// regression: issue-27: the db-deploy template must apply committed migrations to Production
// 0-touch on merge to main — push:main, path-filtered to migrations, `supabase db push`,
// and NO per-deploy migration-repair (repair is a one-time bootstrap op only).
describe('regression: issue-27: db-deploy 0-touch migration deploy', () => {
  const root = process.cwd()
  const workflow = readFileSync(
    resolve(root, '.github/workflows/db-deploy.yml'),
    'utf8',
  )

  it('triggers on push to main', () => {
    expect(workflow).toMatch(/on:\s/)
    expect(workflow).toMatch(/push:/)
    expect(workflow).toMatch(/branches:\s*\[main\]/)
  })

  it('is path-filtered to supabase/migrations/** (no-op when nothing changed)', () => {
    expect(workflow).toMatch(/supabase\/migrations\/\*\*/)
  })

  it('applies migrations via supabase db push', () => {
    expect(workflow).toMatch(/supabase db push/)
  })

  it('serialises deploys via a concurrency group (committed order preserved)', () => {
    expect(workflow).toMatch(/^concurrency:/m)
  })

  it('contains NO migration-repair (repair is bootstrap-only, never per-deploy)', () => {
    expect(workflow).not.toMatch(/migration repair/)
  })

  it('ships the one-time bootstrap scripts', () => {
    expect(existsSync(resolve(root, 'scripts/bootstrap-supabase.sh'))).toBe(true)
    expect(existsSync(resolve(root, 'scripts/bootstrap-vercel.sh'))).toBe(true)
  })

  it('keeps migration-repair in the supabase bootstrap script only', () => {
    const bootstrap = readFileSync(
      resolve(root, 'scripts/bootstrap-supabase.sh'),
      'utf8',
    )
    expect(bootstrap).toMatch(/migration repair/)
  })
})
