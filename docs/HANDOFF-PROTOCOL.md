# Handoff Protocol

Exact 3-step trigger sequence when a side-hustle moves from spec to build.

## Hop 1 -> Hop 2: PM ends spec session

PM ends every side-hustle spec session with this sentence (verbatim):

> Specs sind fertig in `Product Manager/Ideas/<slug>/`.
> 
> **Nächster Schritt für Jo:** Öffne Master Agent (Cowork), neue Session, paste:
> 
> ```
> Master Agent: bootstrap side-hustle <slug>
> Specs liegen in: Product Manager/Ideas/<slug>/
> ```

PM does NOT write setup commands, does NOT mention gh, Code-Tab, or Bash. Just the trigger sentence.

## Hop 2: Master Agent receives bootstrap trigger

1. Verify specs exist (vision.md, prd-light.md, architecture.md, issues.md as minimum)
2. Create GitHub repo <slug> private from Jobi0202/sidehustle-foundation template via Composio API
3. Verify template inheritance (.claude/, .github/workflows/pr-gates.yml, CLAUDE.md present)
4. Copy 4 spec files into <slug>/specs/ via single atomic commit
5. Set branch protection on main (required: Gates Green, strict, enforce_admins=false)
6. Enable repo auto-merge + delete-branch-on-merge + squash-only
7. Return Builder-Prompt + Setup-Checklist to Jo

Master Agent does NOT write code, NOT design specs, NOT touch Builder runtime.

## Hop 3: Build starts in Claude Code Desktop

1. Code tab -> GitHub-Connector -> select <slug> repo
2. Paste Builder-Prompt from Hop 2
3. Builder reads CLAUDE.md + /specs/* + .claude/rules/* and begins Issue #1
