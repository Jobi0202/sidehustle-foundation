import { execFileSync } from 'node:child_process'
import { mkdtempSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import path from 'node:path'

import { afterEach, beforeEach, describe, expect, it } from 'vitest'

/**
 * Integration test for scripts/check-author.mjs — the pre-push canonical-identity
 * guard. Builds a throwaway git repo, commits under various authors, and drives
 * the guard with a real pre-push stdin payload, asserting exit codes + message.
 */

const SCRIPT = path.resolve(__dirname, 'check-author.mjs')
const CANONICAL_EMAIL = 'tomorrow.tech.lab@gmail.com'
const CANONICAL_NAME = 'Jobi0202'
const WRONG_EMAIL = 'johannes.rentsch.jr@gmail.com'
const ZERO_SHA = '0'.repeat(40)

let repo: string

function git(args: string[], email = CANONICAL_EMAIL, name = CANONICAL_NAME): string {
  return execFileSync('git', args, {
    cwd: repo,
    encoding: 'utf8',
    env: {
      ...process.env,
      GIT_AUTHOR_NAME: name,
      GIT_AUTHOR_EMAIL: email,
      GIT_COMMITTER_NAME: name,
      GIT_COMMITTER_EMAIL: email,
    },
  }).trim()
}

function commit(message: string, email: string): string {
  git(['commit', '--allow-empty', '-m', message], email)
  return git(['rev-parse', 'HEAD'])
}

/** Run the guard with the given pre-push stdin payload. Returns exit code + stderr. */
function runGuard(payload: string): { code: number; stderr: string } {
  try {
    execFileSync('node', [SCRIPT], { cwd: repo, input: payload, encoding: 'utf8' })
    return { code: 0, stderr: '' }
  } catch (err) {
    const e = err as { status?: number; stderr?: string }
    return { code: e.status ?? 1, stderr: e.stderr ?? '' }
  }
}

beforeEach(() => {
  repo = mkdtempSync(path.join(tmpdir(), 'check-author-'))
  git(['init', '-b', 'feature'])
  git(['config', 'commit.gpgsign', 'false'])
})

afterEach(() => {
  rmSync(repo, { recursive: true, force: true })
})

describe('check-author guard', () => {
  it('passes when a new-branch push contains only canonical-author commits', () => {
    const sha = commit('feat: canonical', CANONICAL_EMAIL)
    const { code } = runGuard(`refs/heads/feature ${sha} refs/heads/feature ${ZERO_SHA}\n`)
    expect(code).toBe(0)
  })

  it('blocks a push that introduces a non-canonical author and shows the fix', () => {
    const sha = commit('feat: wrong author', WRONG_EMAIL)
    const { code, stderr } = runGuard(`refs/heads/feature ${sha} refs/heads/feature ${ZERO_SHA}\n`)
    expect(code).toBe(1)
    expect(stderr).toContain(WRONG_EMAIL)
    expect(stderr).toContain(`git config user.email "${CANONICAL_EMAIL}"`)
    expect(stderr).toContain(`git config user.name  "${CANONICAL_NAME}"`)
  })

  it('judges only the commits in the pushed range, not pre-existing history', () => {
    const base = commit('feat: base canonical', CANONICAL_EMAIL)
    const head = commit('feat: new wrong', WRONG_EMAIL)
    const { code, stderr } = runGuard(`refs/heads/feature ${head} refs/heads/feature ${base}\n`)
    expect(code).toBe(1)
    expect(stderr).toContain(WRONG_EMAIL)
  })

  it('ignores branch deletions (local sha all zeros)', () => {
    commit('feat: anything', WRONG_EMAIL)
    const { code } = runGuard(`(delete) ${ZERO_SHA} refs/heads/feature ${ZERO_SHA}\n`)
    expect(code).toBe(0)
  })

  it('falls back to HEAD when stdin is empty and blocks a wrong author', () => {
    commit('feat: wrong head', WRONG_EMAIL)
    const { code, stderr } = runGuard('')
    expect(code).toBe(1)
    expect(stderr).toContain(WRONG_EMAIL)
  })
})
