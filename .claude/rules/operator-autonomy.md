# Operator Autonomy Rule

> Binding rule. Read at session start alongside the other `.claude/rules/*.md` files.

## Why this rule exists

Builder runs have repeatedly stalled with low-value confirmation questions ("where are the specs?", "which branch name?", "should I start with Issue #N?", "approve before I open the PR?") and have wrongly escalated *technical* conflicts that the rules already settle. Every such pause costs Jo time and breaks the Continuous-Operator promise of this repo.

This rule is the binding contract: **if the answer is derivable from CLAUDE.md, the Issue body, the handoff prompt, the rules, or convention — execute, don't ask.**

## The Decision Tree (apply before every "should I ask Jo?" reflex)

1. Is the answer in CLAUDE.md, this rule, another `.claude/rules/*.md`, the Issue body, or a referenced handoff prompt? → **Execute.**
2. Is the answer derivable from established conventions in this repo (branch naming, PR template, file scope)? → **Execute.**
3. Does the handoff/prompt **contradict** the enforced rules or specs? → Apply **Konflikt-Vorrang** (below): a clear *technical* conflict you resolve yourself; only a *product/risk* conflict escalates.
4. Is this a Hard Stop from CLAUDE.md (delete from main, push to main, bypass husky, disable status check, self-merge, secret commit, top-level dep, edit workflows/CLAUDE.md/rules without targeted Issue)? → **Stop, post Issue comment, label `needs-jo`, fire Pushover via existing notify-jo flow.**
5. Otherwise — and only otherwise — is this a genuine ambiguity (3 failed attempts, contradictory specs, missing secret, blocking dependency)? → **Stop, post Issue comment, label `needs-jo`, fire Pushover.**

If you find yourself drafting a question that maps to step 1 or 2 — delete it and execute.

## Konflikt-Vorrang: Handoff/Prompt vs. enforced rules & spec

When a handoff or prompt contradicts the enforced `.claude/rules/*` **or** the product `specs/`
(incl. `specs/architecture.md`), classify the conflict and route it by **kind**, not by reflex:

- **TECHNIK / Framework / Tooling / Struktur → the rules + spec WIN.**
  Follow the rules/spec, record the inconsistency in the PR body (one line: what the handoff
  asked, what you did instead, which rule/spec governs), and continue. **No escalation, no
  question.** Examples: handoff says Vite but `architecture.md` mandates Next.js; handoff says
  `npm` but the stack is pnpm-only; handoff puts logic in `components/` but the layer model
  forbids it; handoff proposes a file layout that breaks `anti-spaghetti.md` caps.
- **PRODUKT / Scope / Risiko / Kosten → escalate.**
  Stop, post an Issue comment with the **concrete** discrepancy, label `needs-jo`, let the
  notify-jo flow ping Jo. Examples: handoff adds a feature outside the Issue's acceptance
  criteria; handoff implies money movement / data-loss / user-consent (tier-3); handoff
  changes a paid-quota or billing assumption.

**Grundsatz:** clear technical conflicts the Builder resolves itself in favour of the rules;
only genuine product/risk/cost contradictions go up — and those go to **Jo**, never reframed as
a technical question.

**Boundary vs. the loop-cap routing in `review.md`:** a *clear* tech conflict is not a
`needs-architect` case. `needs-architect` is reserved for a **technical loop-cap** (3 consecutive
FAILs on a genuinely ambiguous technical question). A conflict the rules already settle has no
ambiguity — resolve it and move on.

## Specific anti-patterns (Do NOT do these)

| Anti-Pattern | Correct behavior |
|---|---|
| "Where are the specs?" | Specs SoT is `specs/` in this repo. If a handoff names an external path, read it from there. The path is given. Don't re-confirm. |
| "Which branch name should I use?" | Use the convention in CLAUDE.md or the handoff. Default: `feat/issue-<N>-<slug>` (or `fix/`, `refactor/`, `chore/`, `docs/` per Conventional-Commit kind). Don't ask. |
| "Should I start with Issue #X or #Y?" | Sequence is in the handoff. If absent: numerically ascending. Don't ask. |
| "Approve before I open the PR?" | No. PR-open is the unit of delivery. Open the PR. The three Gates + Auto-Merge are the approval mechanism. |
| "Handoff says framework/tool X, but the rules say Y — which wins?" | Konflikt-Vorrang: the rules/spec win for any technical conflict. Follow them, note it in the PR body, proceed. Don't ask. |
| "Should I commit a small unrelated improvement I noticed?" | Boy-Scout rule: in-scope edits OK, out-of-scope = new Issue. See `boy-scout.md`. Don't ask. |
| "Should I install shadcn component X?" | If the spec references it, install it. Document the install in the PR body. Don't ask. |

## Continuous Operator Loop (binding)

When Jo (or a PM session) provides a handoff prompt that lists N Issues, treat it as a binding
work order and run it end-to-end:

1. Execute any foundation/setup step listed first → PR → wait for merge.
2. Execute a spec-sync step (if specs differ) → PR → wait for merge.
3. For each Issue in the listed sequence:
   a. Create worktree + branch per convention.
   b. Implement strictly in file-scope.
   c. Run `pnpm verify` — must be green.
   d. Open PR with `closes #N`, AC checklist, verify-output in the body.
   e. Move on. Do NOT pause for Jo confirmation between Issues.
4. After the last PR is opened — and only then — post a single status comment summarizing all
   PRs opened, gates pending, and any blockers.

If a Gate fails: address blocking findings, push, continue. No status check-in for routine Gate
failures.

## What counts as a legitimate Jo-ping

These are the only ones. Use the Issue-comment + `needs-jo` label + automated Pushover path. Do
NOT direct-message via PR description.

- Hard Stop triggered (see CLAUDE.md "Hard Stops" section)
- A **product/scope/risk/cost** conflict under Konflikt-Vorrang
- 3 consecutive failing attempts on the same test or Gate (technical → see `review.md`: this
  routes to `needs-architect`, not `needs-jo`)
- Spec contradiction across `prd-light.md` / `architecture.md` / `issues.md`
- Missing secret blocking the build
- Hard dependency on a previous PR that has not merged

Anything else: execute.

## Self-check before sending any user-facing message during a build

Ask yourself: "Is this message a Hard-Stop ping, a final-status summary, or a `needs-jo`
escalation?" If none of the three — don't send it.
