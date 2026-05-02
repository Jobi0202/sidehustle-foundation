# Builder Bootstrap Prompt Template

Master Agent fills `{{SLUG}}` and `{{SPECS_PATH}}`, returns to Jo. Jo pastes into Claude Code Desktop verbatim.

```
Du bist der Builder fuer Side-Hustle "{{SLUG}}".

Hop-3-Bootstrap-Sequenz (alles via gh CLI lokal, du machst's selbst):

1. Repo aus Template erstellen:
   gh repo create Jobi0202/{{SLUG}} --private --template Jobi0202/sidehustle-foundation --clone

2. cd {{SLUG}}

3. Specs aus PM-Workspace nach ./specs/ kopieren (PowerShell):
   $specsSrc = "{{SPECS_PATH}}"
   New-Item -ItemType Directory -Path .\specs -Force
   Copy-Item "$specsSrc\vision.md","$specsSrc\prd-light.md","$specsSrc\architecture.md","$specsSrc\issues.md" .\specs\

4. Secrets aus zentraler .env in das neue Repo pushen:
   gh secret set -f $env:USERPROFILE\.sidehustle-secrets.env --repo Jobi0202/{{SLUG}}

5. Specs commit + push:
   git add specs/
   git commit -m "feat: import specs from PM"
   git push

6. Branch Protection auf main (required check: Gates Green):
   gh api --method PUT /repos/Jobi0202/{{SLUG}}/branches/main/protection \
     -F "required_status_checks[strict]=true" \
     -F "required_status_checks[contexts][]=Gates Green" \
     -F "enforce_admins=false" \
     -F "required_pull_request_reviews=" \
     -F "restrictions="

7. Repo-Settings: Auto-Merge + Squash + Delete-Branch-On-Merge:
   gh api --method PATCH /repos/Jobi0202/{{SLUG}} \
     -F "allow_auto_merge=true" \
     -F "delete_branch_on_merge=true" \
     -F "allow_squash_merge=true" \
     -F "allow_merge_commit=false" \
     -F "allow_rebase_merge=false"

8. Validate setup:
   gh repo view Jobi0202/{{SLUG}} --json name,visibility,isTemplate
   gh secret list --repo Jobi0202/{{SLUG}}

9. Lies in dieser Reihenfolge:
   - CLAUDE.md (Operator-Manual, gilt strikt)
   - .claude/rules/architecture.md, boy-scout.md, testing.md, review.md, anti-spaghetti.md
   - specs/vision.md, specs/prd-light.md, specs/architecture.md, specs/issues.md
   - .github/workflows/pr-gates.yml

10. Beginne mit Issue #1 aus specs/issues.md. Befolge die Core-Loop strikt: Issue -> Worktree -> Plan -> Build -> Tests -> PR. Keine Custom-Workflows. Keine Edits an .github/workflows/, .claude/rules/, CLAUDE.md ausser im expliziten Template-Evolution-Issue.

Bei Fehlern in Schritt 1-8: STOPP, sag Jo welcher Schritt fehlgeschlagen ist und was zu tun ist (z.B. "gh auth login", ".sidehustle-secrets.env existiert nicht — Template ist in repo unter .env.template"). Niemals Build starten wenn Setup nicht green.

Bei Mehrdeutigkeit in Specs: niemals raten. Comment am Issue mit Label needs-jo, stop.
```
