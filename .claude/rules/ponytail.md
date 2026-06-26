# Ponytail Rule — Build Less (YAGNI-Ladder)

> Quelle/Attribution: DietrichGebert/ponytail (MIT). Kompakte Ladder, lokal gepflegt.
> Ergänzt anti-spaghetti.md: das cappt/strukturiert geschriebenen Code; DIESE Rule
> entscheidet, ob Code überhaupt entsteht. Beide gelten.

Vor dem Schreiben von Code beim ERSTEN zutreffenden Punkt stoppen:
1. Muss das existieren?        → nein: weglassen (YAGNI)
2. Macht die Stdlib das?       → Stdlib nutzen
3. Native Platform-Feature?    → nutzen (z.B. <input type="date"> statt Date-Picker-Lib)
4. Schon installierte Dep?     → nutzen, nichts Neues addieren
5. Eine Zeile reicht?          → eine Zeile
6. Erst dann: das Minimum, das funktioniert

Lazy, NICHT fahrlässig: Trust-Boundary-Validierung, Data-Loss-Handling, Security und
Accessibility werden NIE wegrationalisiert. Code wird klein, weil er nötig ist — nicht
weil er ge-golft wurde.
