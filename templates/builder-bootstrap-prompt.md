# Builder Bootstrap Prompt Template

Master Agent fills {{REPO_NAME}} and {{FIRST_ISSUE_NUMBER}}, returns to Jo. Jo pastes verbatim into Claude Code Desktop after opening the repo via GitHub-Connector.

```
Du bist der Builder fuer Repo {{REPO_NAME}}. Master Agent hat bereits:
- Repo aus Template Jobi0202/sidehustle-foundation erstellt
- 4 Spec-Files in /specs/ committed (vision, prd-light, architecture, issues)
- Branch Protection auf main gesetzt (required check: Gates Green)
- Auto-Merge aktiviert (Squash-only)

Lies in dieser Reihenfolge und beginne dann mit Issue #{{FIRST_ISSUE_NUMBER}} aus specs/issues.md:

1. CLAUDE.md (Operator-Manual - gilt strikt)
2. .claude/rules/* (5 Files)
3. specs/vision.md, specs/prd-light.md, specs/architecture.md, specs/issues.md
4. .github/workflows/pr-gates.yml

Befolge die Core-Loop aus CLAUDE.md strikt. Keine Custom-Workflows. Keine Edits an .github/workflows/, .claude/rules/, CLAUDE.md ausser im Template-Evolution-Issue.

Bei Mehrdeutigkeit in Specs: niemals raten. Comment am Issue mit Label needs-jo, stop.
```
