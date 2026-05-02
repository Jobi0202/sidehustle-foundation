# Handoff Protocol v2

Exact 3-step trigger sequence. Master Agent does NOT touch GitHub. Builder owns all GitHub operations via `gh` CLI.

## Hop 1 -> Hop 2: PM ends spec session

PM ends every side-hustle spec session with this sentence (verbatim):

> Specs sind fertig in `Product Manager/Ideas/<slug>/`.
> 
> **Naechster Schritt fuer Jo:** Oeffne Master Agent (Cowork), neue Session, paste:
> 
> ```
> Master Agent: bootstrap side-hustle <slug>
> Specs liegen in: Product Manager/Ideas/<slug>/
> ```

PM does NOT write any setup commands. PM does NOT mention `gh`, Code-Tab, or Bash. PM does NOT explain the Pipeline.

## Hop 2: Master Agent receives bootstrap trigger

Master Agent's ONLY job: assemble the Builder-Prompt and return it. NO API calls.

1. Read `templates/builder-bootstrap-prompt.md` from `sidehustle-foundation`.
2. Substitute `{{SLUG}}` and `{{SPECS_PATH}}` with values from the trigger.
3. Return the filled prompt to Jo with one line: "Paste this in Claude Code Desktop."

That is the entire Hop 2.

## Hop 3: Build starts in Claude Code Desktop

Jo opens Claude Code Desktop, Code tab. New session in his local dev folder (e.g. `C:\Users\Rentsch\dev\`). Pastes the Builder-Prompt.

Builder runs `gh` CLI sequence:
1. `gh repo create` from template
2. `gh repo clone` locally
3. `cp` specs into `specs/`
4. `gh secret set --env-file` from `~/.sidehustle-secrets.env`
5. `git push`
6. `gh api` for branch protection
7. `gh api` for auto-merge enable
8. Read CLAUDE.md + rules + specs, begin Issue #1

## Failure Modes

| Failure | Symptom | Recovery |
|---|---|---|
| `.sidehustle-secrets.env` missing | gh secret set fails | Builder tells Jo to create from `.env.template` in repo, restart |
| `gh` not authenticated | gh repo create fails | Builder tells Jo to run `gh auth login`, restart |
| Claude Code App not installed | Gate 2 fails 401 | Builder tells Jo to install at github.com/apps/claude one-time |
| Vercel App not installed | No preview deploys | Builder tells Jo to connect once, then auto for future repos |
