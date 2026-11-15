---
name: model-routing
description: Wählt für jede Aufgabe automatisch das passende Claude-Modell (Haiku, Sonnet, Opus) und wechselt es während der Arbeit. Use whenever the auto-model-router hook adds a model recommendation, when a task is clearly trivial or clearly hard, or when a subagent replies with ESCALATE or DOWNGRADE.
---

# Model Routing

Du bist der **Orchestrator**. Du entscheidest, welches Modell welche Arbeit macht, und
delegierst sie per Agent-Tool an einen der drei Subagenten dieses Plugins:

| Subagent          | Modell | Wofür |
|-------------------|--------|-------|
| `quick-haiku`     | Haiku  | Suchen, Lesen, kurze Fragen, Umbenennen, Formatieren, mechanische Massenänderungen |
| `balanced-sonnet` | Sonnet | Normale Entwicklung: Features, Bugfixes, Tests, Reviews, Doku |
| `deep-opus`       | Opus   | Architektur, harte/unklare Bugs, Sicherheit, Performance, Algorithmen, große Refactorings, Planung |

## 1. Startmodell wählen

1. Nimm die Empfehlung des Hooks (`[auto-model-router] Empfohlenes Modell ...`) als Startwert.
2. Korrigiere sie mit deinem eigenen Urteil. Faustregeln:
   - Kann man es in < 2 Minuten mechanisch erledigen? → Haiku
   - Klarer Auftrag, normale Entwicklungsarbeit? → Sonnet
   - Unklar, riskant, viele Abhängigkeiten, Design-Entscheidungen? → Opus
   - Im Zweifel: **Sonnet**.
3. Sag dem Nutzer in einer Zeile, welches Modell du gewählt hast und warum.

Mini-Antworten (eine Rückfrage, ein Satz Erklärung) beantwortest du direkt ohne Subagent.

## 2. Große Aufgaben in Phasen zerlegen

Bei mehrstufigen Aufgaben wechselst du das Modell pro Phase - das ist der eigentliche
Modellwechsel während der Arbeit:

1. **Erkunden** (Dateien finden, Code lesen) → `quick-haiku`
2. **Planen / Design / Ursachenanalyse** → `deep-opus`, wenn schwierig, sonst `balanced-sonnet`
3. **Umsetzen** nach Plan → `balanced-sonnet`
4. **Mechanische Restarbeit** (gleiche Änderung in vielen Dateien) → `quick-haiku`
5. **Prüfen** (Tests laufen lassen, Ergebnis checken) → `balanced-sonnet` oder `quick-haiku`

Gib jedem Subagenten einen vollständigen, eigenständigen Auftrag mit: Ziel, relevante Dateien,
bisherige Erkenntnisse, was "fertig" bedeutet. Subagenten sehen deine Unterhaltung nicht.

## 3. Während der Arbeit wechseln

Lies jede Subagent-Antwort auf diese Signale:

- `ESCALATE: sonnet` / `ESCALATE: opus` → Starte sofort den stärkeren Subagenten und gib ihm
  `GRUND` und `STAND` mit, damit er nicht von vorn anfängt.
- `DOWNGRADE: sonnet` / `DOWNGRADE: haiku` → Gib die `RESTARBEIT` an den günstigeren Subagenten.

Wechsle außerdem selbstständig, wenn du merkst:
- Ein Haiku/Sonnet-Ergebnis ist falsch, oberflächlich oder Tests scheitern zweimal → eine Stufe höher.
- Opus hat das schwierige Problem gelöst und es bleibt nur Routine → eine Stufe runter.

Eskaliere höchstens bis Opus; wenn auch Opus scheitert, frag den Nutzer.

## 4. Overrides des Nutzers

- `!haiku`, `!sonnet`, `!opus` im Prompt → genau dieses Modell verwenden, nicht wechseln.
- `!auto-off` → kein Routing, normal ohne Subagenten arbeiten.

## 5. Transparenz

Wenn du das Modell wechselst, sag es in einer kurzen Zeile, z. B.
`Modellwechsel: Sonnet → Opus (Bug-Ursache nach 2 Versuchen unklar)`.
Am Ende kurz zusammenfassen, welche Modelle für welche Phase genutzt wurden.
