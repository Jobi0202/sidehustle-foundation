# Builder Bootstrap Prompt Template

Master Agent fills `{{SLUG}}` and `{{SPECS_PATH}}`, returns to Jo. Jo pastes into Claude Code Desktop verbatim.

```
Du bist der Builder fuer Side-Hustle "{{SLUG}}".

Hop-3-Bootstrap-Sequenz (alles via gh CLI lokal, du machst's selbst):

1. Pre-Check: gh auth + Template-Status:
   gh auth status
   gh repo view Jobi0202/sidehustle-foundation --json isTemplate
   # Wenn isTemplate=false: gh api --method PATCH /repos/Jobi0202/sidehustle-foundation -F is_template=true
   # ~/.sidehustle-secrets.env muss existieren — sonst stoppen, Jo soll das Template aus dem Repo lokal befuellen.

1.5. App-Install Pre-Check (sonst failen Gates spaeter):
   gh api /user/installations --jq '.installations[].app_slug'
   # Erwarte mindestens "claude" und "vercel" in der Liste.
   # Wenn nicht: STOPP, sag Jo:
   #   - Claude Code App: https://github.com/apps/claude installieren
   #   - Vercel: https://github.com/apps/vercel installieren
   # Erst nach Bestaetigung weiter.

2. Repo aus Template erstellen + clonen:
   gh repo create Jobi0202/{{SLUG}} --private --template Jobi0202/sidehustle-foundation --clone

3. cd {{SLUG}}

4. Specs aus PM-Workspace nach ./specs/ kopieren (PowerShell):
   $specsSrc = "{{SPECS_PATH}}"
   New-Item -ItemType Directory -Path .\specs -Force
   Copy-Item "$specsSrc\vision.md","$specsSrc\prd-light.md","$specsSrc\architecture.md","$specsSrc\issues.md" .\specs\

5. Secrets aus zentraler .env in das neue Repo pushen:
   gh secret set -f $env:USERPROFILE\.sidehustle-secrets.env --repo Jobi0202/{{SLUG}}

6. Branch Protection: SKIP — paused bis Firmengruendung (siehe Master-Agent Memory). Free-Plan-Tuersteher ist der lokale Husky pre-push Hook, der mit dem Template geklont wurde. Verifizieren nach `pnpm install` in Issue #1:
   Test-Path .husky/pre-push    # muss True sein
   Get-Content .husky/pre-push   # muss main-block-Logik enthalten

7. Repo-Settings: Auto-Merge + Squash + Delete-Branch-On-Merge + PR-Body als Squash-Commit-Message (damit `closes #N` Auto-Close beim Squash-Merge zuverlaessig greift):
   gh api --method PATCH /repos/Jobi0202/{{SLUG}} `
     -F "allow_auto_merge=true" `
     -F "delete_branch_on_merge=true" `
     -F "allow_squash_merge=true" `
     -F "allow_merge_commit=false" `
     -F "allow_rebase_merge=false" `
     -F "is_template=false" `
     -F "squash_merge_commit_title=PR_TITLE" `
     -F "squash_merge_commit_message=PR_BODY"

8. Specs commit + push:
   git add specs/
   git commit -m "feat: import specs from PM"
   git push

8.5. Vercel-Project bootstrap (kein zweiter manueller Setup-Step mehr fuer Jo):
   npm install -g vercel@latest
   vercel whoami
   # Wenn 'Not logged in': STOPP, sag Jo 'vercel login' einmalig, dann nochmal starten.

   vercel link --yes --project {{SLUG}}
   vercel deploy --prod --yes > /tmp/vercel_deploy.txt 2>&1
   cat /tmp/vercel_deploy.txt
   PROD_URL=$(grep -oE 'https://[a-z0-9.-]+\.vercel\.app' /tmp/vercel_deploy.txt | tail -1)
   if [ -z "$PROD_URL" ]; then
     echo "ERROR: Vercel deploy did not return a Production URL."
     exit 1
   fi
   echo "Production URL: $PROD_URL"

   # Eindeutige Sichtbarkeit der Production-URL in GitHub:
   gh repo edit Jobi0202/{{SLUG}} --homepage "$PROD_URL"
   {
     echo "# {{SLUG}}"
     echo ""
     echo "🟢 **Live:** $PROD_URL"
     echo ""
     tail -n +2 README.md 2>/dev/null
   } > /tmp/README.new && mv /tmp/README.new README.md
   git add README.md
   git commit -m "chore: surface Vercel Production URL"
   git push

9. Validate setup:
   gh repo view Jobi0202/{{SLUG}} --json name,visibility,isTemplate
   gh secret list --repo Jobi0202/{{SLUG}}

10. Lies in dieser Reihenfolge:
    - CLAUDE.md (Operator-Manual, gilt strikt)
    - .claude/rules/architecture.md, boy-scout.md, testing.md, review.md, anti-spaghetti.md
    - specs/vision.md, specs/prd-light.md, specs/architecture.md, specs/issues.md
    - .github/workflows/pr-gates.yml

11. Beginne mit Issue #1 aus specs/issues.md. Befolge die Core-Loop strikt: Issue -> Worktree -> Plan -> Build -> Tests -> PR. Keine Custom-Workflows. Keine Edits an .github/workflows/, .claude/rules/, CLAUDE.md ausser im expliziten Template-Evolution-Issue.

Bei Fehlern in Schritt 1-9: STOPP, sag Jo welcher Schritt fehlgeschlagen ist und was zu tun ist. Niemals Build starten wenn Setup nicht green.

Bei Mehrdeutigkeit in Specs: niemals raten. Comment am Issue mit Label needs-jo, stop.
```
