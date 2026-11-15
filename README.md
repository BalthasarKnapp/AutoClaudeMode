# auto-model-router

Claude-Code-Plugin, das für jede Aufgabe automatisch das passende Modell wählt
(**Haiku**, **Sonnet** oder **Opus**) und das Modell **während der Arbeit wechselt**,
wenn eine Phase leichter oder schwerer wird.

## So funktioniert es

1. **Hook (`UserPromptSubmit`)** - bei jedem Prompt schätzt `hooks/route.ps1` den
   Schwierigkeitsgrad (Stichwörter auf Deutsch/Englisch, Länge, Anzahl Anforderungen)
   und gibt Claude eine Modell-Empfehlung mit.
2. **Skill `model-routing`** - Claude arbeitet als Orchestrator, zerlegt die Aufgabe in
   Phasen (Erkunden → Planen → Umsetzen → Restarbeit → Prüfen) und delegiert jede Phase
   an den passenden Subagenten.
3. **Drei Subagenten mit festem Modell**
   - `quick-haiku` (Haiku) - Suchen, Lesen, Kleinkram, mechanische Änderungen
   - `balanced-sonnet` (Sonnet) - normale Entwicklungsarbeit
   - `deep-opus` (Opus) - Architektur, harte Bugs, Sicherheit, Performance
4. **Modellwechsel während der Arbeit** - Subagenten melden `ESCALATE: <modell>`, wenn
   die Aufgabe sie überfordert, oder `DOWNGRADE: <modell>`, wenn nur Routine übrig ist.
   Der Orchestrator startet dann das stärkere bzw. günstigere Modell mit dem bisherigen Stand.

## Installation

```
/plugin marketplace add <GITHUB-USER>/<REPO>
/plugin install auto-model-router@auto-model-router
```

Tipp: Stell die Hauptsitzung auf **Sonnet** (`/model sonnet`). Sie orchestriert nur;
die schwere Arbeit landet bei Opus, die leichte bei Haiku - so sparst du Kosten,
ohne an Qualität zu verlieren.

## Bedienung

Einfach normal arbeiten - das Routing passiert automatisch. Optional:

| Eingabe | Wirkung |
|---|---|
| `!haiku` / `!sonnet` / `!opus` im Prompt | Modell erzwingen |
| `!auto-off` im Prompt | Routing für diesen Prompt aus |
| `/auto-model-router:route opus <aufgabe>` | Aufgabe gezielt mit einem Modell |
| `/auto-model-router:route <aufgabe>` | Aufgabe mit automatischer Wahl |

## Grenzen

- Ein Plugin kann das Modell der **Hauptsitzung** nicht selbst umstellen. Der Wechsel
  passiert über Subagenten, die jeweils mit ihrem eigenen Modell laufen.
- Der Hook nutzt Windows PowerShell (`powershell`). Unter macOS/Linux braucht es
  PowerShell 7 (`pwsh`) - dann in `hooks/hooks.json` `powershell` durch `pwsh` ersetzen.
  Skill und Subagenten funktionieren auch ohne Hook.
- Die Hook-Empfehlung ist eine Heuristik; Claude darf sie überstimmen.

## Struktur

```
.claude-plugin/plugin.json        Plugin-Manifest
.claude-plugin/marketplace.json   macht das Repo als Marketplace installierbar
agents/                           quick-haiku, balanced-sonnet, deep-opus
skills/model-routing/SKILL.md     Routing- und Wechselregeln
hooks/hooks.json, hooks/route.ps1 automatische Empfehlung pro Prompt
commands/route.md                 /auto-model-router:route
```
