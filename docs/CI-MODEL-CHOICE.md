# CI Model Choice — Gate 2 + Gate 3 (Target-Architektur 2026-06-04)

**Gate 2 (Claude Review):** DeepSeek via Anthropic-kompatiblem Endpoint (`api.deepseek.com/anthropic`), Modell `deepseek-v4-flash`.

**Gate 3 (Codex Adversarial):** OpenAI Codex bleibt eigentlicher Reviewer (Cross-Family-Adversarial gegen Gate 2, Architekt-Verdict 2026-05-17 B). CLI-Wrapper auf DeepSeek-Backend wie Gate 2.

**Reason:** Cost — Gates feuern auf jeden PR, Anthropic-Sonnet/Haiku skaliert linear mit PR-Volumen.

**Data flow:** PR-Diffs + geänderte Files an DeepSeek (China) — Source-Code unter Git-Historie ohnehin offen, kein Kunden-PII, keine Produktionsdaten.

**Opt-out:** Anthropic-Backend nur mit expliziter Build-vs-Buy-Notiz hier oben (z.B. DSGVO-Sondercase). Rollback-Pfad: ANTHROPIC_API_KEY-Zeile in `pr-gates.yml` aktivieren, DeepSeek-Zeilen auskommentieren.

**Caveat:** DeepSeek-flash zeigt gelegentlich Format-Drift (Meta-Prosa statt `VERDICT:`-Zeile). Mitigation: VERDICT-Format-Guard in pr-gates.yml. Bei wiederholtem Drift: ANTHROPIC_MODEL auf `deepseek-v4-pro` heben.

**Last reviewed:** 2026-06-04
