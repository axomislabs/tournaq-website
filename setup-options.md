# TournaQ — Setup-Seiten: alle Einstellungen

Vollständiger Export aller Einstellungen der acht Turnier-Setup-Seiten der App
(`~/Projects/tournaq`, Branch `main`, Stand 2026-08-23), mit Presets, Defaults,
harten Grenzen, Sichtbarkeits- und Warnbedingungen sowie den Hilfetexten wörtlich
aus der App.

**Steht auch im User Guide selbst**: jede „Setting up …“-Seite in `pages/guide.html`
(Keys `m-*-hub`) trägt ihre Tabelle als `opts`-Block, das Gemeinsame liegt auf der
Seite `setup-settings`. Ändert sich eine Setup-Seite in der App, müssen diese Datei
und die Tabellen dort zusammen nachgezogen werden.

Schwesterdateien: `tournament-options.md` für die laufende Turnierseite,
`scorecard-options.md` für die Scorecards. `tools/export-options.py` erzeugt aus
allen dreien die CSV-Zwillinge.

Deutsche Spalten und Zwischentexte sind Beschreibung; alles in `"…"` ist der
englische App-String im Original (Platzhalter wie `{teams}` bleiben stehen).

## Wie die Seiten aufgebaut sind

Alle acht Seiten laufen über dieselben Bausteine
(`lib/widgets/setup/`, `SetupPageScaffold` → `SetupSectionHeader` → `SetupFieldGrid`):

1. **Tournament Setup** — das Feldraster mit allen Mode-Einstellungen
2. **Schedule Preview** — die Karte, die zeigt, was diese Einstellungen kosten (Zeit, Slots, Runden)
3. **Pace alerts** — Schalter direkt unter der Vorschau
4. **Suggestions** — nur bei den Player-Pool-Modi, nur wenn es etwas zu sagen gibt
5. **Teams** bzw. **Players** — Roster-Kachel, öffnet das Roster-Sheet
6. **Tournament Name** — Textfeld mit Vorschlags-Button
7. **Create** — Bereitschaftszeile plus „Create Tournament“

Jedes Feld ist entweder ein Zahlenfeld (tippbar plus Preset-Dropdown), ein
Auswahlfeld, ein Schalter oder ein gesperrtes Feld. Ein Fragezeichen am Feldrand
öffnet den Hilfetext; eine Fußnote unter dem Feld erscheint nur, wenn der gewählte
Wert eine Warnung verdient.

**Modi im Überblick**

| Guide-Seite | Titel in der App | Quelldatei | Familie |
|---|---|---|---|
| Setting up a League | League | `lib/pages/league_setup_page.dart` | Bracket (Teams) |
| Setting up an Elimination | Elimination | `lib/pages/elimination_setup_page.dart` | Bracket (Teams) |
| Setting up a TournaQ Classic | Group + Knockout | `lib/pages/group_knockout_setup_page.dart` | Bracket (Teams) |
| Setting up a Swiss System | Swiss System | `lib/pages/swiss_setup_page.dart` | Bracket (Teams) |
| Setting up a Social Scramble | Social Scramble | `lib/pages/scramble_setup_page.dart` | Player Pool (Runden) |
| Setting up a Royal Rotation | Scramble King | `lib/pages/scramble_king_setup_page.dart` | Player Pool (Queue) |
| Setting up a King of the Court | King of the Court | `lib/pages/kotc_queue_setup_page.dart` | Player Pool (Queue) |
| Setting up a Royal Shuffle | Doghouse | `lib/pages/doghouse_queue_setup_page.dart` | Player Pool (Queue) |

> **Namens-Abweichung:** Der Guide sagt „Royal Rotation“ und „Royal Shuffle“, die App
> sagt weiterhin „Scramble King“ und „Doghouse“. Wer den Guide gegen die App liest,
> stolpert darüber.

---

# 0 · Was auf jeder Setup-Seite gleich ist

## 0.1 Schedule Preview — Zeitsteuerung

Die goldene Karte unter dem Feldraster. Bei den vier Bracket-Modi ist sie
gleichzeitig Editor: Startzeit, Spielformat, Tempo, Pausen und einzelne
Slot-Starts werden hier gesetzt, nicht im Raster darüber.

| Einstellung | Werte / Presets | Default | Grenzen | Bedingungen & Warnungen | Wofür | Hilfetext in der App (wörtlich) |
|---|---|---|---|---|---|---|
| Startdatum | Datumsauswahl | heute (bzw. Tag der Startzeit) | gestern bis +365 Tage | nur Bracket-Modi (League, Elimination, TournaQ Classic, Swiss); Player-Pool-Modi haben nur eine Uhrzeit | Legt fest, ab wann geplant wird; erlaubt mehrtägige Events | — |
| Startzeit | Zeitauswahl | jetzt + 1 Stunde (Bracket) bzw. "Now" (Player Pool) | — | Player-Pool-Modi zeigen "Start: Now", bis eine Zeit gewählt wird | Anker für alle Zeitschätzungen | — |
| Game format | öffnet Sheet, siehe 0.2 | 1 × 15, Seitenwechsel alle 5, Hinweis an | — | nur Bracket-Modi; Zusatzzeile "{count} rounds differ", sobald einzelne Runden abweichen | Wie viel gespielt wird — Sätze und Zielpunktzahl | "Applies to every round. Individual rounds can differ." |
| Game pace | öffnet Sheet, siehe 0.3 | Standard · 60 s | ab 5 s | nur Bracket-Modi | Wie lange ein Ballwechsel dauert — daraus folgt jede Zeitangabe | "How long a rally takes on average. Drives every time estimate for this tournament." |
| Format je Slot / Runde | dasselbe Sheet plus "Use the default" | erbt den Default | — | nur in der aufgeklappten Detailliste; Reset erscheint nur, solange eine Abweichung gesetzt ist | Einzelne Runde kürzer oder länger spielen | — |
| Pause nach Slot / Runde | 0, 5, 10, 15, 20, 30, 45, 60 min plus freie Eingabe | 0 (keine Pause) | 0 bis 1440 min (24 h) | letzte Runde hat keine Pause; erscheint als "Add break", solange 0 | Mittagspause, Siegerehrung, Platzwechsel einplanen | "Custom length" · Eingabehilfe "e.g. 25" |
| Slot-Start verankern | "Set start day & time" oder "Remove — back to auto" | automatisch | gestern bis +365 Tage | nur Bracket-Modi; "custom start" markiert verankerte Slots | Mehrtägige Events oder feste Anspielzeiten fixieren | — |
| Detail ein-/ausklappen | "Show all {count} slots" / "Hide detail" | eingeklappt | — | Expander erscheint erst ab mehr als 4 Slots; darunter steht die Liste immer offen | Übersicht behalten, ohne die Rundenliste zu verlieren | — |

Angezeigt (nicht einstellbar): Gesamtdauer, voraussichtliches Ende, Slots und
Matches, Dauer je Slot, Summe der Pausen, Anzahl verankerter Starts.

## 0.2 Game format sheet (`lib/widgets/game_format_sheet.dart`)

Nur Bracket-Modi. Schreibt sofort — jede Änderung terminiert die Vorschau neu, es gibt kein Speichern.

| Einstellung | Werte / Presets | Default | Grenzen | Bedingungen & Warnungen | Wofür | Hilfetext in der App (wörtlich) |
|---|---|---|---|---|---|---|
| Sets per game | 1, 3, 5 | 1 | nur diese drei | — | Best-of-Format des Spiels | — |
| Target score | 11, 15, 21, "Custom…" | 15 | ab 1 | — | Zielpunktzahl je Satz | — |
| Side change | "Off", 5, 7, "Custom…" | 5 | ab 1 | "Off" schaltet den Seitenwechsel ganz ab | Seitenwechsel alle n Punkte | — |
| Notify at target score | Schalter | an | — | — | Fragt beim Erreichen der Zielpunktzahl nach, ob das Spiel endet | "Prompt to finish when a side reaches the target" |
| Use the default | Button | — | — | nur beim Bearbeiten einer einzelnen Runde und nur, solange sie abweicht | Override wieder auf den Turnier-Default zurücksetzen | — |

## 0.3 Game pace sheet

| Einstellung | Werte / Presets | Default | Grenzen | Bedingungen & Warnungen | Wofür | Hilfetext in der App (wörtlich) |
|---|---|---|---|---|---|---|
| Seconds per point | "Fast · 45s", "Standard · 60s", "Relaxed · 80s", "Custom…" | Standard · 60 s | ab 5 s | zeigt darunter "about {minutes} min a game" | Einzige freie Variable in einem Punkte-Ziel-Zeitplan | "How long a rally takes on average. Drives every time estimate for this tournament." |

## 0.4 Pace alerts

| Einstellung | Werte / Presets | Default | Grenzen | Bedingungen & Warnungen | Wofür | Hilfetext in der App (wörtlich) |
|---|---|---|---|---|---|---|
| Pace alerts | Schalter | aus | — | auf allen acht Seiten vorhanden | Markiert Runden im laufenden Turnier als pünktlich, fällig oder überfällig | "Flag rounds as on track, due, or overdue" |

## 0.5 Roster — Teams bzw. Players

Die Kachel unter der Vorschau ist dreistufig: grau ohne Einträge, rot bei falscher
Anzahl, oliv sobald die Zahl passt. Sie öffnet das Roster-Sheet.

| Element | Werte / Presets | Default | Grenzen | Bedingungen & Warnungen | Wofür | Hilfetext in der App (wörtlich) |
|---|---|---|---|---|---|---|
| Roster-Kachel | "Tap to add teams" / "Tap to add players" bzw. "{count}/{target} … added" | leer | — | — | Bereitschaftsanzeige der Seite | — |
| Create Player / Create Team | Name eingeben, "Add" | — | — | doppelter Name fragt nach: "{name} is already added to this tournament. Add anyway?" | Teilnehmer anlegen, die noch nicht in der Administration stehen | — |
| Add Existing | Liste aus der Administration, Gruppen-Chips, Suche, "Add all ({count})" | — | — | Bracket-Modi zeigen nur Teams, die exakt das gewählte Format besetzen (`userIds.length == playersPerSide`); Gruppen-Chips erscheinen nur für Gruppen mit passenden Einträgen | Bestehende Spieler und Teams übernehmen | — |
| Fill {count} random | Button | — | — | nur Player-Pool-Modi; füllt auf die Zielanzahl auf | Testlauf oder spontane Session ohne Namensliste | — |
| Clear all | Button mit Rückfrage | — | — | "This will remove all added players from the list." | Roster zurücksetzen | — |
| Confirm | Bestätigungsleiste | — | — | Bei Abweichung: "You added {selected} teams, but the setup is planned for {target}. Adjusting updates the bracket, seeding and schedule — keep {target} if you'd rather review the line-up first." Liegt die Zahl außerhalb der Grenzen: "The player count runs from {min} to {max}, so it can't be set to {selected}." | Geplante Anzahl der tatsächlichen Aufstellung angleichen | — |

## 0.6 Name und Create

| Einstellung | Werte / Presets | Default | Grenzen | Bedingungen & Warnungen | Wofür | Hilfetext in der App (wörtlich) |
|---|---|---|---|---|---|---|
| Tournament Name | Freitext plus Würfel-Button | zufälliger Name passend zum Modus | darf nicht leer sein | — | Name im Arena-Überblick und auf der Scorecard | "Suggest a name" |
| Create Tournament | Button | deaktiviert | — | Statuszeile darüber: "Ready to start!" / "Setup looks good!" bzw. "Add all {count} teams to continue" / "Setup incomplete" | Legt das Turnier an | — |

---

# 1 · Setting up a League

`lib/pages/league_setup_page.dart` — Titel in der App: **League**. Jeder gegen jeden,
ein oder zwei Durchgänge. Setzt feste Teams voraus.

## 1.1 Tournament Setup

| Einstellung | Werte / Presets | Default | Grenzen | Bedingungen & Warnungen | Wofür | Hilfetext in der App (wörtlich) |
|---|---|---|---|---|---|---|
| Teams | Zahlenfeld, Presets 4, 6, 8, 10, 12, 16 | 8 | 2 bis 64 | Wird die Zahl unter die Anzahl bereits hinzugefügter Teams gesenkt, wird das Roster gekürzt | Feldgröße; daraus folgen Spielplan, Runden und Dauer | — |
| Courts | Zahlenfeld, Presets 1 bis 6 | 2 | 1 bis 32 | Warnung, sobald mehr Felder als Teams ÷ 2: "Only {usable} courts can be used with {teams} teams — every team plays once per slot." | Wie viele Partien gleichzeitig laufen | — |
| Referees | "Fill every court" / "Keep a referee free" | Fill every court | — | "Keep a referee free" ist nur wählbar, wenn das Feld nicht alle Plätze besetzen kann (oder die Option bereits gesetzt ist). Fußnote bei Unterdeckung: "{gap} matches per round starts without a referee: {teams} teams cover {ceiling} courts at once, not {courts}." plus "Reserving covers them all and adds about {time}." | Ob Schiedsrichter aus dem Feld gestellt werden oder Partien unbesetzt laufen | "Fill every court — Games run on every available court. There may be no free player left to referee — assign one by hand, or let the teams manage the game themselves." · "Keep a referee free — Makes sure every game has a referee from the player pool. Only available once every court is filled and too few players sit out — matches wait so someone is free to referee, which makes the tournament longer." |
| Style | 1vs1 bis 6vs6 | 2vs2 | 1 bis 6 je Seite | Beim Wechsel werden bestehende Teams auf die neue Größe gebracht, fehlende Plätze heißen "Player n" | Mannschaftsgröße je Seite | — |
| Legs | "Single" / "Double" | Single | — | — | Ob jede Paarung einmal oder zweimal gespielt wird | "Single — Every pair of teams meets exactly once. The shortest format — ideal for a single session." (Beispiel: "Example (6 teams): 5 rounds of 3 matches — 15 matches in total.") · "Double — Every pair meets twice, the second time with the sides reversed. Twice the rounds, and a fairer table." (Beispiel: "Example (6 teams): 10 rounds of 3 matches — 30 matches in total.") · "Odd teams — With an odd number of teams, one team sits out each round. The bye rotates, so everyone sits out equally often." (Beispiel: "Example (7 teams): 7 rounds of 3 matches, each team resting once.") |
| Generation | "Random" / "Seeded" | Random | — | "Seeded" ist ausgegraut und nicht wählbar (noch nicht ausgeliefert) | Wie die Reihenfolge der Paarungen zustande kommt | — |
| Back-to-back | "Never" / "Up to 2" / "No limit" | Up to 2 | — | Der Hilfetext zeigt zu jeder Option die konkrete Slot-Zahl der aktuellen Konfiguration | Wie hart der Spielplan die Felder packt — Erholung gegen Gesamtdauer | "Never — Every team gets a slot off between matches. Kindest on players, but the longest schedule." · "Up to 2 — A team plays at most two slots in a row before resting. Balances a full set of courts against recovery." · "No limit — Pack the courts as tightly as the fixtures allow. The shortest day, but a team can play many matches in a row." |

## 1.2 Weiter unten auf der Seite

Schedule Preview mit Slot-Liste (siehe 0.1), Pace alerts (0.4), Teams-Roster (0.5),
Name und Create (0.6). Die Slot-Liste klappt ab fünf Slots ein und fasst dann
zusammen: Slots und Matches, Dauer je Slot, Pausen, verankerte Starts.

**Create ist möglich, wenn:** Name nicht leer, Teams ≥ 2, und genau so viele Teams
hinzugefügt wie geplant.

---

# 2 · Setting up an Elimination

`lib/pages/elimination_setup_page.dart` — Titel in der App: **Elimination**.
Ein Leben oder zwei; die zweite Hälfte des Rasters hängt an dieser Wahl.

## 2.1 Tournament Setup

| Einstellung | Werte / Presets | Default | Grenzen | Bedingungen & Warnungen | Wofür | Hilfetext in der App (wörtlich) |
|---|---|---|---|---|---|---|
| Teams | Zahlenfeld, Presets 4, 6, 8, 10, 12, 16 | 8 | 2 bis 64 | Roster wird gekürzt, wenn die Zahl sinkt | Feldgröße; entscheidet über Bracket-Größe und Freilose | — |
| Courts | Zahlenfeld, Presets 1 bis 6 | 2 | 1 bis 32 | — | Wie viele Partien gleichzeitig laufen | — |
| Referees | "Fill every court" / "Keep a referee free" | Fill every court | — | wie bei League (siehe 1.1) | Schiedsrichterdeckung aus dem Teilnehmerfeld | wie bei League (siehe 1.1) |
| Style | 1vs1 bis 6vs6 | 2vs2 | 1 bis 6 je Seite | — | Mannschaftsgröße je Seite | — |
| Format | "Single Elimination" / "Double Elimination" | Single Elimination | — | Steuert, welche Felder darunter erscheinen | Ob eine Niederlage ausscheidet oder erst die zweite | "Single elimination: lose once and you're out. Shortest format, fixed finish time. Double elimination: winners and losers brackets — you need two losses to be eliminated. Roughly twice the matches. On eight teams: 7 matches single, 14 double." |
| Generation | "Random" / "Seeded" | Random | — | "Seeded" ausgegraut (noch nicht ausgeliefert) | Wie die Auslosung entsteht | — |
| Odd Teams | "Byes" / "Play-in" / "Play-in+" | Byes | — | nur bei Single Elimination; "Play-in+" ist ausgegraut | Was passiert, wenn das Feld keine Zweierpotenz ist | "Byes — Top seeds skip round 1 and wait. Weaker seeds play first. Fastest setup — ideal when you want to reward higher seedings without extra matches." (Beispiel: "Example (5 teams): Seeds 1–3 wait. Seeds 4 and 5 play. Winner joins the main bracket.") · "Play-in — Bottom seeds play a preliminary round to earn their bracket spot. Nobody gets a free pass — every team has to win to advance." (Beispiel: "Example (5 teams): Seeds 4 and 5 play a play-in. Winner takes the last slot in the main bracket.") |
| Grand final | "Single match" / "Bracket reset" | Single match | — | nur bei Double Elimination; Fußnote "Byes — fixed for this format", weil Double Elimination die Odd-Team-Regel festlegt | Wie das Finale zwischen ungeschlagenem und einmal geschlagenem Team entschieden wird | "The winners bracket champion reaches the grand final undefeated; the losers champion already has one loss. Single match: one game decides the title, whoever wins it. Bracket reset: if the losers champion wins, both sides have one loss and a decider is played. Fairer, but the finish time is not fixed." |
| Second chance | "All rounds" oder "Through round {n}" | All rounds | 1 bis (Hauptrunden − 1) | nur bei Double Elimination und nur, wenn das Bracket mehr als eine Hauptrunde hat | Ab welcher Runde eine Niederlage endgültig ausscheidet | "Who drops into the losers bracket after a defeat. All rounds is true double elimination — every loss earns a second life. Capping it shortens the tournament: losers from later rounds are out straight away. On eight teams, capping at round 1 is 11 matches instead of 14." |
| Fill empty places | Schalter | an | — | nur bei Double Elimination | Vergibt freie Plätze im Losers Bracket statt Freilose | "Give a spare losers-bracket place to the best eliminated team instead of a bye" |

## 2.2 Weiter unten auf der Seite

Schedule Preview mit Runden-Liste (0.1), Pace alerts (0.4), Teams-Roster (0.5),
Name und Create (0.6).

**Create ist möglich, wenn:** Name nicht leer, Teams ≥ 2, Roster vollständig.

---

# 3 · Setting up a TournaQ Classic

`lib/pages/group_knockout_setup_page.dart` — Titel in der App: **Group + Knockout**.
Gruppenphase in eine mehrstufige K.-o.-Phase. Die längste Setup-Seite der App,
weil hier zwei Phasen und beliebig viele Tiers konfiguriert werden.

## 3.1 Tournament Setup

| Einstellung | Werte / Presets | Default | Grenzen | Bedingungen & Warnungen | Wofür | Hilfetext in der App (wörtlich) |
|---|---|---|---|---|---|---|
| Teams | Zahlenfeld, Presets 4, 6, 8, 10, 12, 16 | 8 | 2 bis 64 | Roster wird gekürzt, wenn die Zahl sinkt | Feldgröße; bestimmt Gruppengrößen und Qualifikantenzahl | — |
| Courts | Zahlenfeld, Presets 1 bis 6 | 2 | 1 bis 32 | Warnung bei mehr Feldern als nutzbar: "Only {usable} courts can be used with {teams} teams — every team plays once per slot." | Wie viele Partien gleichzeitig laufen | — |
| Referees | "Fill every court" / "Keep a referee free" | Fill every court | — | wie bei League (siehe 1.1) | Schiedsrichterdeckung aus dem Teilnehmerfeld | wie bei League (siehe 1.1) |
| Style | 1vs1 bis 6vs6 | 2vs2 | 1 bis 6 je Seite | — | Mannschaftsgröße je Seite | — |
| Legs | "Single" / "Double" | Single | — | betrifft nur die Gruppenphase | Ob in der Gruppe einmal oder zweimal gegeneinander gespielt wird | "Single — Every pair of teams meets exactly once. The shortest format — ideal for a single session." · "Double — Every pair meets twice, the second time with the sides reversed. Twice the rounds, and a fairer table." |
| Generation | "Random" / "Seeded" | Random | — | "Seeded" ausgegraut (noch nicht ausgeliefert) | Wie die Gruppen ausgelost werden | — |
| Groups | 2 bis Teams ÷ 2 | 2 | 2 bis 8 | Auswahlliste endet bei Teams ÷ 2, höchstens 8 | Einzige Größensteuerung — die Gruppengrößen folgen daraus | "Group count is the only sizing control — sizes follow from it. 17 teams into 4 groups gives one group of 5 and three of 4. That is normal and nothing breaks, but teams in the bigger group play one more match, so when the app compares teams across groups it uses points per match rather than totals. More groups is not automatically better: it raises the number of qualifiers, which can push a tier onto a bigger bracket with more byes." |
| One court per group | Schalter | an | — | greift nur, wenn die Felder aufgehen; sonst wirkungslos | Gibt jeder Gruppe und später jedem Tier ein eigenes Feld | "Give each group, and then each tier, a court of its own where the courts allow it." |
| Back-to-back | "Never" / "Up to 2" / "No limit" | Up to 2 | — | Hilfetext zeigt je Option die Slot-Zahl der aktuellen Konfiguration | Wie hart der Spielplan die Felder packt | wie bei League (siehe 1.1) |

Unter dem Raster zeigt eine Split-Bar sofort, wie sich das Feld auf die Gruppen verteilt.

## 3.2 Qualification — je Platzierung und je Tier

Für jede Platzierung in der Gruppe wird gewählt, wohin sie führt. Tiers heißen
Gold, Silver, Bronze und so weiter; Standard ist Platz 1 und 2 nach Gold, der Rest raus.

| Einstellung | Werte / Presets | Default | Grenzen | Bedingungen & Warnungen | Wofür | Hilfetext in der App (wörtlich) |
|---|---|---|---|---|---|---|
| Ziel je Platzierung | Tier (Gold, Silver, …) oder "Out" | Platz 1 und 2 → Gold, alle weiteren → Out | höchstens 8 Tiers | Es kann nur der nächste noch nicht benutzte Tier neu geöffnet werden — kein Bronze ohne Silver. Lücken werden automatisch geschlossen, Tier-Einstellungen wandern mit. Bei ungleichen Gruppen: "only {have} of {total} groups have one" | Wer nach der Gruppenphase weiterspielt und in welchem Wettbewerb | — |
| Format je Tier | "Single elimination" / "Double elimination" | Single elimination | — | pro Tier eigenständig; kein turnierweiter Schalter | Trostrunden mehr Spiele geben, ohne die Spitze zu verlängern | — |
| Seeding je Tier | "Cross-group" / "Overall rank" / "Random" | Cross-group | — | pro Tier eigenständig | Wie die Qualifikanten im Baum verteilt werden | "Cross-group pairs each group winner with another group's runner-up, and keeps two teams from the same group in opposite halves so they can only meet in the final. Overall rank ranks every qualifier across all groups — on points per match, so uneven groups compare fairly — and seeds them best against worst. Random draws the qualifiers out of a hat." |
| Break before knockout | Pausen-Sheet, 0 bis 60 min plus freie Eingabe | 15 min | 0 bis 1440 min | steht in der Zeitleiste an der Nahtstelle zwischen den Phasen | Umbaupause zwischen Gruppenphase und K.-o. | — |

Angezeigt je Tier: "{teams} teams · {size}-team bracket, {byes} byes" sowie
"{count} eliminated in the groups".

## 3.3 Weiter unten auf der Seite

Schedule Preview, in zwei Phasen geteilt (Gruppen-Slots und K.-o.-Slots getrennt
auf- und zuklappbar), Pace alerts (0.4), Teams-Roster (0.5), Name und Create (0.6).

**Create ist möglich, wenn:** Name nicht leer, Teams ≥ 2, Roster vollständig.

---

# 4 · Setting up a Swiss System

`lib/pages/swiss_setup_page.dart` — Titel in der App: **Swiss System**.
Jede Runde wird nach Punktgleichheit neu gepaart, deshalb steht vor dem Start nur
die Rundenzahl fest, nicht die Paarungen.

## 4.1 Tournament Setup

| Einstellung | Werte / Presets | Default | Grenzen | Bedingungen & Warnungen | Wofür | Hilfetext in der App (wörtlich) |
|---|---|---|---|---|---|---|
| Teams | Zahlenfeld, Presets 4, 6, 8, 10, 12, 16 | 8 | 2 bis 64 | Bei ungerader Zahl Fußnote: "One team sits out each round. The bye rotates." | Feldgröße; bestimmt auch die automatische Rundenzahl | — |
| Courts | Zahlenfeld, Presets 1 bis 6 | 2 | 1 bis 32 | Warnung bei mehr Feldern als nutzbar: "Only {usable} courts can be used with {teams} teams — every team plays once per slot." | Wie viele Partien gleichzeitig laufen | — |
| Referees | "Fill every court" / "Keep a referee free" | Fill every court | — | wie bei League (siehe 1.1) | Schiedsrichterdeckung aus dem Teilnehmerfeld | wie bei League (siehe 1.1) |
| Style | 1vs1 bis 6vs6 | 2vs2 | 1 bis 6 je Seite | — | Mannschaftsgröße je Seite | — |
| Rounds | "Auto ({n})" oder 2 bis Maximum | Auto — aufgerundetes log₂ der Feldgröße, mindestens 2 | Maximum = Teams − 1, höchstens 9 | Auto wird beim Anlegen in eine feste Zahl aufgelöst, damit ein späterer Rückzug das Turnier nicht verkürzt | Wie viele Runden gespielt werden — je mehr, desto klarer die Rangfolge | "Auto — Enough rounds that only one team can stay unbeaten — log₂ of the field, rounded up." (Beispiel: "{teams} teams → {rounds} rounds") · "Fewer rounds — Quicker, but more teams finish level and the tiebreak decides more places." (Beispiel: "Good for a short evening session.") · "More rounds — Separates the field further. Every extra round is another slot on the clock." (Beispiel: "Maximum here: {max} rounds — beyond that a rematch is unavoidable.") · bei ungerader Teamzahl zusätzlich: "Odd number of teams — One team sits out each round. The bye rotates." (Beispiel: "Nobody sits out twice before everyone has once.") |
| Generation | "Random" / "Seeded" | Random | — | "Seeded" ausgegraut (noch nicht ausgeliefert) | Wie die erste Runde gepaart wird | — |

## 4.2 Weiter unten auf der Seite

Schedule Preview (0.1) — die Runden stehen mit exakten Zeiten, aber ohne Paarungen
da, weil Swiss erst nach der Vorrunde paart. Pace alerts (0.4), Teams-Roster (0.5),
Name und Create (0.6).

**Create ist möglich, wenn:** Name nicht leer, Teams ≥ 2, Roster vollständig.

---

# 5 · Setting up a Social Scramble

`lib/pages/scramble_setup_page.dart` — Titel in der App: **Social Scramble**.
Feste Rundenzeiten, nach jeder Runde werden die Teams neu gemischt. Einzelanmeldung,
also Spieler statt Teams. Kein Game-Format-Sheet: hier läuft die Uhr, nicht die Punktzahl.

## 5.1 Tournament Setup

| Einstellung | Werte / Presets | Default | Grenzen | Bedingungen & Warnungen | Wofür | Hilfetext in der App (wörtlich) |
|---|---|---|---|---|---|---|
| Target Players | Zahlenfeld, Presets 4, 6, 8, 10, 12, 16, 20, 24 | 8 | 4 bis 64 | — | Geplante Teilnehmerzahl; Grundlage für Spielplan und Rotation | "How many players will take part in the session. Used to plan the schedule and rotations. The actual participants are added in the Players section below." |
| Courts | Zahlenfeld, Presets 1, 2, 3, 4, 5, 6, 8 | 1 | 1 bis 32 | Warnung, wenn die Spielerzahl die Felder nicht füllt: "Only {active} of {courts} courts can be filled with {players} players in {perTeam}v{perTeam}. Reduce courts to {active} or add more players." | Wie viele Partien gleichzeitig laufen | "Number of courts available for play. More courts allow more simultaneous matches but require more players active at once." |
| Style | 2vs2 bis 6vs6 | 2vs2 | 2 bis 6 je Seite | Warnung, wenn kein Feld besetzt werden kann: "At least {n} players are needed for one {perTeam}v{perTeam} court. Add more players or switch to a smaller format." | Mannschaftsgröße je Seite | — |
| Rounds | Zahlenfeld, Presets 6, 8, 10, 12, 16, 20, 24, 30 | 12 | 1 bis 999 | Löst die Vorschläge unter der Vorschau aus (Abdeckung, gleiche Spielanteile) | Wie oft neu gemischt wird | "How many rounds to play. The suggestions below help balance fresh partnerships against the total round count." |
| Match Duration | Zahlenfeld, Presets 5, 8, 10, 12, 15, 20, 25, 30 (Einheit min) | 4 min | 1 bis 999 min | muss größer als 0 sein, sonst kein Create | Wie lange eine Runde gespielt wird | "How long each individual match lasts. Longer matches mean fewer rounds but more play time per match." |
| Break Between Rounds | Zahlenfeld, Presets 0, 2, 3, 5, 7, 10 (Einheit min) | 1 min | 0 bis 999 min | 0 heißt durchspielen ohne Pause | Zeit zum Wechseln und Durchatmen zwischen den Runden | "Rest time between rounds. Allows players to rotate, catch their breath, and reset before the next round starts. Set to 0 for back-to-back play." |

## 5.2 Suggestions — was die Seite von sich aus meldet

Erscheint als eigener Abschnitt unter der Vorschau, nur wenn es etwas zu sagen gibt.
Einige Vorschläge haben einen Übernehmen-Button ("Use {target} rounds").

| Fall | Meldung in der App (wörtlich) | Blockiert Create |
|---|---|---|
| Zu wenige Runden | "At least 1 round is needed to build a schedule." | ja |
| Runde ohne Dauer | "Match and break duration must be greater than zero." | ja |
| Feld zu klein für ein Court | "At least {n} players are needed for one {perTeam}v{perTeam} court. Add more players or switch to a smaller format." | ja |
| Sehr großes Feld | "With {n} players the mixing becomes statistical — everyone-against-everyone is no longer guaranteed, but equal play time still is. This works well for large events." | nein |
| Ungleiche Spielanteile | "Uneven play at {rounds} rounds. Use a multiple of {unit} for equal games." | nein |
| Viele sitzen aus | "{sitting} of {players} sit out each round. Full coverage needs {target} rounds; with fewer, some pairs won't partner." | nein |
| Partner-Abdeckung erreichbar | "No repeat partners at {rounds} rounds. {target} rounds lets everyone partner with everyone." bzw. "Some partnerships repeat. {target} rounds lets everyone partner with everyone." | nein |
| Felder nicht füllbar | "Only {active} of {courts} courts can be filled with {players} players in {perTeam}v{perTeam}. Reduce courts to {active} or add more players." | nein |
| Zu wenige Aussetzer für Schiris | "With {players} players filling {active} courts in {perTeam}v{perTeam}, only {sitting} players sit out each round — {without} courts won't have a dedicated referee and will need scores entered manually." | nein |

## 5.3 Weiter unten auf der Seite

Schedule Preview mit Startzeit ("Start: Now" bis eine Zeit gewählt wird),
"Predicted end: {time}" und der Zeile "Round duration: {n}m match + {n}m break = {n}m".
Pace alerts (0.4), Players-Roster (0.5) inklusive "Fill {count} random",
Name und Create (0.6).

**Create ist möglich, wenn:** Name nicht leer, Match Duration > 0, Rounds > 0 und
genau so viele Spieler hinzugefügt wie geplant.

---

# 6 · Setting up a Royal Rotation

`lib/pages/scramble_king_setup_page.dart` — Titel in der App: **Scramble King**.
King of the Court mit Partner: Der Pool wird je Runde auf die Felder verteilt,
innerhalb eines Feldes läuft eine eigene Warteschlange.

## 6.1 Tournament Setup

| Einstellung | Werte / Presets | Default | Grenzen | Bedingungen & Warnungen | Wofür | Hilfetext in der App (wörtlich) |
|---|---|---|---|---|---|---|
| Target Players | Zahlenfeld, Presets 8, 12, 16, 20, 24, 32, 48 | 16 | 2 × Seitengröße (2vs2: 4) bis 128; baubar erst ab Feldboden 3 × Seitengröße, unter Auto-Allplay 4 × Seitengröße + 1 | — | Geplante Teilnehmerzahl; steuert Zufalls-Auffüllen und die Plausibilitätsprüfung | "How many players you plan to have. Used to size the 'fill random' quick-add and to check your court/round settings make sense." |
| Courts | Zahlenfeld, Presets 1, 2, 3, 4, 5, 6, 8 | 2 | 1 bis 8 | — | Wie viele unabhängige Warteschlangen gleichzeitig laufen | "How many courts run at once, each with its own independent King of the Court queue for the round." |
| Style | 2vs2 bis 6vs6 | 2vs2 | 2 bis 6 je Seite | Eine Größe bleibt sichtbar, wird aber unwählbar, sobald das geplante Feld keine zwei vollen Seiten stellt. Fußnote nur am Limit: "{n}vs{n} is the largest {players} players can fill" | Mannschaftsgröße je Seite | "The format of each game — 2vs2, 3vs3, and so on. Sets how many players make up each team on court." |
| Rounds | Zahlenfeld, Presets 3, 4, 5, 6, 8, 10, 12 | 6 | 1 bis 999 | — | Wie oft der ganze Pool neu auf Felder und Teams gemischt wird | "How many times the whole player pool gets mixed into new courts and teams." |
| Match Duration | Zahlenfeld, Presets 8, 10, 12, 15, 20, 25, 30 (min) | 12 min | 1 bis 999 min | muss größer als 0 sein | Wie lange eine Runde läuft, bevor neu gemischt wird | "How long each round runs before everyone is reshuffled into new courts and teams." |
| Break Between Rounds | Zahlenfeld, Presets 0, 2, 3, 5, 7, 10 (min) | 2 min | 0 bis 999 min | — | Pause zwischen den Runden | — |
| Strike Points | Zahlenfeld, Presets 0, 3, 5, 7, 10, 15, 21 | 5 | 0 bis 999 | 0 schaltet die automatische Ablösung ab | Punktzahl, mit der ein Team das Spiel gewinnt und das Feld als Sieger verlässt | "Points a team must score to win the game and be ejected as winners. Set to 0 to disable — teams stay on court until the coach manually ejects them." |
| Odd player handling | "Placeholder" / "Jumper" | Placeholder | — | "Jumper" ist erst ab 4 × Seitengröße + 1 Spielern wählbar (2vs2: 9). Fußnote sonst: "Jumper needs {count}+ players; with fewer the queue can loop unfairly, so Placeholder is used." | Wie der Spieler behandelt wird, für den kein Partner übrig bleibt | "When a court can't be split evenly into teams of two, one player gets their own team and queues like everyone else — only their partner is decided by this setting. Placeholder picks a random free player the first time they take the court, then keeps that same partner for the rest of the round. Jumper re-picks a partner every time, using a fairness calculation so playing time stays balanced across the round. Either way, the odd player's own team earns the points, just like every other team." |
| Assignment | "Manual" / "Automated" / "Auto-Allplay" | Manual | — | Der Modus hebt den Spielerboden je Feld: Manual und Automated brauchen 3 × Seitengröße, Auto-Allplay 4 × Seitengröße + 1. Fußnote nur bei Unterdeckung: "{mode} needs at least {count} players per court." | Wie das nächste Team aufs Feld kommt | "How the next court team is chosen. Manual — the coach selects players from the queue by tapping them. Automated — TournaQ suggests the best team, prioritising players who have waited longest and haven't been paired together recently. The coach can re-roll before confirming. Automated — All Play — like Automated but no dedicated coach. A rotating referee keeps score while everyone else plays. TournaQ picks a random starting referee and suggests the next handoff from the ejected team after each game." |
| Auto-eject challenger | Zahlenfeld, Presets 0, 1, 2, 3 | 0 (aus) | 0 bis 3 | 0 schaltet es ab; manuelles Ablösen bleibt immer möglich | Fordert zum Auswechseln des Herausforderer-Teams auf, sobald es so viele Punkte kassiert hat | "Prompts you to eject the challenger team once the on-court team scores this many points against them. With automatic assignment, confirming brings the next team on; with manual assignment you eject them yourself. 0 keeps it off — you can still eject by hand anytime." |

## 6.2 Weiter unten auf der Seite

Schedule Preview (Startzeit, voraussichtliches Ende, Rundendauer, Feldgrößen),
Suggestions (siehe 7.2 — dieselbe Prüfung wie bei King of the Court, plus die
Abdeckungsschätzung), Pace alerts (0.4), Players-Roster (0.5), Name und Create (0.6).

**Create ist möglich, wenn:** Name nicht leer, Match Duration > 0, Rounds > 0,
Roster vollständig und der Plan baubar — jedes gewünschte Feld muss seinen
Spielerboden bekommen.

---

# 7 · Setting up a King of the Court

`lib/pages/kotc_queue_setup_page.dart` — Titel in der App: **King of the Court**.
Einzelanmeldung, Warteschlange je Feld, Partner werden live gebildet.

## 7.1 Tournament Setup

| Einstellung | Werte / Presets | Default | Grenzen | Bedingungen & Warnungen | Wofür | Hilfetext in der App (wörtlich) |
|---|---|---|---|---|---|---|
| Target Players | Zahlenfeld, Presets 6, 8, 12, 16, 20, 24, 32 | 12 | 1 bis 128 | Beim Unterschreiten des Modus-Bodens Fußnote: "Auto-Allplay works with fewer players, but rotation may feel clunky below {count} players." | Geplante Teilnehmerzahl; steuert Zufalls-Auffüllen und die Plausibilitätsprüfung | "How many players you plan to have. Used to size the 'fill random' quick-add and to check your court/round settings make sense." |
| Courts | Zahlenfeld, Presets 1, 2, 3, 4, 5, 6, 8 | 2 | 1 bis 8 | Blockierende Meldung, wenn der Pool die Felder nicht füllt | Wie viele unabhängige Warteschlangen gleichzeitig laufen | "How many courts run at once, each with its own independent King of the Court queue for the round." |
| Style | 2vs2 bis 6vs6 | 2vs2 | 2 bis 6 je Seite | Hebt den Spielerboden je Feld; die geplante Spielerzahl bleibt stehen und wird nur neu geprüft | Mannschaftsgröße je Seite | "The format of each game — 2vs2, 3vs3, and so on. Sets how many players make up each team on court." |
| Rounds | Zahlenfeld, Presets 2, 3, 4, 5, 6, 8, 10 | 4 | 1 bis 999 | — | Wie oft der ganze Pool neu auf Felder verteilt wird | "How many times the whole player pool gets mixed into new courts and teams." |
| Match Duration | Zahlenfeld, Presets 8, 10, 12, 15, 20, 25, 30 (min) | 12 min | 1 bis 999 min | muss größer als 0 sein | Wie lange eine Runde läuft, bevor neu gemischt wird | "How long each round runs before everyone is reshuffled into new courts and teams." |
| Break Between Rounds | Zahlenfeld, Presets 0, 2, 3, 5, 7, 10 (min) | 2 min | 0 bis 999 min | — | Pause zwischen den Runden | — |
| Strike Points | Zahlenfeld, Presets 0, 3, 5, 7, 10, 15, 21 | 5 | 0 bis 999 | 0 schaltet die automatische Ablösung ab | Punktzahl, mit der ein Team gewinnt und das Feld als Sieger verlässt | "Points a team must score to win the game and be ejected as winners. Set to 0 to disable — teams stay on court until the coach manually ejects them." |
| Assignment | "Manual" / "Automated" / "Auto-Allplay" | Automated | — | Boden je Feld: Manual und Automated 3 × Seitengröße, Auto-Allplay 4 × Seitengröße + 1. Fußnote nur bei Unterdeckung: "{mode} needs at least {count} players per court." | Wie das nächste Team aufs Feld kommt | "How the next court team is chosen. Manual — the coach selects players from the queue by tapping them. Automated — TournaQ suggests the best team, prioritising players who have waited longest and haven't been paired together recently. The coach can re-roll before confirming. Automated — All Play — like Automated but no dedicated coach. A rotating referee keeps score while everyone else plays. TournaQ picks a random starting referee and suggests the next handoff from the ejected team after each game." |
| Auto-eject challenger | Zahlenfeld, Presets 0, 1, 2, 3 | 0 (aus) | 0 bis 3 | 0 schaltet es ab; manuelles Ablösen bleibt möglich | Fordert zum Auswechseln des Herausforderer-Teams auf, sobald es so viele Punkte kassiert hat | "Prompts you to eject the challenger team once the on-court team scores this many points against them. With automatic assignment, confirming brings the next team on; with manual assignment you eject them yourself. 0 keeps it off — you can still eject by hand anytime." |

## 7.2 Suggestions — was die Seite von sich aus meldet

Gilt gleichermaßen für King of the Court, Royal Shuffle und Royal Rotation.

| Fall | Meldung in der App (wörtlich) | Blockiert Create |
|---|---|---|
| Zu wenige Runden | "At least 1 round is needed." | ja |
| Runde ohne Dauer | "Round duration must be greater than zero." | ja |
| Pool zu klein für ein Feld | "At least {min} players are needed for one court." | ja |
| Pool zu klein für alle Felder | "{courts} courts need {needed} players at {min} each — you have {players}. Add players, use fewer courts, or switch off Auto All-Play." | ja |
| Feld ohne Warteschlange | "A court has no waiting queue, so challenger rotation can't happen there. Add players for {min} per court." bzw. ohne Auto-Eject: "A court has no waiting queue. The same players stay on court all round. Add players for {min} per court." | nein |
| Volle Abdeckung erreicht | "At {rounds} rounds every player shares a court with all {total} others." | nein |
| Abdeckung ausbaufähig | "At {rounds} rounds each player shares a court with about {met} of the other {total}. {target} rounds makes it about {more}." (mit Button "Use {target} rounds") | nein |
| Frische Partner | "No repeat partners at {rounds} rounds." bzw. "Fresh partners for at least the first {promised} rounds." | nein |

## 7.3 Weiter unten auf der Seite

Schedule Preview (Startzeit, voraussichtliches Ende, "Round duration", "Rounds",
"Scheduled duration"), Suggestions, Pace alerts (0.4), Players-Roster (0.5),
Name und Create (0.6).

**Create ist möglich, wenn:** Name nicht leer, Match Duration > 0, Rounds > 0,
Roster vollständig und der Plan baubar.

---

# 8 · Setting up a Royal Shuffle

`lib/pages/doghouse_queue_setup_page.dart` — Titel in der App: **Doghouse**.
Wie King of the Court, aber mit dem Doghouse-Zyklus: Das Team im Doghouse
punktet nur beim eigenen Aufschlaggewinn und muss sich herausspielen.

## 8.1 Tournament Setup

| Einstellung | Werte / Presets | Default | Grenzen | Bedingungen & Warnungen | Wofür | Hilfetext in der App (wörtlich) |
|---|---|---|---|---|---|---|
| Target Players | Zahlenfeld, Presets 6, 8, 12, 16, 20, 24, 32 | 12 | 1 bis 128 | Fußnote unter dem Modus-Boden: "Auto-Allplay works with fewer players, but rotation may feel clunky below {count} players." | Geplante Teilnehmerzahl | "How many players you plan to have. Used to size the 'fill random' quick-add and to check your court/round settings make sense." |
| Courts | Zahlenfeld, Presets 1, 2, 3, 4, 5, 6, 8 | 2 | 1 bis 8 | Blockierende Meldung, wenn der Pool die Felder nicht füllt | Wie viele unabhängige Warteschlangen gleichzeitig laufen | "How many courts run at once, each with its own independent King of the Court queue for the round." |
| Style | 2vs2 bis 6vs6 | 2vs2 | 2 bis 6 je Seite | Hebt den Spielerboden je Feld | Mannschaftsgröße je Seite | "The format of each game — 2vs2, 3vs3, and so on. Sets how many players make up each team on court." |
| Rounds | Zahlenfeld, Presets 2, 3, 4, 5, 6, 8, 10 | 4 | 1 bis 999 | — | Wie oft der ganze Pool neu verteilt wird | "How many times the whole player pool gets mixed into new courts and teams." |
| Match Duration | Zahlenfeld, Presets 8, 10, 12, 15, 20, 25, 30 (min) | 12 min | 1 bis 999 min | muss größer als 0 sein | Wie lange eine Runde läuft | "How long each round runs before everyone is reshuffled into new courts and teams." |
| Break Between Rounds | Zahlenfeld, Presets 0, 2, 3, 5, 7, 10 (min) | 2 min | 0 bis 999 min | — | Pause zwischen den Runden | — |
| Escape Points | Zahlenfeld, Presets 0, 2, 3, 4, 5, 7 | 3 | 0 bis 999 | 0 schaltet das automatische Entkommen ab | Punkte, die das Doghouse-Team zum Entkommen braucht | "Points the doghouse team must score to escape. A point is earned each time the serving (doghouse) team wins a rally. The score resets to zero after each game lost." |
| Loss Limit | Zahlenfeld, Presets 0, 2, 3, 4, 5 | 3 | 0 bis 999 | 0 schaltet die automatische Ablösung ab | Wie viele Spiele das Doghouse-Team verlieren darf, bevor es ausgewechselt wird | "How many games the doghouse team can lose before being automatically ejected. Each time the court team wins a rally, one game is lost and the point score resets to zero." |
| Assignment | "Manual" / "Automated" / "Auto-Allplay" | Automated | — | Boden je Feld: Manual und Automated 3 × Seitengröße, Auto-Allplay 4 × Seitengröße + 1. Fußnote bei Unterdeckung: "{mode} needs at least {count} players per court." | Wie das nächste Team aufs Feld kommt | "How the next court team is chosen. Manual — the coach selects players from the queue by tapping them. Automated — TournaQ suggests the best team, prioritising players who have waited longest and haven't been paired together recently. The coach can re-roll before confirming. Automated — All Play — like Automated but no dedicated coach. A rotating referee keeps score while everyone else plays. TournaQ picks a random starting referee and suggests the next handoff from the ejected team after each game." |
| Auto-eject challenger | Zahlenfeld, Presets 0, 1, 2, 3 | 0 (aus) | 0 bis 3 | 0 schaltet es ab | Fordert zum Auswechseln des Herausforderer-Teams auf, sobald es so viele Punkte kassiert hat | "Prompts you to eject the challenger team once the on-court team scores this many points against them. With automatic assignment, confirming brings the next team on; with manual assignment you eject them yourself. 0 keeps it off — you can still eject by hand anytime." |

## 8.2 Weiter unten auf der Seite

Schedule Preview, Suggestions (siehe 7.2), Pace alerts (0.4), Players-Roster (0.5),
Name und Create (0.6).

**Create ist möglich, wenn:** Name nicht leer, Match Duration > 0, Rounds > 0,
Roster vollständig und der Plan baubar.

---

# 9 · Was nicht auf einer Setup-Seite steht

- **Quick Game** hat keine Setup-Seite. Zielpunktzahl und Seitenwechsel werden direkt
  auf dem Scoreboard gewählt (`lib/scoring/quick_game_adapter.dart`). Die Guide-Seite
  „Setting up a Quick Game" beschreibt also einen anderen Ablauf als die acht hier.
- **Ranking-Methode und Strict-Modus** der Queue-Modi werden bewusst nicht im Setup
  gesetzt, sondern erst im laufenden Turnier auf der Statistikseite.
- **Court-Tiefe** ist bei King of the Court, Royal Shuffle und Royal Rotation kein
  Feld mehr: Sie folgt aus Feldanzahl, Style und Assignment.
- **Seeded** gibt es auf allen vier Bracket-Seiten als sichtbare, aber ausgegraute
  Option — ebenso "Play-in+" bei Elimination.

---

# 10 · Auffälligkeiten beim Durchgehen

Nichts davon ist kaputt, aber alles davon fällt auf, wenn man die Seiten
nebeneinanderlegt — und drei Punkte betreffen direkt, was der Guide behaupten darf.

- **Social Scramble startet außerhalb seiner eigenen Presets.** Match Duration
  ist mit 4 min vorbelegt, die Preset-Liste beginnt bei 5. Break Between Rounds
  steht auf 1 min, die Liste kennt nur 0, 2, 3, 5, 7, 10. Beides ist wählbar,
  taucht aber im Dropdown nicht auf.
- **Zwei Namenswelten.** Guide: Royal Rotation, Royal Shuffle, TournaQ Classic.
  App: Scramble King, Doghouse, Group + Knockout.
- **„Seeding" heißt im Feld „Generation"** — auf allen vier Bracket-Seiten. Der
  Guide spricht durchgehend von Seeding.
- **Seeded ist überall sichtbar, aber nirgends wählbar.** Gleiches gilt für
  "Play-in+" bei Elimination. Der Guide sollte Seeding also als „entscheidet, wer
  auf wen trifft" beschreiben, ohne zu versprechen, dass man es heute schon setzen kann.
- **Referees ist die stillste wichtige Einstellung.** Sie steht auf allen vier
  Bracket-Seiten, ist aber nur in der Unterdeckung überhaupt umschaltbar — und
  genau dann rechnet die Fußnote vor, was sie an Zeit kostet.
- **Die Player-Pool-Modi haben kein Spielformat.** Sätze, Zielpunktzahl und
  Seitenwechsel gibt es dort nicht; es zählt die Rundenuhr plus die
  modeeigene Punktgrenze (Strike Points bzw. Escape Points und Loss Limit).
