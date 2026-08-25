# TournaQ — Tournament Page: alle Bedienelemente

Vollständiger Export dessen, was auf der laufenden Turnierseite bedient werden kann
(`~/Projects/tournaq`, Branch `main`, Stand 2026-08-23): jede Pill mit ihrer Aktion,
jede Sperre mit ihrem Grund, dazu QR, Workbook, Umbenennen und die Sheets dahinter.

**Steht auch im User Guide selbst**: jede „Running a …“-Seite in `pages/guide.html`
(Keys `m-*-run`) trägt ihre Pill-Tabelle als `opts`-Block, das Gemeinsame liegt auf
der Seite `tournament-controls`. Schwesterdateien: `setup-options.md` für die
Setup-Seiten, `scorecard-options.md` für die Scorecards.

Deutsche Spalten und Zwischentexte sind Beschreibung; alles in `"…"` ist der
englische App-String im Original (Platzhalter wie `{count}` bleiben stehen).

## Woher das kommt

| Baustein | Datei |
|---|---|
| Was eine Pill ist, und in welcher Reihenfolge sie steht | `lib/widgets/pills/pill_concept.dart` |
| Was ein Tipp auf eine Pill tut — oder warum nicht | `lib/widgets/pills/pill_action.dart` |
| Warum eine Pill gesperrt ist | `lib/widgets/pills/pill_lock_dialog.dart` |
| Welche Pills die Bracket- und Scramble-Modi zeigen | `lib/widgets/pills/event_pills.dart` |
| Die Pills der Queue-Modi | die jeweilige `*_overview_page.dart` |
| QR, Workbook, Ergebnis von Hand | `lib/widgets/tournament_workbook_actions.dart`, `lib/widgets/ko_match_actions.dart` |
| Die Sheets hinter den Pills | `lib/widgets/sheets/` |

## Das Modell in einem Absatz

Jede Pill trägt ein **Concept** (was sie meint), das ihre Reihenfolge und ihre Zeile
festlegt — dieselbe Pill sitzt in jedem Modus an derselben Stelle. Und eine **Action**,
aus der sowohl die Farbe als auch das Glyph am rechten Rand folgen. Vier Zustände:

| Action | Glyph | Farbe | Bedeutung |
|---|---|---|---|
| `context` | keins | grau | Feststellung. Nichts kann diesen Wert ändern, also gibt es nichts zu tippen. |
| `drillIn` | `›` | oliv | Öffnet etwas — Tabelle, Roster, Courtraster, Zeitleiste. |
| `edit` | Stift | oliv | Hier bearbeitbar. Öffnet ein Sheet und schreibt direkt ins Turnier zurück. |
| `locked` | Schloss | oliv | Existiert und ist änderbar — nur nicht hier oder nicht mehr. Der Tipp erklärt, welches von beidem. |

Die Regel dahinter: **getönt heißt, hier lässt sich etwas machen; grau heißt, das ist
nur eine Angabe.** Ein Schloss verspricht ausdrücklich, dass die Einstellung existiert
— eine weggelassene Pill würde behaupten, es gäbe sie nicht.

Die sechs Zeilen (`PillGroup`) in ihrer festen Reihenfolge: Match-Kontext (nur auf der
Scorecard) · Navigation · Roster · Form des Turniers · Spielregeln · Zeit.

## Die drei Sperrgründe

| Grund | Text in der App (wörtlich) | Wann |
|---|---|---|
| `drawStarted` | **"The draw is set"** — "The draw is fixed once a match has started." | Sobald ein Match gestartet oder gespielt wurde. Betrifft Redraw, Adjust draw, Legs, Odd Teams, Format; bei Swiss zusätzlich den Reroll der ersten Runde. Ein Freilos zählt dabei nicht als Ergebnis, ein Walkover schon. |
| `notFromHere` | **"Not from here"** — "This belongs to the tournament, not to one game. Change it in the tournament overview, where it applies to the whole event." | Jede Turniereinstellung, die von einer Scorecard aus gesehen wird. |
| `multiCourt` | **"Locked while multiple courts are running"** — "This session runs on {courts} courts, and every court feeds one shared ranking. Changing the format here would rescore only these players against everyone else's unchanged rules. Change it from the tournament overview instead, where it applies to every court at once. On a single-court session you can edit it right here." | Format-Einstellungen auf einer Scorecard, solange die Session auf mehr als einem Court läuft. |

Bestätigt wird jeder Dialog mit "Got it".

---

# 1 · Die Pills, Modus für Modus

Spalten: **Element** = das Concept · **Beschriftung** = was auf der Pill steht ·
**Aktion** = was ein Tipp tut · **Bearbeitbar hier?** · **Bedingung / Sperrgrund** ·
**Wofür**.

## 1.1 League — `lib/pages/league_table_page.dart`

| Element | Beschriftung in der App | Aktion | Bearbeitbar hier? | Bedingung / Sperrgrund | Wofür |
|---|---|---|---|---|---|
| standings | "Standings" | öffnet die Tabelle | Navigation | — | Der Stand, wie er ist |
| crosstable | "Crosstable" | öffnet das Raster | Navigation | League hat als einziger Modus eine eigene Crosstable-Pill — seine Standings haben keinen Bracket-Tab, über den man ins Raster käme | Wer gegen wen gespielt hat, und wie es ausging |
| allocation | "Allocation" | öffnet das Courtraster | Navigation | — | Welche Partie auf welchem Court liegt |
| teams | "{count} teams" | öffnet das Roster | Navigation, im Sheet dann bearbeitbar | Bearbeiten/Tauschen nur solange die Seite das Roster besitzt; Withdraw nur im laufenden Turnier | Team ändern, tauschen, zurückziehen |
| teamSize | "2v2" | keine | nein — Feststellung | Ändern würde die ganze Auslosung neu mischen, also gibt es dafür nirgends einen Editor | Gegen welche Mannschaftsgröße gezogen wurde |
| courts | "{count} courts" | öffnet das Court-Sheet | ja | Bis nichts mehr umzuplanen ist; nie unter einen Court mit laufendem Match; bis 32 | Netz weg oder Netz dazu, mitten am Tag |
| referees | "Refs covered" bzw. "{gap} without a ref" | öffnet die Schiri-Deckung | ja | Gilt ab der nächsten ungespielten Einheit: "Applies from {unit} — what has been played keeps its courts and times." | Ob die gleich startenden Partien jemanden zum Pfeifen haben |
| seeding | "Random" (bzw. "Seeded") | keine | nein — Feststellung | Seeded ist gebaut, aber nicht ausgeliefert; es gibt also genau einen erreichbaren Wert | „Wie wurde ausgelost?“ ist eine echte Frage |
| legs | "Single" / "Double" | öffnet Bracket generation | ja, bis zum ersten Match | Danach `drawStarted` | Einfache oder doppelte Runde |
| walkovers | "{count} walkovers" | öffnet die Liste | nein — Feststellung | Bei 0 nicht tippbar, bleibt aber stehen, damit die Zeile ihre Form behält | Was ein Rückzug entschieden hat |
| estFinish | "Ends {time}" bzw. "Set schedule" | öffnet die Zeitleiste | Navigation | — | Voraussichtliches Ende, plus Pace alerts |

## 1.2 Elimination — `lib/pages/elimination_bracket_page.dart`

| Element | Beschriftung in der App | Aktion | Bearbeitbar hier? | Bedingung / Sperrgrund | Wofür |
|---|---|---|---|---|---|
| bracketView / standings | "Bracket" (Double) bzw. "Standings" (Single) | öffnet die Ansicht | Navigation | — | Der Baum bzw. die Tabelle |
| allocation | "Allocation" | öffnet das Courtraster | Navigation | — | Welche Partie auf welchem Court liegt |
| teams | "{count} teams" | öffnet das Roster | Navigation, im Sheet bearbeitbar | Withdraw nur im laufenden Turnier | Team ändern, tauschen, zurückziehen |
| teamSize | "2v2" | keine | nein — Feststellung | — | Mannschaftsgröße der Auslosung |
| drawFormat | "Single Elimination" / "Double Elimination" | öffnet die Formatwahl | ja, bis zum ersten Match | Danach `drawStarted` — Umschalten heißt neu auslosen | Ein Leben oder zwei |
| courts | "{count} courts" | öffnet das Court-Sheet | ja | wie League | Wie viele Partien gleichzeitig |
| referees | "Refs covered" / "{gap} without a ref" | öffnet die Schiri-Deckung | ja | ab der nächsten ungespielten Runde | Schiris aus dem Feld |
| seeding | "Random" | keine | nein — Feststellung | — | Wie gezogen wurde |
| reroll | "Redraw" | zieht neu | ja, bis zum ersten Match | Danach `drawStarted` | „Diese Auslosung gefällt mir nicht“ |
| drawAdjust | "Adjust draw" | öffnet den Tauschdialog | ja, bis zum ersten Match | Immer ein Tausch, nie ein einseitiges Verschieben | Zwei Teams von Hand vertauschen |
| oddTeams | "Byes" / "Play-in" / "Play-in+" | öffnet Bracket generation | ja, bis zum ersten Match | Nur Single Elimination — Double nutzt immer Freilose | Wie ein ungerades Feld aufgeht |
| grandFinal | "Single match" / "Bracket reset" | öffnet die Finalwahl | ja, bis das Finale gespielt ist | Nur Double Elimination. Bewusst spät änderbar: man weiß erst, ob man einen Reset will, wenn man sieht, wer im Finale steht | Wie der Titel entschieden wird |
| byes | "{count} byes" | öffnet die Liste | nein — Feststellung | Bei 0 nicht tippbar | Wer eine Runde übersprungen hat |
| walkovers | "{count} walkovers" | öffnet die Liste | nein — Feststellung | Bei 0 nicht tippbar | Was ein Rückzug entschieden hat |
| estFinish | "Ends {time}" | öffnet die Zeitleiste | Navigation | — | Voraussichtliches Ende |

## 1.3 TournaQ Classic — `lib/pages/group_knockout_page.dart`

Wie Elimination, mit diesen Unterschieden: **Standings** statt Bracket, **Legs**
(`"Single"` / `"Double"`) statt Format und Odd Teams, **kein** Grand final, **keine**
Byes-Pill. **Redraw** und **Adjust draw** sind da; „Adjust draw“ verschiebt hier ein
Team zwischen Gruppen — immer im Tausch, weil eine gewachsene Gruppe mehr Spiele,
mehr Slots und ein späteres Ende bekäme.

## 1.4 Swiss System — `lib/pages/swiss_rounds_page.dart`

| Element | Beschriftung in der App | Aktion | Bearbeitbar hier? | Bedingung / Sperrgrund | Wofür |
|---|---|---|---|---|---|
| standings | "Standings" | öffnet die Tabelle | Navigation | — | Woraus die nächste Runde gepaart wird |
| allocation | "Allocation" | öffnet das Courtraster | Navigation | — | Court-Zuordnung |
| teams | "{count} teams" | öffnet das Roster | Navigation, im Sheet bearbeitbar | Withdraw im laufenden Turnier | Roster pflegen |
| teamSize | "2v2" | keine | nein — Feststellung | — | Mannschaftsgröße |
| courts | "{count} courts" | öffnet das Court-Sheet | ja | Swiss misst „was noch kommt“ in geplanten Slots, auch für noch nicht gezogene Runden | Courts ändern |
| referees | "Refs covered" / "{gap} without a ref" | öffnet die Schiri-Deckung | ja | ab der nächsten ungespielten Einheit | Schiri-Deckung |
| seeding | "Random" | keine | nein — Feststellung | — | Wie Runde 1 gezogen wurde |
| rounds | "Round {round} of {total}" | keine | nein — Feststellung | — | Fortschritt durch die feste Rundenzahl |
| reroll | "Reroll round 1" | zieht Runde 1 neu | nur solange Runde 1 unberührt ist | Danach `drawStarted`. Nur die erste Runde ist eine Auslosung — alle weiteren folgen aus Ergebnissen | Erste Paarung neu würfeln |
| drawAdjust | "Adjust draw" | öffnet den Tauschdialog | nur solange Runde 1 unberührt ist | wie Reroll | Zwei Teams tauschen |
| byes | "{count} byes" | öffnet die Liste | nein — Feststellung | Ein ungerades Feld setzt jede Runde ein Team aus; das rotiert | Wer schon ausgesetzt hat |
| walkovers | "{count} walkovers" | öffnet die Liste | nein — Feststellung | Bei 0 nicht tippbar | Rückzüge |
| estFinish | "Ends {time}" | öffnet die Zeitleiste | Navigation | — | Voraussichtliches Ende |

## 1.5 Social Scramble — `lib/pages/scramble_overview_page.dart`

| Element | Beschriftung in der App | Aktion | Bearbeitbar hier? | Bedingung / Sperrgrund | Wofür |
|---|---|---|---|---|---|
| standings | "Standings" | öffnet die Tabelle | Navigation | — | Der Stand |
| allocation | "Allocation" | öffnet das Courtraster | Navigation | Bewusst eine zweite Pill neben der Court-Zahl: die sagt *wie viele*, diese *was jeder tut* | Was auf welchem Court läuft |
| teams | "Teams" | öffnet das Sheet | Navigation | — | Die Paarungen dieser Runde |
| players | "{count} players" | öffnet das Roster | Navigation, im Sheet bearbeitbar | Auf einer Mehr-Court-Session gehört die Roster-Änderung auf die Turnierseite, nicht auf eine Scorecard | Nachmelden, Pause, Austauschen |
| teamSize | "{n}v{n}" | öffnet die Einstellungen | ja, bis eine Runde festgezogen ist | Danach gesperrt — die Auslosung ist bereits gegen diese Größe gebaut | Mannschaftsgröße |
| rounds | "{count} rounds" | öffnet die Einstellungen | ja | — | Rundenzahl |
| courts | "{count} courts" | öffnet die Einstellungen | ja | — | Courts |
| estFinish | Ende laut Zeitplan | öffnet die Schedule Preview | Navigation | — | Voraussichtliches Ende |

## 1.6 Royal Rotation (App: Scramble King) — `lib/pages/scramble_king_overview_page.dart`

Alle mit „ja“ markierten Pills öffnen dasselbe Format-Sheet.

| Element | Beschriftung in der App | Aktion | Bearbeitbar hier? | Bedingung / Sperrgrund | Wofür |
|---|---|---|---|---|---|
| standings | "Standings" | öffnet die Ranking-Seite | Navigation | Dort ist auch die Ranking-Methode noch änderbar | Gesamtwertung |
| allocation | "Allocation" | öffnet die Court-Seite | Navigation | — | Was jeder Court tut |
| teams | "Teams" | öffnet das Sheet | Navigation | — | Aktuell gebildete Teams |
| players | "{count} players" | öffnet das Roster | Navigation, im Sheet bearbeitbar | — | Nachmelden, Pause, Austauschen |
| teamSize | "{n}v{n}" | öffnet den Editor | ja | Zieht nur ungespielte Runden neu; ein bereits gestartetes Turnier fragt vorher nach | Seitengröße |
| rounds | "{count} rounds" | Format-Sheet | ja | — | Rundenzahl |
| courts | "{count} courts" | Format-Sheet | ja | — | Courts |
| targetPoints | "{n} pt strike" | Format-Sheet | ja | Nur sichtbar, wenn Strike Points > 0 | Punkte zum Sieg auf dem Court |
| challengerAutoEject | "Auto-eject @ {n}" bzw. "Auto-eject off" | Format-Sheet | ja | Immer sichtbar — „aus“ ist genau der Zustand, den man vor dem Start kennen will | Herausforderer früh ablösen |
| oddPlayerMode | "Placeholder" / "Jumper" | Format-Sheet | ja | — | Partner für den überzähligen Spieler |
| assignmentMode | "Manual" / "Automated" / "Auto-Allplay" | Format-Sheet | ja | — | Wie das nächste Team auf den Court kommt |
| estFinish | "Est. finish: {time}" bzw. "Finished: {time}" | öffnet die Zeitleiste | Navigation | Die Schätzung ist abgeleitet, aber Startzeit und Runden-/Pausenlängen sind es nicht | Voraussichtliches Ende |

## 1.7 King of the Court — `lib/pages/kotc_queue_overview_page.dart`

| Element | Beschriftung in der App | Aktion | Bearbeitbar hier? | Bedingung / Sperrgrund | Wofür |
|---|---|---|---|---|---|
| standings | "Standings" | öffnet die Ranking-Seite | Navigation | — | Gesamtwertung |
| allocation | "Allocation" | öffnet die Court-Seite | Navigation | — | Was jeder Court tut |
| players | "{count} players" | öffnet das Roster | Navigation, im Sheet bearbeitbar | — | Nachmelden, Pause, Austauschen |
| teamSize | "{n}v{n}" | keine | nein — Feststellung | Im Setup gewählt und für das Event fix: jede Runde ist bereits dagegen gebildet, es gibt nichts, hinein zu bearbeiten | Seitengröße |
| rounds | "{count} rounds" | Format-Sheet | ja | — | Rundenzahl |
| courts | "{count} courts" | Format-Sheet | ja | — | Courts |
| targetPoints | "{n} pt strike" | Format-Sheet | ja | Nur sichtbar, wenn Strike Points > 0 | Punkte zum Sieg |
| challengerAutoEject | "Auto-eject @ {n}" / "Auto-eject off" | Format-Sheet | ja | Immer sichtbar | Herausforderer früh ablösen |
| assignmentMode | "Manual" / "Automated" / "Auto-Allplay" | Format-Sheet | ja | — | Teamzuteilung |
| estFinish | "Est. finish: {time}" / "Finished: {time}" | öffnet die Zeitleiste | Navigation | — | Voraussichtliches Ende |

## 1.8 Royal Shuffle (App: Doghouse) — `lib/pages/doghouse_queue_overview_page.dart`

Wie King of the Court, mit zwei zusätzlichen Regel-Pills:

| Element | Beschriftung in der App | Aktion | Bearbeitbar hier? | Bedingung / Sperrgrund | Wofür |
|---|---|---|---|---|---|
| escapePoints | "{count} pt escape" | Format-Sheet | ja | Nur sichtbar, wenn Escape Points > 0 | Punkte, um aus dem Doghouse zu kommen |
| lossLimit | "{count} loss limit" | Format-Sheet | ja | Nur sichtbar, wenn ein Limit gesetzt ist | Wie lange ein Team feststecken darf |

---

# 2 · Was die Seite außerhalb der Pills kann

| Element | Wo | Was es tut | Bedingung |
|---|---|---|---|
| Umbenennen | Titelzeile, Tipp auf den Namen unter dem Modus | Öffnet "Rename tournament" | Kein Schloss, keine Rückfrage, von jeder Oberfläche aus. Der Name ist die einzige Einstellung, an der nichts hängt — kein Spielplan, keine Tabelle, keine Auslosung. Nur eine importierte Scorecard unterdrückt sie, dort gehört der Name dem fremden Event |
| Export / Import | Scanner-Icon in der Titelzeile, Tooltip "Export / Import" | Menü mit drei Einträgen | Beide Wege liegen hinter demselben Icon, weil sie dieselbe Besorgung in zwei Größen sind: ein Court per QR, oder das ganze Event als Workbook |
| — "Import result" | ebenda und im Menü jeder Partie | Scannt ein Ergebnis-QR vom Schiri-Gerät | Der Code trägt seine eigene Match-ID, ein Scanner reicht also für das ganze Turnier. Fehltexte: "This QR code is not a result." · "This result is for a different tournament." |
| — "Export tournament" | Menü | Baut das Excel-Workbook und gibt es an das Share-Sheet | "There is nothing to export yet.", solange es nichts gibt |
| — "Import tournament" | Menü | Liest ein Workbook zurück | Vorschau vor dem Anwenden: "{applied} recorded · {cleared} cleared · {skipped} skipped". Ab 5 überschriebenen Ergebnissen — oder wenn die Datei mindestens die Hälfte überschreibt — wird ein zweites Mal gefragt ("Replace results"). Abweisungen: falsches Turnier, falscher Modus, neuere App-Version, fehlende Spalten |
| "Export game" | QR-Icon auf der Match-Karte | Gibt eine Partie per QR an ein Schiri-Gerät | Trägt die echte Position mit ("Gold semi-final", "Slot 7"), damit die fremde Scorecard nicht „Final · Match 1“ behauptet. Nicht bei Walkovers und nicht, solange ein Gegner fehlt |
| "Manually Set Score" | QR-Icon auf der Match-Karte | Endstand satzweise eintragen und die Partie abschließen | In jedem Zustand verfügbar. Bei vorhandenem Ergebnis erst die Rückfrage "Override current score?" — "This game already has a score. Editing it will replace the current result." Hilfetext: "Use this when the game was played without live scoring. Enter the final score for both sides and complete the game." |

---

# 3 · Die Sheets hinter den Pills

| Sheet | Datei | Was darin geht | Grenzen |
|---|---|---|---|
| Teams | `sheets/bracket_teams_sheet.dart` | Team bearbeiten, gegen ein anderes tauschen, zurückziehen | Bearbeiten und Tauschen nur, wenn die Seite die Roster-Hooks mitgibt; Withdraw nur im laufenden Turnier. Ein abgeschlossenes Event lässt Withdraw von selbst weg — es gibt keinen Restspielplan mehr |
| Players | `sheets/scramble_roster_editor.dart` (und die Queue-Geschwister) | Nachmelden, Pause, Austauschen, bearbeiten | Nachmelden zieht alle ungespielten Runden neu: "{name} will join as a late entry. Remaining pairings will be reshuffled — some players may end up with an unequal number of games." Pause bleibt auch dort verfügbar, wo Roster-Änderungen gesperrt sind — sie zieht nichts neu |
| Pause | `sheets/player_break_dialog.dart` | Zwei Fragen: wie lange (nur diese Runde / bis auf Weiteres), und was mit dem Platz passiert (offen halten oder aus der Queue nachbesetzen) | Die zweite Frage nur, wenn der Platz gerade auf dem Court ist |
| Courts | `sheets/court_count_sheet.dart` | Anzahl und Court-Namen | Anzahl bis 32 (Schnellwahl bis 8), eingefroren sobald nichts mehr umzuplanen ist, nie unter einen Court mit laufendem Match. Umbenennen bleibt immer möglich |
| Referees | `sheets/referee_coverage_sheet.dart` | Deckung mitten im Turnier umstellen | "Applies from {unit} — what has been played keeps its courts and times." |
| Bracket generation | `sheets/generation_sheet.dart` | Seeding plus die modeeigene zweite Wahl (Odd Teams, Legs) | Entwurf, nicht live — nichts wird vor "Save" angewendet: "Regenerates the bracket. Available only before the first match starts." |
| Adjust draw | `sheets/draw_adjust_sheet.dart` | Team von Hand setzen | Immer ein Tausch. "Swap {team} with…" · "That place is taken. Pick who moves the other way." |
| Byes / Walkovers | `sheets/auto_decided_sheet.dart` | Die ohne Court entschiedenen Partien ansehen | Reine Liste |
| Schedule preview | `sheets/schedule_preview_sheet.dart` | Zeitleiste plus Pace-alerts-Schalter | Der Zeitplan selbst ist pro Modus |
| Court allocation | `pages/courts_page.dart` | Partie halten und auf einen anderen Court ziehen, Slot-Format einzeln setzen, Pausen setzen, Court-Plan auflegen | "Tap a match for its full card · hold to move it to another court." · Plan-Optionen: "One court per group", "One court per tier", "Maximise court use", "Allow backfilling". Warnt, wenn die Courts für eine saubere Teilung nicht reichen |

---

# 4 · Was *nicht* auf dieser Seite liegt

- **Kopieren und Löschen** eines Turniers stehen in der Turnierliste des Modus
  (`*_hub_page.dart`), eine Ebene darüber. Kopie: "Copy of {name}" — gleiche
  Einstellungen, gleiche Teilnehmer, frische Paarungen, heute. Löschen fragt:
  "This will permanently delete {name} and all its data."
- **Ranking-Methode und Strict-Modus** der Queue-Modi sitzen auf der Statistikseite
  hinter der Standings-Pill, nicht im Pill-Row selbst.
- **Match-Kontext-Pills** (Round, Court, Starts at, Sets, Points, Duration) gibt es
  nur auf der Scorecard. Auf der Turnierseite ist diese Zeile leer.

---

# 5 · Auffälligkeiten beim Durchgehen

- **Zwei Pills sehen gleich aus und meinen Verschiedenes:** „Byes“ als Odd-Team-Strategie
  (Einstellung) und „{count} byes“ als Liste (Feststellung). Deshalb trägt die Liste
  eine Zahl.
- **teamSize ist nicht überall gleich streng.** Bracket-Modi und die beiden Queue-Modi
  zeigen sie als reine Angabe, Royal Rotation und Social Scramble lassen sie ändern —
  weil dort nur ungespielte Runden neu gebildet werden.
- **Seeding-Pill zeigt „Random“ und ist nicht tippbar**, so wie im Setup „Seeded“
  ausgegraut ist. Beide Stellen sagen dasselbe, nur mit verschiedenen Mitteln.
- **Der Grand-Final-Schalter ist absichtlich die späteste Entscheidung im Programm** —
  er bleibt offen, bis das Finale gespielt ist.
- **League hat weder Redraw noch Adjust draw**, und das mit Absicht: bei „jeder gegen
  jeden“ gibt es keine alternative Paarung, die ein Tausch ändern würde.
