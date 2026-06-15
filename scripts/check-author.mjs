#!/usr/bin/env node
/**
 * check-author.mjs — pre-push canonical-identity guard.
 *
 * Rejects any commit being pushed whose author email is not the fleet canonical
 * identity. Reads the standard `git push` pre-push payload from stdin
 * (`<local ref> <local sha> <remote ref> <remote sha>` lines). For a new branch
 * it judges only commits not already present on a remote, so pre-existing
 * upstream history is never re-litigated — only NEW commits are checked.
 *
 * Canonical identity (owner of every repo + the Vercel team):
 *   Jobi0202 <tomorrow.tech.lab@gmail.com>
 * johannes.rentsch.jr@gmail.com (the dead Giro22 account) must never author commits.
 */
import { execFileSync } from 'node:child_process'
import { readFileSync } from 'node:fs'

const CANONICAL_EMAIL = 'tomorrow.tech.lab@gmail.com'
const CANONICAL_NAME = 'Jobi0202'

const isZeroSha = (sha) => /^0+$/.test(sha)
const git = (args) => execFileSync('git', args, { encoding: 'utf8' }).trim()

/** "<sha> <email>" lines for the commits introduced by one pre-push ref update. */
function entriesForUpdate(localSha, remoteSha) {
  const range = isZeroSha(remoteSha)
    ? [localSha, '--not', '--remotes']
    : [`${remoteSha}..${localSha}`]
  const out = git(['log', '--format=%H %ae', ...range])
  return out ? out.split('\n') : []
}

function readPayload() {
  try {
    return readFileSync(0, 'utf8').trim()
  } catch {
    return ''
  }
}

function collectOffending() {
  const offending = []
  const payload = readPayload()

  if (!payload) {
    // No payload (manual run / empty stdin): judge HEAD.
    try {
      const [sha, email] = git(['log', '-1', '--format=%H %ae']).split(' ')
      if (email && email !== CANONICAL_EMAIL) offending.push({ sha, email })
    } catch {
      /* repo has no commits yet — nothing to check */
    }
    return offending
  }

  for (const line of payload.split('\n')) {
    const [, localSha, , remoteSha] = line.trim().split(/\s+/)
    if (!localSha || isZeroSha(localSha)) continue // branch deletion / malformed
    for (const entry of entriesForUpdate(localSha, remoteSha ?? '0')) {
      const [sha, email] = entry.split(' ')
      if (email && email !== CANONICAL_EMAIL) offending.push({ sha, email })
    }
  }
  return offending
}

const offending = collectOffending()
if (offending.length > 0) {
  const list = offending.map((o) => `  ${o.sha.slice(0, 9)}  ${o.email}`).join('\n')
  process.stderr.write(
    `ERROR: push blocked — non-canonical commit author email(s):\n${list}\n\n` +
      `The fleet canonical identity is:  ${CANONICAL_NAME} <${CANONICAL_EMAIL}>\n` +
      `(owner of every repo + the Vercel team).\n\n` +
      `Fix your local identity, then re-commit:\n` +
      `  git config user.email "${CANONICAL_EMAIL}"\n` +
      `  git config user.name  "${CANONICAL_NAME}"\n\n` +
      `To restamp commit(s) already made under the wrong author:\n` +
      `  git commit --amend --reset-author --no-edit        # most recent commit\n` +
      `  git rebase -r <base> --exec "git commit --amend --reset-author --no-edit"\n\n` +
      `Bypassing this hook (git push --no-verify) is a CLAUDE.md Hard-Stop violation.\n`,
  )
  process.exit(1)
}
