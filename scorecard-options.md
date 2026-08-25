# TournaQ — Scorecards: alle Bedienelemente

Was jede Scorecard bietet — Widget für Widget, mit Bedingungen und den Texten
wörtlich aus der App (`~/Projects/tournaq`, Branch `main`, Stand 2026-08-23).

**Steht auch im User Guide selbst**: jede „Scoring a …“-Seite in `pages/guide.html`
(Keys `m-*-score`, `quick-game-score`) trägt ihre Tabelle als `opts`-Block, die drei
Kartentypen liegen auf `sc-classic`, `sc-scramble` und `sc-queue`, die geliehene Karte
auf `exported`. Dritte Datei der Reihe neben `setup-options.md` und
`tournament-options.md`; `tools/export-options.py` baut aus allen dreien die CSVs.

Deutsche Spalten und Zwischentexte sind Beschreibung; alles in `"…"` ist der
englische App-String im Original.

## Drei Karten, nicht acht

| Karte | Datei | Benutzt von |
|---|---|---|
| Classic — Sätze, Zielpunktzahl, Seitenwechsel | `lib/pages/ko_bracket_match_page.dart` | League, Elimination (single und double), TournaQ Classic, Swiss System |
| Classic, geteilte Fassung | `lib/scoring/live_scoring_page.dart` über `lib/pages/score_page.dart` | Quick Game |
| Scramble — Rundenuhr statt Sätzen | `lib/pages/scramble_scorecard_page.dart` | Social Scramble |
| Queue — Court plus Warteschlange | `lib/pages/kotc_queue_court_page.dart`, `doghouse_queue_court_page.dart`, `scramble_king_court_page.dart` | King of the Court, Royal Shuffle, Royal Rotation |

> **Korrektur zur bisherigen Guide-Fassung:** Royal Rotation (App: Scramble King)
> lief dort unter „Scramble scorecard“. Die Seite ist aber eine Queue-Court-Seite —
> mit Court, Challengers, Up Next, Eject und Finish court — nur mit Paaren in der
> Schlange statt Einzelspielern. Im Guide ist das jetzt richtig zugeordnet.

---

# 1 · Classic Scorecard

Gemeinsam für League, Elimination, TournaQ Classic und Swiss.

| Bedienelement | Was es tut | Wann sichtbar / Bedingung | Text in der App (wörtlich) |
|---|---|---|---|
| Punkte-Buttons | Plus gibt der Seite den Punkt, Minus nimmt ihn zurück. Aufschlag wechselt automatisch zu der Seite, die gerade gepunktet hat; die Rotation rückt einen Platz weiter | Bis Satz oder Match abgeschlossen ist — danach ausgegraut | — |
| Serves-first-Banner | Wer den Aufschlag hat, bevor der erste Punkt fällt | Bis zum ersten Punkt; im Querformat aus Platzgründen weggelassen | — |
| Satzübersicht | Eine Karte je Satz mit Stand; Tippen macht den Satz zum aktiven | Formate mit mehr als einem Satz | "Set {n} · to {target}" |
| Seitenwechsel-Erinnerung | Dialog am Wechselpunkt, danach tauschen die Zähler mit | Wenn das Format ein Seitenwechsel-Intervall hat | "Side Change" · "Total score is {score}. Teams must switch sides now." · "Sides Switched — Continue" |
| Zielpunkt-Abfrage | Fragt, ob der Satz gewonnen ist | Beim Erreichen der Zielpunktzahl, solange „Notify at target score“ an ist | "{team} reached the target. Set {set} is won." · "Complete Set" / "Complete Game" · "Keep Playing" |
| Match Options | Drei Einträge hinter dem Regler-Icon | Immer | "Swap Sides — Switch left and right display" · "Change Service — Advance to next server" · "Match History — View point-by-point history" |
| Match History | Ballwechsel für Ballwechsel, nach Sätzen gruppiert | Aus den Match Options | "Match History" · "Set {n} · to {target}" · "Final: {s1} – {s2}" · leer: "No scoring history yet" |
| Schedule-Karte | Geplanter Start und geplantes Ende dieser Partie | Nur wenn Pace alerts für das Event an sind | "Planned start" · "Planned end" · "Over schedule!" · Status "Upcoming" / "Due" / "Overdue" / "Completed" |
| Schiri-Banner | Vorschlag oder Aufforderung | Wenn das Event Schiris stellt | "{name} suggested as referee" · "Assign a referee manually" |
| Match Controls | Start, Satz, Match, zurück | Unten auf der Karte | "Start Match" · "Complete Set" / "Undo Set Completion" · "Complete Game" / "Undo Game Completion" · "Back to Schedule" |
| Sperr-Banner | Legt die Punkte-Buttons still | Sobald ein Satz oder das Match fertig ist | "Match complete" (mit Sieger) · "Set complete — undo set to edit score" |
| QR-Menü in der Titelzeile | Karte weitergeben oder Ergebnis von Hand setzen | Nur bei 0–0 und wieder nach Abschluss — mitten im Match ausgeblendet | "Export scorecard" · "Manually Set Score" · Hilfetext: "Use this when the game was played without live scoring. Enter the final score for both sides and complete the game." |
| Pill-Row | Match-Kontext plus die Event-Einstellungen | Unter dem Titel. Alle Event-Einstellungen sind hier gesperrt; das Roster ist die Ausnahme, es schreibt über denselben Adapter wie der Punktestand | Kontext-Pills: Name, Position, Court, "{n} sets", "{n} pts", Dauer |
| Querformat | Dieselben Bedienelemente, neu angeordnet für Netzpfosten oder Beistelltisch | Jederzeit | — |

## 1.1 Was pro Modus dazukommt

| Modus | Besonderheit | Text in der App (wörtlich) |
|---|---|---|
| League | Position ist schlicht Runde und Match, weil es keinen Baum gibt, aus dem sich eine Position lesen ließe | "Round {n} · Match {m}" |
| Elimination | Schutz, wenn die Folgepartie schon läuft: der Sieger steht fest, die Punkte bleiben korrigierbar | "Winner can't change" · "The next match has already started, so the winner of this match can't change. You can still correct the points as long as the same team wins." |
| Swiss | Der Abschluss der letzten Partie einer Runde paart die nächste sofort — die Scorecard führt den Reconcile selbst aus, nicht erst die Rundenseite | — |
| TournaQ Classic | Position nennt Phase und Tier | — |
| Quick Game | Zielpunktzahl und Seitenwechsel sind Dropdowns auf der Karte selbst, weil es kein Turnier gibt, von dem sie geerbt würden. Optionen heißen „Swap Teams“, Abschluss ist „Save & Return to Games“. Tippen auf einen Teamnamen öffnet die Aufstellung | "Target score:" · "Side swap" / "No side swap" · "Custom…" · "Swap Teams — Switch left and right sides" · "Save & Return to Games" |

---

# 2 · Scramble Scorecard

Social Scramble. Kein Satz, keine Zielpunktzahl — die Uhr beendet die Runde.

| Bedienelement | Was es tut | Wann sichtbar / Bedingung | Text in der App (wörtlich) |
|---|---|---|---|
| Rundenuhr | Countdown der Runde, mit Anhalten, Fortsetzen und Neustart. Eine Pause friert die Restzeit ein und speichert sie, damit das Verlassen der Seite die Uhr nicht kostet | Immer | "Stop" · "Resume" · "Start" / "Restart" |
| Punkte-Buttons | Plus und Minus je Seite, Aufschlag wechselt automatisch | Immer | — |
| Serves-first-Banner | Wer die Runde aufschlägt | Bis zum ersten Punkt | — |
| Schiri-Banner | Wer pfeift, oder die Aufforderung, jemanden zu bestimmen | Wenn dieser Court einen Schiri-Platz hat | "{name} refs" · "Assign a referee manually" |
| Spieler-Pills | Tippen schickt jemanden in die Pause; der Platz wird ein Platzhalter. Tippen auf den Platzhalter holt zurück | Solange eine spätere Runde zum Zurückkommen bleibt; auf einer importierten Karte nicht angeboten | "{name} is on a break — their seat is a Placeholder." · "{name} is back in the rotation." · "No round left to sit out." |
| Upcoming Games | Die nächsten Partien, nach Runden gruppiert, je mit Schiri | Unter der Karte | "{count} courts — played in parallel" · "{name} refs" |
| QR-Menü | Karte weitergeben oder Ergebnis von Hand setzen | Solange das Board live ist | "Export scorecard" / "Export result" · "Manually Set Score" |
| Pill-Row | Name (bearbeitbar — ein Name formt nichts um), Runde, Court, Format, Rounds, Courts | Die drei Format-Pills sind nur auf einer Ein-Court-Session bearbeitbar, sonst gesperrt | "Format" · "Rounds" · "Courts" · "Est. finish: {time}" / "Finished: {time}" |
| Zurück | Zur Übersicht bzw. zum Hub | Unten auf der Karte | "Back to Schedule" · "Back to Hub" |

---

# 3 · Queue Scorecard

King of the Court, Royal Shuffle und Royal Rotation. Halb Scorecard, halb Warteliste.

| Bedienelement | Was es tut | Wann sichtbar / Bedingung | Text in der App (wörtlich) |
|---|---|---|---|
| Court | Wer gerade hält, und die Punkte dieser Runde | Immer | "Court" |
| Challengers | Die Seite, die als Nächste drankommt | Immer | "Challengers" · "Waiting for players..." |
| Up Next | Die Stufe dahinter, mit Neuauslosung | Automatische Zuteilung | "Up Next" · "Re-roll" · "Not enough players in queue." |
| Punkte-Buttons | Zählt, was die Seite auf dem Court macht | Immer | — |
| Session-Timer | Countdown der Runde | Immer | "SESSION TIMER" · "Stop" · "Resume" · "Start" / "Restart" |
| Eject | Schickt die Seite runter und holt die nächste hoch | Immer — manuelles Ablösen bleibt möglich, unabhängig von den automatischen Schwellen | "Eject" · "Eject / Challenger" |
| Automatische Eject-Prompts | Melden Sieg, Entkommen oder Rauswurf und lösen ab | Nur wenn die jeweilige Schwelle über 0 steht | King of the Court: "Game Won!" · "{names} reached {points} points!" · "They will be ejected and return to the queue." · "Eject Team" — Royal Shuffle zusätzlich: "Escaped!" und "Ejected!" · "{names} lost {count} games!" · "They are ejected from the doghouse and return to the queue." |
| Undo | Nimmt den letzten Schritt zurück | Nach einer Ablösung und während einer manuellen Auswahl; mit Punkten auf dem Board erst nach Rückfrage | "Undo" · "Discard recorded points?" · "The team currently on court has {points} point(s) recorded. Undoing will discard them." · "Discard and undo" |
| Schiri wechseln | Übergibt das Zählen an jemand anderen | Auto-Allplay | "Change referee" · "Select who referees this court. The current one returns to the queue." · "NEXT REFEREE" · "Suggested from the current court team." |
| Spieler-Pills | Pause und Rückkehr, wie auf der Scramble-Karte | Solange eine spätere Runde bleibt | wie oben |
| Court starten / beenden | Startet den Court, schließt ihn ab, macht das rückgängig | Unten auf der Karte | "Start Court" · "Finish court" · "Finish this court?" · "Record this court's results now and end its round." · "Undo Finish" · "This court's round is complete" |
| QR-Menü | Ganzen Court weitergeben oder Ergebnisse von Hand setzen | Solange der Court live ist | "Export court" / "Export result" · "Manually Set Score" |
| Tabelle unter der Karte | Wins, Punkte und Ranking-Punkte je Spieler bzw. Team auf diesem Court | Immer | "Wins" · "Pts" · "RP" · Royal Rotation zusätzlich "Teams" und "Games" |
| Pill-Row | Dieselben Pills wie die Turnierseite, plus Runde und Court | Format-Pills nur auf einer Ein-Court-Session bearbeitbar, sonst gesperrt | "Round {n}" · "Court {n}" |

## 3.1 Was pro Modus dazukommt

| Modus | Besonderheit | Text in der App (wörtlich) |
|---|---|---|
| King of the Court | Strike Points beenden den Halt | "{n} pt strike" · "Auto-eject @ {n}" / "Auto-eject off" |
| Royal Shuffle | Zwei Schwellen statt einer: Entkommen und Verlustgrenze | "{count} pt escape" · "{count} loss limit" |
| Royal Rotation | Paare statt Einzelspieler in der Schlange, dazu ein Partnerwähler für den überzähligen Spieler | "Pick a partner for the floater" · "Teams" · Odd-Player-Modus "Placeholder" / "Jumper" |

---

# 4 · Die geliehene Karte

Was sich ändert, wenn eine Scorecard per QR auf einem fremden Gerät läuft.

| Bedienelement | Was es tut | Wann sichtbar / Bedingung | Text in der App (wörtlich) |
|---|---|---|---|
| Speicherung | Alles bleibt auf dem fremden Gerät, bis das Ergebnis-QR zurückgescannt wird — der Host-Speicher wird nie berührt | Immer | — |
| "Export result" | Tritt an die Stelle von "Export scorecard" und verweigert vorzeitig | Erst nach Abschluss | "Export result" · "Finish the match before exporting the result." |
| Echte Position | Die Karte trägt die Runde des Hosts, nicht die des empfangenden Geräts | Unter dem Titel | z. B. "Quarter-final · Match 3" statt "Final · Match 1" |
| Read-only Event | Name und Roster gehören dem Host und werden nur genannt; jede andere Einstellung ist gesperrt | Pill-Row | "Not from here" · "This belongs to the tournament, not to one game." |
| Eingefrorene Vorschau | Die Upcoming-Liste ist ein Stand vom Moment des Teilens | Scramble- und Queue-Karten | "Snapshot from when this was shared — the schedule may have changed since." · "For other games, see the host device." |
| Rückweg | Kein Spielplan darunter, also zurück zum Hub | Unten auf der Karte | "Back to Hub" |
| Rückscannen beim Host | Das Ergebnis landet auf der richtigen Partie, weil der Code seine Match-ID trägt | Turnierseite | "Result imported." · "This QR code is not a result." · "This result is for a different tournament." |

---

# 5 · Auffälligkeiten beim Durchgehen

- **Zwei Namen für dieselbe Geste:** Die Turnier-Scorecard sagt „Swap Sides“, Quick Game
  sagt „Swap Teams“ — dieselbe Funktion, weil Quick Game über die geteilte
  `live_scoring_page.dart` läuft und die Bracket-Karte ihre eigene ist.
- **Die Ein-Court-Regel ist überall dieselbe** und steht in `kotc_queue_court_page.dart`
  in ihrer Urfassung: eine Scorecard darf eine Turniereinstellung nur ändern, wenn die
  Session genau einen Court hat — dann *ist* die Scorecard die Session.
- **Das QR-Menü der Bracket-Karte ist mitten im Match absichtlich weg**, damit niemand
  ein halbes Spiel exportiert. Bei 0–0 und nach Abschluss ist es da.
- **Der Punktestand ist auf 0…999 begrenzt**, auf jeder Karte.
- **Manuelles Ablösen bleibt in den Queue-Modi immer möglich**, auch wenn alle
  automatischen Schwellen auf 0 stehen.
