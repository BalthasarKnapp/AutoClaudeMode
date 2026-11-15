# auto-model-router: UserPromptSubmit hook
# Liest den Prompt (JSON auf stdin), schaetzt den Schwierigkeitsgrad und gibt
# Claude eine Modell-Empfehlung als zusaetzlichen Kontext mit.
# Overrides im Prompt: !haiku  !sonnet  !opus  !auto-off

$ErrorActionPreference = 'SilentlyContinue'
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $data = $raw | ConvertFrom-Json } catch { exit 0 }
$prompt = [string]$data.prompt
if (-not $prompt) { exit 0 }
$p = $prompt.ToLowerInvariant()

if ($p -match '!auto-off') { exit 0 }

$tier = $null
$reason = ''
if     ($p -match '!opus')   { $tier = 'opus';   $reason = 'manueller Override (!opus)' }
elseif ($p -match '!sonnet') { $tier = 'sonnet'; $reason = 'manueller Override (!sonnet)' }
elseif ($p -match '!haiku')  { $tier = 'haiku';  $reason = 'manueller Override (!haiku)' }

if (-not $tier) {
    $opusWords = @(
        'architektur','architecture','systemdesign','system design','design pattern',
        'migration','migrier','security','sicherheit','vulnerab','schwachstelle','exploit',
        'race condition','deadlock','concurren','nebenlaeuf','nebenläuf','thread-safe',
        'performance','optimier','optimiz','bottleneck','engpass','memory leak','speicherleck',
        'algorithm','algorithmus','komplex','complex','skalier','scalab','distributed','verteilt',
        'von grund auf','from scratch','gesamte','ganze codebase','entire codebase','whole codebase',
        'strategie','strategy','trade-off','abwaegung','abwägung','root cause','ursache',
        'seit tagen','mysterious','mysterioes','mysteriös','unerklaerlich','unerklärlich',
        'kryptograf','cryptograph','compiler','parser','refactor the whole','komplett umbauen'
    )
    $haikuWords = @(
        'typo','tippfehler','rechtschreib','umbenenn','rename','formatier','format ',
        'was ist','what is','wo ist','where is','wo finde','zeig mir','show me','liste ','list ',
        'finde ','find ','lies ','read ','uebersetz','übersetz','translate','zusammenfass','summar',
        'kurz','quick','schnell','einfach','simple','kommentar hinzu','add comment','version von',
        'welche datei','which file','ls ','grep','status'
    )
    $sonnetWords = @(
        'implement','baue','bau ','build','erstell','create','fix','bug','fehler','test',
        'feature','funktion','schreib','write','refactor','review','endpoint','komponente','component',
        'script','skript','plugin','api','ui','seite','page'
    )

    $o = 0; $h = 0; $s = 0
    foreach ($w in $opusWords)   { if ($p.Contains($w)) { $o++ } }
    foreach ($w in $haikuWords)  { if ($p.Contains($w)) { $h++ } }
    foreach ($w in $sonnetWords) { if ($p.Contains($w)) { $s++ } }

    $len = $prompt.Length
    if ($len -gt 800) { $o += 2 } elseif ($len -gt 400) { $o += 1 }
    if ($len -lt 80)  { $h += 1 }
    # Viele Aufzaehlungspunkte/Anforderungen = groessere Aufgabe
    $bullets = ([regex]::Matches($prompt, '(?m)^\s*([-*]|\d+[.)])\s')).Count
    if ($bullets -ge 5) { $o += 1; $s += 1 }

    if ($o -ge 2 -or ($o -ge 1 -and $o -ge $s)) {
        $tier = 'opus'
    } elseif ($h -ge 2 -and $h -ge $s) {
        $tier = 'haiku'
    } else {
        $tier = 'sonnet'
    }
    $reason = "Heuristik (opus=$o, sonnet=$s, haiku=$h, laenge=$len)"
}

$agent = @{ haiku = 'quick-haiku'; sonnet = 'balanced-sonnet'; opus = 'deep-opus' }[$tier]

$ctx = @"
[auto-model-router] Empfohlenes Modell fuer diese Aufgabe: $tier -> Subagent "$agent".
Grund: $reason.
Wende den Skill "model-routing" an: Delegiere die eigentliche Arbeit per Agent-Tool an den passenden
Subagenten (quick-haiku / balanced-sonnet / deep-opus). Die Empfehlung ist ein Startwert - wenn du die
Aufgabe anders einschaetzt, waehle selbst. Reagiere auf ESCALATE/DOWNGRADE-Meldungen der Subagenten mit
einem Modellwechsel. Reine Rueckfragen oder Mini-Antworten darfst du direkt beantworten.
Nenne dem Nutzer kurz, welches Modell du gewaehlt hast (z. B. "Modell: Sonnet").
"@

$out = @{
    hookSpecificOutput = @{
        hookEventName     = 'UserPromptSubmit'
        additionalContext = $ctx
    }
}
$out | ConvertTo-Json -Compress -Depth 5
exit 0
