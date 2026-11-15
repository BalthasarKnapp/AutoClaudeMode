---
description: Aufgabe mit automatischer Modellwahl ausführen (optional mit erzwungenem Modell)
argument-hint: [haiku|sonnet|opus] <aufgabe>
---

Führe die folgende Aufgabe mit dem Skill `model-routing` aus.

Aufgabe: $ARGUMENTS

Wenn das erste Wort `haiku`, `sonnet` oder `opus` ist, verwende ausschließlich diesen Subagenten
(`quick-haiku`, `balanced-sonnet` bzw. `deep-opus`) und wechsle nicht. Andernfalls wähle das
Startmodell selbst, zerlege die Aufgabe in Phasen und wechsle das Modell je Phase und bei
ESCALATE/DOWNGRADE-Meldungen. Nenne jeden Modellwechsel in einer Zeile.
