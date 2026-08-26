/* Der Inhalt des User Guide — die eine Quelle.

   PAGES ist der Inhalt, CARDS kommt gebacken aus tools/cards/cards.json, NAV
   ist der Baum der Seitenleiste, EXTERN sind die Seiten der Website darin.
   Keine Zeile hier fasst das DOM an: nur so kann tools/bake-guide.mjs sie
   unter Node lesen und dieselben Seiten schreiben, die der Browser zeichnet.

   Die Bausteine (panel/step/item/split/fbox/sect/note/grid/flow) entsprechen
   eins zu eins tournaq/lib/widgets/explainer/explainer_blocks.dart, damit der
   Text hier und die Erklaerseiten in der App dieselbe Form behalten.

   Einer hat noch kein Gegenstueck in der App: `opts`, die Referenztabelle auf
   den acht "Setting up …"- und acht "Running a …"-Seiten. Ihre Zeilen sind
   direkt aus der App gelesen — tournaq/lib/pages/*_setup_page.dart fuer die
   Felder der Einrichtung (Vorgaben, Standardwerte, Grenzen, Fussnoten, die
   Hilfetexte hinter den Fragezeichen), tournaq/lib/widgets/pills/ fuer die
   Pillen der Turnierseite (was jede oeffnet und warum sie sperrt), und die
   Scorecard-Seiten samt lib/scoring/ fuer das, was jede Karte kann.
   setup-options.md, tournament-options.md und scorecard-options.md in diesem
   Repo halten dieselben Daten mit ihren Quelldateien; aendert sich die App,
   muessen diese drei und die Tabellen hier nachziehen.

   Gewachsen aus drafts/guide/guide-web-draft.html — dort nichts mehr aendern.
*/

/* ══════════════════════════════════════════════════════════════════════════
   Block helpers — one-for-one with lib/widgets/explainer/explainer_blocks.dart
   so this draft translates straight into the existing widgets.
   ══════════════════════════════════════════════════════════════════════════ */
const panel = (badge, sub, items, o={}) => ({t:'panel', badge, sub, items, ...o});
const step  = (n, icon, label, cap, o={}) => ({k:'step', n, icon, label, cap, ...o});
const item  = (icon, label, cap, o={}) => ({k:'item', icon, label, cap, ...o});
const split = (label) => ({k:'split', label});
/* Zwei parallele Straenge in einem Panel. `split` teilt einen Strang der
   Laenge nach — nacheinander gelesen —, `fork` stellt zwei Faelle
   nebeneinander, die gleichzeitig gelten: links die eine Modusfamilie,
   rechts die andere. Ohne Gegenstueck in der App, wie `opts`. */
const fork  = (a, b) => ({k:'fork', a, b});
const arm   = (label, items) => ({label, items});
const fbox  = (icon, title, body, lines) => ({t:'fbox', icon, title, body, lines});
const sect  = (label, icon='i-south') => ({t:'sect', label, icon});
const note  = (title, body) => ({t:'note', title, body});
const grid  = (cards) => ({t:'grid', cards});
const imgcards = (cards) => ({t:'imgcards', cards});
/* Ein App-Screenshot mit Bildunterschrift. `src` ist der Pfad unter assets/
   ohne Groessensuffix, `sizes` die Breiten, die auf der Platte liegen — beide
   werden von tools/bake-guide.mjs nicht erraten, sondern beim Erzeugen aus
   tools/specs/*.json eingetragen. `w`/`h` halten das Seitenverhaeltnis, damit
   beim Laden nichts springt. */
const shot = (src, w, h, sizes, title, body, alt) => ({t:'shot', src, w, h, sizes, title, body, alt});
const flow  = (spec) => ({t:'flow', spec});
/* Ein Verweis von der Einleitung auf einen Block weiter unten. `href` bleibt
   der echte Anker, damit die gebackene Seite auch ohne JavaScript springt;
   `data-jump` faengt boot.js ab und zentriert das Ziel, statt den Hash zu
   veraendern — der gehoert hier dem Router. */
/* Ein Verweis aus dem Fliesstext auf eine andere Guide-Seite. Wohin er zeigt,
   weiss erst der Renderer — Hash-Route oder eigene Datei —, hier steht daher
   nur der Knoten in einem Platzhalter, den renderPage zum Schluss aufloest. */
const pageLink = (id, txt) => '<a class="g-jump" href="{{' + id + '}}">' + txt + '</a>';
const jump = (id, txt) => '<a class="g-jump" href="#' + id + '" data-jump="' + id + '">' + txt + '</a>';

/* The settings table. `opt` is one field of a setup page, in the app's own
   terms: `what` says why it is there, `dflt` carries the default and the range
   it accepts, `when` the condition or warning the app attaches to it, and
   `help` quotes the help sheet behind the field's question mark verbatim. */
const opts = (label, rows, cols) => ({t:'opts', label, rows, cols});
const opt  = (name, values, dflt, o={}) => ({name, values, dflt, ...o});

/* ══ CARDS — gebacken aus tools/cards/cards.json, nicht von Hand ══ */
const CARDS = {
  'administration': {img:'administration', to:'administration', t:'Administration', s:'Set up players, teams and clubs to easily<br>assign them to your tournaments.', alt:'Administration — Set up players, teams and clubs to easily assign them to your tournaments.', k:'Players, teams and clubs, set up once.'},
  'arena': {img:'arena', to:'arena', t:'TournaQ Arena', s:'Browse the TournaQ Arena and find<br>your favourite game mode.', alt:'TournaQ Arena — Browse the TournaQ Arena and find your favourite game mode.', k:'Find your favourite game mode.'},
  'quick-game': {img:'quick-game', to:'quick-game', t:'Quick Game', s:'Easily keep track<br>of any game.', alt:'Quick Game — easily keep track of any game.'},
  'tournament-hub': {img:'tournament-hub', to:'tournament-hub', t:'Tournament Hub', s:'Maintain and set up<br>new tournaments.', alt:'Tournament Hub — Maintain and set up new tournaments.', k:'Set up a new tournament.'},
  'tournament': {img:'tournament', to:'tournament', t:'Running a Tournament', s:'Keep control over your tournament and change<br>settings as needed. Track results and progress.', alt:'Running a Tournament — Keep control over your tournament and change settings as needed. Track results and progress.', k:'Your control desk once it starts.'},
  'scorecards': {img:'scorecards', to:'scorecards', t:'Scorecards', s:'The referee\'s best friend. Easily keep track of the<br>results, supported by time keeping, automatic<br>side changes and serving indication.', alt:'Scorecards — The referee\'s best friend. Easily keep track of the results, supported by time keeping, automatic side changes and serving indication.', k:'The referee\'s best friend.'},
  'exported': {img:'exported', to:'exported', t:'Exported Scorecard', s:'Leverage the offline functions of TournaQ and hand<br>scorecards of your tournament over to your<br>assigned referees by QR code.', alt:'Exported Scorecard — Leverage the offline functions of TournaQ and hand scorecards of your tournament over to your assigned referees by QR code.', k:'Hand scorecards over by QR code.'},
  'team-competitions': {img:'team-competitions', to:'brackets', t:'Team Competitions', s:'Play and win tournaments<br>together with your partner.', alt:'Team Competitions — Play and win tournaments together with your partner.'},
  'scramble-competitions': {img:'scramble-competitions', to:'scrambles', t:'Scramble Competitions', s:'Play and win tournaments on your own account.<br>Temporarily team up with everyone in your group.', alt:'Scramble Competitions — Play and win tournaments on your own account. Temporarily team up with everyone in your group.'},
  'queue-modes': {img:'queue-modes', to:'queue-modes', t:'Queue Modes', s:'Queue up and play nonstop.<br>Can you handle the pressure?', alt:'Queue Modes — Queue up and play nonstop. Can you handle the pressure?'},
  'social-scramble': {img:'social-scramble', to:'m-social-scramble', t:'Social Scrambles', s:'Team up for timed games with everyone in your group.<br>Play a full tournament in less than an hour.', alt:'Social Scrambles — Team up for timed games with everyone in your group. Play a full tournament in less than an hour.'},
  'royal-rotation': {img:'royal-rotation', to:'m-royal-rotation', t:'Royal Rotations', s:'King of the Court. Stick with a partner<br>for one round — but never for two.', alt:'Royal Rotations — King of the Court. Stick with a partner for one round — but never for two.'},
  'royal-shuffle': {img:'royal-shuffle', to:'m-royal-shuffle', t:'Royal Shuffles', s:'King of the Court.<br>Change your partner with every rally.', alt:'Royal Shuffles — King of the Court. Change your partner with every rally.'},
  'royal-duo': {img:'royal-duo', to:'m-royal-duo', t:'Royal Duos', s:'King of the Court.<br>Win as a team.', alt:'Royal Duos — King of the Court. Win as a team.'},
  'doghouse': {img:'doghouse', to:'m-doghouse', t:'Doghouses', s:'Get out of the Doghouse —<br>if you can.', alt:'Doghouses — Get out of the Doghouse — if you can.'},
  'league': {img:'league', to:'m-league', t:'Leagues', s:'Play against everybody.<br>Once or twice. No excuses.', alt:'Leagues — Play against everybody. Once or twice. No excuses.', k:'Everybody plays everybody.'},
  'elimination': {img:'elimination', to:'m-elimination', t:'Eliminations', s:'Win or get knocked out.<br>A game of nerves.', alt:'Eliminations — Win or get knocked out. A game of nerves.', k:'A plain knockout.'},
  'classic': {img:'classic', to:'m-classic', t:'TournaQ Classics', s:'Qualify for the gold tier, or make it through in bronze.<br>Secure your spot on the podium.', alt:'TournaQ Classics — Qualify for the gold tier, or make it through in bronze. Secure your spot on the podium.', k:'Qualification first, then knockout.'},
  'swiss': {img:'swiss', to:'m-swiss', t:'Swiss Systems', s:'Win and play against winners.<br>Until it gets lonely at the top.', alt:'Swiss Systems — Win and play against winners. Until it gets lonely at the top.', k:'Paired against someone on your score.'},
};
/* Zielseite -> Karte, fuer das Hero-Bild oben auf der Seite. */
const CARD_BY_ZIEL = {};
Object.keys(CARDS).forEach(s => CARD_BY_ZIEL[CARDS[s].to] = CARDS[s]);
/* ══ Ende CARDS ══ */

/* ══ Pages ═══════════════════════════════════════════════════════════════ */
const PAGES = {

/* ── The map ─────────────────────────────────────────────────────────── */
home: {
  title:'TournaQ User Guide', route:'/guide', icon:'i-map', parent:null,
  eyebrow:'The map',
  h1:['The ','TournaQ',' Principle'],
  lead:'Every path through the app starts in the same place and ends on a scorecard. What changes in between is how much structure you want around the game. Tap any node to read what it does.',
  blocks:[
    flow('principle'),
    note('Draft note · scope',
      'This page replaces the current two-panel Principle screen. The existing panels become the <b>flow map</b> above; everything else is new depth reached by tapping a node. Nothing here navigates <b>into</b> the app — the guide stays a place to read, which is the rule the current explainers already follow.'),
  ],
},

/* ── Administration ──────────────────────────────────────────────────── */
administration: {
  title:'Administration', route:'/guide/administration', icon:'i-admin', parent:'home',
  eyebrow:'Step 1 · optional',
  h1:['Administration'],
  lead:'Everything you set up once, so you never type it twice. Skip it entirely and add people as you go — Administration only pays off from the second session onwards.',
  blocks:[
    panel('Administration','Three areas, one shared address book.',[
      item('i-admin','Players','Name, and whatever else you want on record.'),
      item('i-people','Teams','Fixed pairings for the bracket modes.'),
      item('i-shield','Groups','Clubs, levels, courses — used to filter rosters later.'),
    ]),
    sect('Three ways to fill it', 'i-south'),
    grid([
      {icon:'i-edit', label:'Upfront, by hand', cap:'One at a time, before the season starts.', to:'admin-hand'},
      {icon:'i-upload', label:'Bulk upload', cap:'A whole club from one spreadsheet.', to:'admin-bulk'},
      {icon:'i-trophy', label:'During tournament setup', cap:'Add people while you build the event.', to:'admin-setup'},
    ]),
  ],
  next:['admin-hand','arena'],
},

/* ── Administration · the three ways in ───────────────────────────────── */
'admin-hand': {
  title:'Upfront, by hand', route:'/guide/administration/by-hand', icon:'i-edit', parent:'administration',
  eyebrow:'Administration · By hand',
  h1:['Upfront, ','by hand'],
  lead:'Fine for a handful of people. Type them in once, before anybody is standing on a court waiting for you.',
  blocks:[
    panel('What you can do',null,[
      item('i-admin','Add a player','One at a time, straight into the list.'),
      item('i-people','Build a team','Pair two players for the bracket modes.'),
      item('i-shield','Sort into groups','Clubs, levels, courses — whatever you will want to filter by later.'),
      item('i-edit','Edit or remove','Fix a name, retire a player, move someone between groups.'),
    ]),
    fbox('i-check','Good for','A regular group that changes slowly. Once the names are right they stay right, and every tournament from then on starts from them.'),
  ],
  next:['admin-bulk','administration'],
},

'admin-bulk': {
  title:'Bulk upload', route:'/guide/administration/bulk-upload', icon:'i-upload', parent:'administration',
  eyebrow:'Administration · Spreadsheet',
  h1:['Bulk ','upload'],
  lead:'The fast lane for a whole club. One file carries players, teams and groups in, and the same file carries them back out again.',
  blocks:[
    panel('The round trip','Four steps, and none of them is typing names into a phone.',[
      step(1,'i-download','Download template','An XLS with the right columns already in place.'),
      step(2,'i-grid','Fill it in','Players, teams and groups in one file — type or paste from wherever your list already lives.'),
      step(3,'i-upload','Import it back','TournaQ reads the file and creates everything it finds.'),
      step(4,'i-check','Ready to use','Your roster is available to every tournament from now on.', {tone:'tint'}),
    ]),
    fbox('i-sync','It is a round trip','Export, edit, import. The same template carries your data out and back in, so a season of changes never has to be retyped inside the app.'),
  ],
  next:['admin-setup','administration'],
},

'admin-setup': {
  title:'During tournament setup', route:'/guide/administration/at-setup', icon:'i-trophy', parent:'administration',
  eyebrow:'Administration · At setup',
  h1:['During ','tournament setup'],
  lead:'You do not have to prepare anything. Every setup sheet can take new names as you go — and whatever you add there lands in Administration for next time.',
  blocks:[
    panel('On the setup sheet',null,[
      item('i-people','Pull from your roster','Filter by group, search by name, or add a whole group with one tap.'),
      item('i-admin','Or type someone new','A player who turns up unannounced goes straight in, without leaving setup.'),
      item('i-sync','It works both ways','Names added here are kept, so the roster grows by being used rather than by being maintained.'),
    ]),
    fbox('i-check','Which sheet you land on depends on the mode','Every mode asks for something slightly different — teams and legs for a League, strikes and swaps for a queue mode. The nine setup pages below are the mode-by-mode version of this screen.'),
    sect('Setting it up, mode by mode', 'i-south'),
    grid([
      {icon:'i-trophy', label:'Leagues', cap:'What this mode asks you at setup.', to:'m-league-hub'},
      {icon:'i-trophy', label:'Eliminations', cap:'What this mode asks you at setup.', to:'m-elimination-hub'},
      {icon:'i-trophy', label:'TournaQ Classics', cap:'What this mode asks you at setup.', to:'m-classic-hub'},
      {icon:'i-trophy', label:'Swiss Systems', cap:'What this mode asks you at setup.', to:'m-swiss-hub'},
      {icon:'i-trophy', label:'Social Scrambles', cap:'What this mode asks you at setup.', to:'m-social-scramble-hub'},
      {icon:'i-trophy', label:'Royal Rotations', cap:'What this mode asks you at setup.', to:'m-royal-rotation-hub'},
      {icon:'i-trophy', label:'Royal Shuffles', cap:'What this mode asks you at setup.', to:'m-royal-shuffle-hub'},
      {icon:'i-trophy', label:'Doghouses', cap:'What this mode asks you at setup.', to:'m-doghouse-hub'},
      {icon:'i-trophy', label:'Quick Game', cap:'What this mode asks you at setup.', to:'quick-game-hub'},
    ]),
  ],
  next:['tournament-hub','administration'],
},

/* ── Arena ───────────────────────────────────────────────────────────── */
arena: {
  title:'TournaQ Arena', route:'/guide/arena', icon:'i-arena', parent:'home',
  eyebrow:'Step 2',
  h1:['TournaQ ','Arena'],
  lead:'The Arena is the one place where you choose what you are about to run. Every mode in the app lives behind this screen, sorted by what kind of session you want.',
  blocks:[
    panel('Styles','What the modes are built for.',[
      item('i-court','Sports','Classic volleyball, footvolley, and any sport that counts the same way.'),
      item('i-people','Team sizes','Anything from 2 to 6 players a side.'),
    ]),
    sect('The game families'),
    imgcards(['quick-game', 'team-competitions', 'scramble-competitions', 'queue-modes']),
    sect('All ten modes', 'i-trophy'),
    /* Sortiert wie die Familien darueber, und jede Karte traegt ihr Etikett:
       die Karte allein sagt nicht, in welcher Familie ein Modus laeuft — und
       vier von ihnen laufen in der Queue statt nach Spielplan. */
    imgcards([
      ['quick-game', 'Quick game'],
      ['league', 'Team competition'],
      ['elimination', 'Team competition'],
      ['classic', 'Team competition'],
      ['swiss', 'Team competition'],
      ['royal-duo', 'Team competition · Queue mode'],
      ['social-scramble', 'Scramble competition'],
      ['royal-rotation', 'Scramble competition · Queue mode'],
      ['royal-shuffle', 'Scramble competition · Queue mode'],
      ['doghouse', 'Scramble competition · Queue mode'],
    ]),
    fbox('i-score','Every mode comes with the scorecard it needs','Team competitions get the classic scorecard with sets and target points. The scramble competitions get one of two, depending on how the round is scored — the timed card, or the one that shows the queue.', [
      {icon:'i-score', title:'Classic scorecard', body:'Leagues, Eliminations, TournaQ Classics, Swiss Systems, Quick Game'},
      {icon:'i-timer', title:'Scramble scorecard', body:'Social Scrambles, Royal Rotations'},
      {icon:'i-queue', title:'Queue scorecard', body:'Royal Shuffles, Doghouses'},
    ]),
  ],
  next:['quick-game','brackets','scrambles','queue-modes','scorecards'],
},

/* ── Quick Game ──────────────────────────────────────────────────────── */
'quick-game': {
  title:'Quick Game', route:'/guide/quick-game', icon:'i-bolt', parent:'arena',
  eyebrow:'Standalone',
  h1:['Quick ','Game'],
  lead:'When you just need a scorecard. No roster, no schedule, no setup to undo afterwards.',
  blocks:[
    panel('The whole flow',null,[
      step(1,'i-arena','TournaQ Arena','The same screen the tournaments start from.'),
      step(2,'i-bolt','Quick Game','Name the two sides, set the format, done.'),
      step(3,'i-score','Scorecard','Start counting.', {tone:'tint'}),
    ]),
    fbox('i-bolt','Nothing to clean up afterwards','A quick game is a game, not a tournament. It still lands in your history, so a casual match you decided to keep is not lost.', [
      {icon:'i-timer', title:'Running in seconds', body:'Two names and a target score is all it needs'},
      {icon:'i-people', title:'Any format', body:'Same team sizes, sets and target points as the tournament scorecard'},
    ]),
    sect('The three steps', 'i-south'),
    grid([
      {icon:'i-trophy', label:'Set it up', cap:'Teams, courts, format — and what it costs in time.', to:'quick-game-hub'},
      {icon:'i-score', label:'Score it', cap:'The card you score on, and what it shows.', to:'quick-game-score'},
    ]),
  ],
  next:['quick-game-hub','arena'],
  /* ══ INBOX · migriert aus pages/modes/quick-game.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Quick Game page · to review','i-south'),
    fbox('i-target','Best for',null,[
      {icon:'i-check', title:'A single match where a tournament would be overkill'},
      {icon:'i-check', title:'Training games where you just want the score kept honestly'},
      {icon:'i-check', title:'Trying the app out before running a real session'},
    ]),
    panel('Finding it in the app','Quick Games sit at the top of the TournaQ Arena, above the tournament formats. The list keeps every match you have scored.',[]),
    shot('guide/00_shell/04_arena',430,932,[430, 860],
      'The Arena',
      'Every format the app can run, grouped by the kind of session it suits. The number on a card is how many of those you have run.',
      'The TournaQ Arena with Quick Games at the top'),
    shot('guide/02_quick_games/01_games',430,932,[430, 860],
      'Your matches',
      'Every game you have scored, most recent first, with the final score and the date. Tap one to see the full set-by-set result.',
      'The Quick Games list showing previously scored matches'),
  ],
},

/* ── Tournament Hub ──────────────────────────────────────────────────── */
'tournament-hub': {
  title:'Tournament Hub', route:'/guide/tournament-hub', icon:'i-trophy', parent:'home',
  eyebrow:'Step 3',
  h1:['Tournament ','Hub'],
  lead:'Where a tournament is built. Pick the mode, bring the people in, say how much time and how many courts you have — TournaQ works out the rest.',
  blocks:[
    panel('Setting one up',null,[
      step(1,'i-trophy','Pick the mode','League, elimination, Classic, Swiss, or one of the scrambles.'),
      step(2,'i-people','Bring in the players','Pull them from Administration — filter by group, search, or add the whole group at once — or type in new ones on the spot.'),
      step(3,'i-court','Courts and format','How many courts, how big the teams, how long a game lasts.'),
      step(4,'i-clock','Rounds and timing','TournaQ builds the schedule and puts every game into a slot.'),
      step(5,'i-check','Start','The tournament opens and the first games are ready to score.', {tone:'tint'}),
    ]),
    fbox('i-copy','Run the same thing again','Copy a finished tournament and you get the same participants and the same settings, ready for next week — one tap instead of the whole setup.'),
    note('Draft note · the shortcut',
      'Your Principle diagram draws a dashed line straight from Administration to the Hub, bypassing the Arena. That is real: a saved roster means you can start at setup. The map on the home page keeps it dashed for exactly that reason.'),
    sect('Setting it up, mode by mode', 'i-south'),
    grid([
      {icon:'i-trophy', label:'Leagues', cap:'What this mode asks you at setup.', to:'m-league-hub'},
      {icon:'i-trophy', label:'Eliminations', cap:'What this mode asks you at setup.', to:'m-elimination-hub'},
      {icon:'i-trophy', label:'TournaQ Classics', cap:'What this mode asks you at setup.', to:'m-classic-hub'},
      {icon:'i-trophy', label:'Swiss Systems', cap:'What this mode asks you at setup.', to:'m-swiss-hub'},
      {icon:'i-trophy', label:'Social Scrambles', cap:'What this mode asks you at setup.', to:'m-social-scramble-hub'},
      {icon:'i-trophy', label:'Royal Rotations', cap:'What this mode asks you at setup.', to:'m-royal-rotation-hub'},
      {icon:'i-trophy', label:'Royal Shuffles', cap:'What this mode asks you at setup.', to:'m-royal-shuffle-hub'},
      {icon:'i-trophy', label:'Doghouses', cap:'What this mode asks you at setup.', to:'m-doghouse-hub'},
      {icon:'i-trophy', label:'Quick Game', cap:'What this mode asks you at setup.', to:'quick-game-hub'},
    ]),
  ],
  next:['tournament','administration'],
},

/* ── The controls every setup page carries ───────────────────────────── */
'setup-settings': {
  title:'Settings Every Mode Shares', route:'/guide/tournament-hub/settings', icon:'i-clock', parent:'tournament-hub',
  eyebrow:'Tournament Hub · reference',
  h1:['Settings every ','mode shares'],
  lead:'Schedule, game format, pace, roster, name. Each mode page lists what is its own; this is everything the eight of them have in common — with the app’s own help text, word for word.',
  blocks:[
    opts('Schedule Preview — the controls inside the card',[
      opt('Start date','Date picker','Today · yesterday to +365 days',
        {what:'Where the plan starts counting.',
         when:'Bracket modes only. The player-pool modes carry a time of day, not a date.'}),
      opt('Start time','Time picker','One hour from now',
        {what:'The anchor every other time on the page is measured from.',
         when:'Player-pool modes read “Start: Now” until you pick a time.'}),
      opt('Game format','Opens the format sheet — sets, target score, side change','1 × 15',
        {what:'How much actually gets played in one match.',
         when:'Bracket modes only. Once a single round is set differently, the row adds “{count} rounds differ”.',
         help:'“Applies to every round. Individual rounds can differ.”'}),
      opt('Game pace','Fast · 45s, Standard · 60s, Relaxed · 80s, or a number you type','Standard · 60s · from 5s',
        {what:'The one free variable in a points-target schedule — and the reason the finish time moves.',
         help:'“How long a rally takes on average. Drives every time estimate for this tournament.”'}),
      opt('Break after a round','0, 5, 10, 15, 20, 30, 45, 60 min, or a length you type','No break · 0 to 1440 min',
        {what:'Lunch, a prize-giving, the gap between two halls.',
         when:'The last round has nothing to break before. Until you set one, the row reads “Add break”.'}),
      opt('Format for one round','The same format sheet, plus “Use the default”','Inherits the tournament format',
        {what:'One round played shorter or longer than the rest.',
         when:'Sits in the expanded schedule detail. The reset only appears while that round really differs.'}),
      opt('Anchored start','“Set start day &amp; time”, or “Remove — back to auto”','Automatic',
        {what:'Pins one round to a real clock time — a second day, a fixed evening slot.',
         when:'Bracket modes only. An anchored round is marked “custom start”.'}),
      opt('Schedule detail','“Show all {count} slots” / “Hide detail”','Collapsed above 4 slots',
        {what:'The round-by-round list, and the summary that stands in for it when it is folded away.'}),
    ]),
    opts('Game format — the sheet behind the row',[
      opt('Sets per game','1, 3, 5','1'),
      opt('Target score','11, 15, 21, or a number you type','15 · from 1',
        {what:'Points that win a set.'}),
      opt('Side change','Off, 5, 7, or a number you type','Every 5 points · from 1',
        {what:'How often the teams swap ends.'}),
      opt('Notify at target score','On / off','On',
        {help:'“Prompt to finish when a side reaches the target”'}),
    ]),
    opts('Below the schedule, on every page',[
      opt('Pace alerts','On / off','Off',
        {what:'Marks rounds as on track, due or overdue once the event is running.',
         help:'“Flag rounds as on track, due, or overdue”'}),
      opt('Roster — Teams or Players','Create new, add from Administration, filter by group, search, add all','Empty',
        {what:'Who is actually taking part. The tile turns red while the count is wrong and olive once it matches.',
         when:'The bracket modes only offer saved teams that field exactly the format you chose — a 2vs2 event will not list a three-player team.'}),
      opt('Fill random','Fills the roster up to the planned count','—',
        {what:'A session that has no name list yet, or a dry run.',
         when:'Player-pool modes only.'}),
      opt('Count mismatch','Adjust the plan, or keep it and fix the line-up','—',
        {what:'What happens when you add more or fewer people than you planned for.',
         help:'“You added {selected} teams, but the setup is planned for {target}. Adjusting updates the bracket, seeding and schedule — keep {target} if you’d rather review the line-up first.”'}),
      opt('Tournament Name','Free text, plus a suggest button','A random name in the mode’s own style',
        {when:'Create stays disabled while the name is empty.'}),
      opt('Create Tournament','The button that ends setup','Disabled until the page is ready',
        {what:'The line above it says what is still missing — “Add all {count} teams to continue”, or simply “Ready to start!”.'}),
    ]),
    fbox('i-bolt','Two families, two kinds of setup page','The bracket modes — Leagues, Eliminations, TournaQ Classics, Swiss Systems — play to a points target, so they carry a game format, a pace and a full slot list. The player-pool modes run a clock instead: the round ends when the minutes are up, so they ask for a match duration and a break, and never for sets or a target score.'),
  ],
  next:['tournament-hub','tournament'],
},

/* ── Tournament (management) ─────────────────────────────────────────── */
tournament: {
  title:'Running a Tournament', route:'/guide/tournament', icon:'i-grid', parent:'tournament-hub',
  eyebrow:'Step 4',
  h1:['Running a tournament'],
  lead:'Once it starts, the tournament screen is your control desk. Twelve things it does for you, grouped by what they are actually for.',
  blocks:[
    panel('Keeping time','The reason a session finishes when you said it would.',[
      item('i-clock','Schedules','Every single game gets a time slot, so you always know what is left.'),
      item('i-timer','Pace controls','Optional. Shows you and the players when something is running early or late, while you can still react.'),
      item('i-court','Court allocations','Who plays when and where, at a glance. Open and close courts as they become available.'),
    ]),
    panel('Keeping people in it','Sessions never survive contact with real life unchanged.',[
      item('i-people','Team and player management','Swap or eject teams mid-tournament. In scramble competitions, add or pause players without breaking the queue.'),
      item('i-admin','Start serving suggestions','TournaQ fairly suggests who serves first in every game across the tournament.'),
      item('i-target','Referee suggestions','And who referees, drawn fairly from whoever is free.'),
    ]),
    panel('Keeping control','Nothing is locked in once it starts.',[
      item('i-grid','Tournament overview','The whole state on one screen. Adjust settings where you need to.'),
      item('i-score','Scorecards with context','Every game carries its own scorecard with the tournament data already on it.'),
    ]),
    panel('Afterwards','What the session leaves behind.',[
      item('i-qr','Scorecard sharing','Hand scorecards to other devices and collect the results back. Paperless, and it works offline.'),
      item('i-copy','Copy tournament','Same people, same settings, new session.'),
      item('i-doc','XLS export','The full data set, out of the app, for whatever you do with it next.'),
      item('i-upload','XLS results import','Or track results in the exported sheet and read them back in.'),
    ]),
    fbox('i-off','Built to work without signal','Courts are outdoors and the wifi is somebody else’s problem. Scheduling, scoring and sharing all work with no connection at all.'),
    sect('Running it, mode by mode', 'i-south'),
    grid([
      {icon:'i-grid', label:'Leagues', cap:'What the live screen shows for this mode.', to:'m-league-run'},
      {icon:'i-grid', label:'Eliminations', cap:'What the live screen shows for this mode.', to:'m-elimination-run'},
      {icon:'i-grid', label:'TournaQ Classics', cap:'What the live screen shows for this mode.', to:'m-classic-run'},
      {icon:'i-grid', label:'Swiss Systems', cap:'What the live screen shows for this mode.', to:'m-swiss-run'},
      {icon:'i-grid', label:'Social Scrambles', cap:'What the live screen shows for this mode.', to:'m-social-scramble-run'},
      {icon:'i-grid', label:'Royal Rotations', cap:'What the live screen shows for this mode.', to:'m-royal-rotation-run'},
      {icon:'i-grid', label:'Royal Shuffles', cap:'What the live screen shows for this mode.', to:'m-royal-shuffle-run'},
      {icon:'i-grid', label:'Doghouses', cap:'What the live screen shows for this mode.', to:'m-doghouse-run'},
    ]),
  ],
  next:['scorecards','exported'],
},

/* ── What the tournament page can do ─────────────────────────────────── */
'tournament-controls': {
  title:'Tournament Page Controls', route:'/guide/tournament/controls', icon:'i-edit', parent:'tournament',
  eyebrow:'Running it · reference',
  h1:['Everything the ','tournament page',' can do'],
  lead:'The pills under the progress ring are the whole control panel: every setting the event still has, and every screen it can reach. Some you can change here, some only state a fact, and some are locked with a reason. This is how to tell which is which — and what the page carries beyond them.',
  blocks:[
    fbox('i-bolt','Reading a pill before you tap it','Colour and the trailing glyph always agree, because both come from the same thing: what tapping actually does.',[
      {icon:'i-swap', title:'Tinted, with ›', body:'Opens something — the standings, the roster, the court grid, the timeline.'},
      {icon:'i-edit', title:'Tinted, with a pencil', body:'Editable right here. Opens a small sheet and writes the change back into the event.'},
      {icon:'i-shield', title:'Tinted, with a padlock', body:'The setting exists and is changeable — just not from this screen, or not any more. Tapping tells you which.'},
      {icon:'i-doc', title:'Grey, no glyph', body:'A fact, not a setting. Nothing anywhere can change it, so the pill offers nothing to tap.'},
    ]),
    opts('The three reasons a pill is locked',[
      opt('The draw is set','A match has started or been played, so nothing about the draw may move — redrawing would discard results.','Redraw, Adjust draw, Legs, Odd Teams, Format — and on Swiss the round-1 reroll',
        {help:'“The draw is fixed once a match has started.”'}),
      opt('Not from here','This screen does not own the setting. The tournament page does.','Any event setting seen from a scorecard',
        {help:'“This belongs to the tournament, not to one game. Change it in the tournament overview, where it applies to the whole event.”'}),
      opt('Locked while multiple courts are running','The setting is per court, but several courts feed one shared ranking — so it can only change for all of them at once.','Format settings on a scorecard, when the session runs on more than one court',
        {help:'“This session runs on {courts} courts, and every court feeds one shared ranking. Changing the format here would rescore only these players against everyone else’s unchanged rules. Change it from the tournament overview instead, where it applies to every court at once. On a single-court session you can edit it right here.”'}),
    ], ['Lock','Why','Which pills wear it']),
    sect('Beyond the pills','i-south'),
    opts('The page itself',[
      opt('Rename the event','Tap the name under the mode title. No lock, no confirmation, from any screen at any point — the name is the one setting nothing else depends on.','In the title bar, under the mode name'),
      opt('Import result','Scan a result QR from a referee’s phone. The code carries its own match id, so one scanner serves the whole event and the score lands on the right fixture whichever cell you opened it from.','Scanner icon in the title bar, and in each match’s own menu'),
      opt('Export tournament','Builds the event’s Excel workbook and hands it to the share sheet — the whole event, results included.','Scanner icon in the title bar'),
      opt('Import tournament','Reads a workbook back. A pre-flight dialog says what would happen before anything is applied — “{applied} recorded · {cleared} cleared · {skipped} skipped” — and lists every result it would overwrite by name. Five or more overwrites, or a file that rewrites half of what it touches, asks a second time.','Scanner icon in the title bar'),
      opt('Export game','Hands one match to a referee device as a QR code, carrying its true position — “Gold semi-final”, “Slot 7” — so their scorecard says where the match sits.','The QR icon on a match card'),
      opt('Manually Set Score','Write a final score in set by set, without opening the scoreboard. Available in every state; on a match that already has a result the override warning fires first and the fields come prefilled.','The QR icon on a match card',
        {help:'“Use this when the game was played without live scoring. Enter the final score for both sides and complete the game.”'}),
    ], ['Control','What it does','Where it is']),
    opts('The sheets the pills open',[
      opt('Teams / Players','Edit an entrant, swap one for another, or withdraw them. A withdrawal turns the remaining fixtures into walkovers; on the player-pool modes, adding someone mid-session re-forms every round nobody has played yet.','The roster pills'),
      opt('Courts','The count, and the court names. The count freezes once there is nothing left to reschedule, and never drops below a court with a live match on it. Quick picks stop at 8; the field takes up to 32.','“{n} courts”'),
      opt('Referees','The same question setup asked, answered again mid-event. It applies from the next unplayed round: “what has been played keeps its courts and times.”','“Refs covered” / “{n} without a ref”'),
      opt('Bracket generation','Seeding, plus whatever second choice the mode has — odd teams, legs. Drafted rather than live: nothing applies until Save, because changing it redraws every unplayed match.','“Legs”, “Odd Teams”',
        {help:'“Regenerates the bracket. Available only before the first match starts.”'}),
      opt('Adjust draw','Place a team by hand. Always an exchange, never a one-way move — a group that grew by one would get more fixtures, more slots and a later finish than its neighbours.','“Adjust draw”'),
      opt('Court allocation','Where every fixture is going to be played, and the one place to change it. Hold a match to move it to another court, tap a slot number to set that slot’s format alone, or lay a plan over the whole event: one court per group, one per tier, or maximise court use.','“Allocation”'),
      opt('Schedule preview','The timeline — when each round runs, what it plays, and the breaks between — plus the pace-alerts switch.','“Ends {time}”, or “Set schedule” while there is no plan yet'),
      opt('Byes and walkovers','The matches decided without ever taking a court. They live behind a pill instead of padding out the schedule.','“{n} byes”, “{n} walkovers”'),
    ], ['Sheet','What you can do in it','Opened from']),
    fbox('i-copy','Two things that are not on this page','Copying an event and deleting one both live in the mode’s tournament list, one level up. Copy runs the same event again: same settings, same entrants, fresh fixtures, today.'),
  ],
  next:['tournament','tournament-hub'],
},

/* ── Scorecards hub ──────────────────────────────────────────────────── */
scorecards: {
  title:'Scorecards', route:'/guide/scorecards', icon:'i-score', parent:'home',
  eyebrow:'Step 5',
  h1:['Scorecards'],
  lead:'Where every path lands. Three of them, because a bracket final, a timed scramble round and a king-of-the-court stint do not need the same controls.',
  blocks:[
    grid([
      {icon:'i-score', label:'Classic scorecard', cap:'Sets, target points, side switches. For bracket modes and Quick Game.', to:'sc-classic'},
      {icon:'i-timer', label:'Scramble scorecard', cap:'Timed rounds instead of sets. For Social Scrambles.', to:'sc-scramble'},
      {icon:'i-queue', label:'Queue scorecard', cap:'The court plus who is waiting. For Royal Shuffles, Doghouses and Royal Rotations.', to:'sc-queue'},
    ]),
    fbox('i-share','And one way to hand them over','Any scorecard can leave your device and come back with a result on it.', [
      {icon:'i-qr', title:'Exported scorecard', body:'Let somebody else run the game on their own phone'},
    ]),
    sect('Scoring it, mode by mode', 'i-south'),
    grid([
      {icon:'i-score', label:'Leagues', cap:'The card this mode scores on.', to:'m-league-score'},
      {icon:'i-score', label:'Eliminations', cap:'The card this mode scores on.', to:'m-elimination-score'},
      {icon:'i-score', label:'TournaQ Classics', cap:'The card this mode scores on.', to:'m-classic-score'},
      {icon:'i-score', label:'Swiss Systems', cap:'The card this mode scores on.', to:'m-swiss-score'},
      {icon:'i-score', label:'Social Scrambles', cap:'The card this mode scores on.', to:'m-social-scramble-score'},
      {icon:'i-score', label:'Royal Rotations', cap:'The card this mode scores on.', to:'m-royal-rotation-score'},
      {icon:'i-score', label:'Royal Shuffles', cap:'The card this mode scores on.', to:'m-royal-shuffle-score'},
      {icon:'i-score', label:'Doghouses', cap:'The card this mode scores on.', to:'m-doghouse-score'},
      {icon:'i-score', label:'Quick Game', cap:'The card this mode scores on.', to:'quick-game-score'},
    ]),
  ],
  next:['sc-classic','sc-scramble','sc-queue','exported'],
},

'sc-classic': {
  title:'Classic Scorecard', route:'/guide/scorecards/classic', icon:'i-score', parent:'scorecards',
  eyebrow:'Scorecard',
  h1:['Classic scorecard'],
  lead:'The full match scorecard: sets, target points and side switches, for every mode where two fixed teams play a match out.',
  blocks:[
    panel('What it does',null,[
      item('i-queue','Points match history','Counts and shows every point made by either team during their service.'),
      item('i-swap','Serving change automation','Tells you whose serve it is, at any moment.'),
      item('i-grid','Variable target sets','1, 3, 5 or any custom number of sets to win.'),
      item('i-target','Variable target points','15, 18, 21 or your own number — win by two.'),
      item('i-sync','Side switch automation','Reminds you to change ends and swaps the counter with you, so nobody loses track.'),
      item('i-swap','Gesture side switch','Or turn the automation off and swap sides yourself with a gesture.'),
    ]),
    fbox('i-check','Used by','Leagues, Eliminations (single and double), TournaQ Classics, Swiss Systems — and Quick Game.'),
    sect('Every control on the card','i-south'),
    opts('The classic card, top to bottom',[
      opt('The pill row','Match context — event name, position, court, sets, target points, duration — plus the event settings, locked here because the tournament page owns them. The roster is the exception: it is the one setting this card writes itself.','Under the title'),
      opt('Schedule card','This match’s planned start and end, and “Over schedule!” when it runs long.','Only while pace alerts are on for the event'),
      opt('Set overview','One card per set with its score; tap one to make it the active set.','Formats of more than one set'),
      opt('Serves-first banner','Who starts the match serving, before anyone has scored.','Until the first point — dropped in landscape for room'),
      opt('Referee banner','“{name} suggested as referee”, or “Assign a referee manually”.','When the event reserves referees'),
      opt('Score buttons','Plus awards the point to that side, minus takes one back. Service passes to whoever just scored and the rotation moves on a slot. The score cannot go below zero.','Until the set or match is complete'),
      opt('Side-change reminder','“Total score is {score}. Teams must switch sides now.” Confirm with “Sides Switched — Continue” and the counters swap with you.','When the format carries a side-change interval'),
      opt('Target-reached prompt','“{team} reached the target. Set {set} is won.” — then “Complete Set” (or “Complete Game”), or “Keep Playing” if the day’s rules say win by two.','On reaching the target score, while the format’s prompt is on'),
      opt('Match Options','“Swap Sides — Switch left and right display”, “Change Service — Advance to next server”, “Match History — View point-by-point history”.','The slider icon beside Gameplay Controls'),
      opt('Match History','The rally-by-rally timeline, grouped by set — “Set {n} · to {target}”, ending in “Final: {s1} – {s2}”.','From Match Options'),
      opt('Lock banner','“Match complete” with the winner’s name, or “Set complete — undo set to edit score”. The score buttons go quiet behind it.','Once a set or the match is finished'),
      opt('Match controls','“Start Match” before the first point; then Complete / Undo Set on multi-set formats, Complete / Undo Game, and “Back to Schedule”.','Bottom of the card'),
      opt('App-bar QR menu','“Export scorecard” hands the match to another phone; “Manually Set Score” writes the final score straight in.','At 0–0 and again once complete — hidden mid-match, so nobody exports half a game'),
      opt('Landscape','Turn the phone and the same controls rearrange for a net post or a side table.','Any time'),
    ], ['Control','What it does','When you see it']),
    sect('What each mode does with it','i-south'),
    opts('What differs, mode by mode',[
      opt('Leagues','The position reads “Round {n} · Match {m}” — a league has no bracket to read one from — and the Crosstable opens from the pill row.','<a href="#/m-league-score">Scoring a League match</a>'),
      opt('Eliminations','A guard once the following match has started: “The next match has already started, so the winner of this match can’t change. You can still correct the points as long as the same team wins.” Byes open from the pill row.','<a href="#/m-elimination-score">Scoring an Elimination match</a>'),
      opt('TournaQ Classics','The position names the phase and the tier the match belongs to.','<a href="#/m-classic-score">Scoring a TournaQ Classic match</a>'),
      opt('Swiss Systems','Completing the last match of a round pairs the next round immediately — the card runs that reconcile itself.','<a href="#/m-swiss-score">Scoring a Swiss System match</a>'),
      opt('Quick Game','Target score and side swap are dropdowns on the card, because there is no tournament to inherit them from. The options sheet says “Swap Teams”, the card closes with “Save &amp; Return to Games”, and tapping a team name edits the lineup. No schedule card and no referee banner.','<a href="#/quick-game-score">Scoring a Quick Game</a>'),
    ], ['Mode','What is different here','The full card, control by control']),
    grid([
      {icon:'i-score', label:'Leagues', cap:'Every control on this card, in one table.', to:'m-league-score'},
      {icon:'i-score', label:'Eliminations', cap:'Every control on this card, in one table.', to:'m-elimination-score'},
      {icon:'i-score', label:'TournaQ Classics', cap:'Every control on this card, in one table.', to:'m-classic-score'},
      {icon:'i-score', label:'Swiss Systems', cap:'Every control on this card, in one table.', to:'m-swiss-score'},
      {icon:'i-bolt', label:'Quick Game', cap:'Every control on this card, in one table.', to:'quick-game-score'},
    ]),
  ],
  next:['exported','scorecards'],
},

'sc-scramble': {
  title:'Scramble Scorecard', route:'/guide/scorecards/scramble', icon:'i-timer', parent:'scorecards',
  eyebrow:'Scorecard',
  h1:['Scramble scorecard'],
  lead:'The same counting, on a clock. Scramble rounds end when time runs out, not when somebody reaches a number — so sets and target points come off the card.',
  blocks:[
    panel('What it does',null,[
      item('i-queue','Points match history','Counts and shows every point made by either team during their service.'),
      item('i-swap','Serving change automation','Tells you whose serve it is, at any moment.'),
      item('i-swap','Gesture side switch','Swap sides yourself, with a gesture, whenever you want.'),
      item('i-timer','Game timer','The round runs to a hard time limit. When it ends, everyone regroups.'),
    ]),
    fbox('i-clock','Why the timer decides','Every court has to finish together, or the next scramble cannot be drawn. The clock keeps the whole session in step.'),
    fbox('i-check','Used by','Social Scrambles, and nothing else.'),
    sect('Every control on the card','i-south'),
    opts('The scramble card, top to bottom',[
      opt('The pill row','Event name — editable, because a name re-forms nothing — then round and court, and Standings, Allocation, Teams and the player count. Format, rounds and courts edit here only on a single-court session.','Under the title'),
      opt('Round timer','The countdown that ends the round, with Stop, Resume and Start / Restart. A pause freezes the remaining time and stores it, so leaving the page does not cost you the clock.','Always'),
      opt('Serves-first banner','Who starts the round serving.','Until the first point'),
      opt('Referee banner','“{name} refs”, or “Assign a referee manually”.','When this court has a referee slot for the round'),
      opt('Score buttons','Plus and minus per side, with service passing to whoever scored. The score cannot go below zero.','Always'),
      opt('Player pills','Tap a player to send them off: “{name} is on a break — their seat is a Placeholder.” Tap the stand-in to bring them back: “{name} is back in the rotation.” With nothing left to come back to: “No round left to sit out.”','While a later round can bring them back'),
      opt('Upcoming games','The next games still to play, grouped by round, each with its referee and a note when courts run in parallel.','Below the card'),
      opt('App-bar QR menu','“Export scorecard”, and “Manually Set Score” for a game played away from the phone.','While the board is live'),
      opt('Back','“Back to Schedule” on your own device, “Back to Hub” on an imported card.','Bottom of the card'),
      opt('Landscape','Turn the phone and the same controls rearrange for a net post or a side table.','Any time'),
    ], ['Control','What it does','When you see it']),
    grid([
      {icon:'i-timer', label:'Scoring a Social Scramble game', cap:'The timer, the breaks, the upcoming games and the pill row — every control, in one table.', to:'m-social-scramble-score'},
    ]),
  ],
  next:['m-social-scramble-score','scorecards'],
},

'sc-queue': {
  title:'Queue Scorecard', route:'/guide/scorecards/queue', icon:'i-queue', parent:'scorecards',
  eyebrow:'Scorecard',
  h1:['Queue scorecard'],
  lead:'Half scorecard, half waiting list. It shows the court and the queue behind it, because in queue modes the next players matter as much as the current score.',
  blocks:[
    panel('What it does',null,[
      item('i-queue','The queue, live','Who is on, who is admin, when the handover is, and who is up next to challenge — laid out to match the assignment mode you chose.'),
      item('i-target','Score court points','Count what the side on court is making.'),
      item('i-swap','Eject challengers','Manually, or automatically once they have conceded enough.'),
      item('i-swap','Eject court teams','Manually, or automatically when they win the game or concede too much.'),
      item('i-timer','Game timer','The round runs to a hard time limit.'),
    ]),
    fbox('i-check','Used by','Royal Shuffles, Doghouses and Royal Rotations.'),
    sect('Every control on the card','i-south'),
    opts('The queue card, top to bottom',[
      opt('The pill row','The same pills the tournament page carries, plus this round and this court. The format pills edit here only on a single-court session; on more than one they lock, because every court feeds one shared ranking.','Under the title'),
      opt('Court','Who is holding the court right now, and the points they have made this turn.','Always'),
      opt('Challengers','The side waiting to come on next.','Always — “Waiting for players…” while the queue is too thin'),
      opt('Up Next','The stage behind the challengers, with “Re-roll” to draw a different pairing.','Automatic assignment — “Not enough players in queue.” when there is nobody left to draw'),
      opt('Score buttons','Count the points the side on court is making.','Always'),
      opt('Session timer','The round’s countdown, with Stop, Resume and Start / Restart.','Always'),
      opt('Eject','Sends the side off and brings the next one on. “Eject / Challenger” where the prompt can rotate a challenger instead.','Always — manual ejection stays available whatever the automatic thresholds say'),
      opt('Automatic eject prompts','The mode’s own threshold fires and offers “Eject Team” — a strike, an escape, or a loss limit reached.','When that threshold is set above zero'),
      opt('Undo','Takes the last step back. With points already on the board it asks first: “The team currently on court has {points} point(s) recorded. Undoing will discard them.”','After an ejection, and during a manual pick'),
      opt('Change referee','“Select who referees this court. The current one returns to the queue.” The successor is suggested from the current court team.','Auto-Allplay, where a rotating referee keeps score'),
      opt('Player pills','Send someone on a break — their seat becomes a Placeholder — and tap the stand-in to bring them back.','While a later round can bring them back'),
      opt('Start / Finish court','“Start Court” drops it into live play; “Finish court” asks “Record this court’s results now and end its round.” and is reversible with “Undo Finish”.','Bottom of the card'),
      opt('App-bar QR menu','“Export court” hands the whole court to another phone; “Manually Set Score” writes the results in directly.','While the court is live'),
      opt('Landscape','Turn the phone and the same controls rearrange for a net post or a side table.','Any time'),
    ], ['Control','What it does','When you see it']),
    sect('What each mode does with it','i-south'),
    opts('What differs, mode by mode',[
      opt('Royal Shuffles','The strike prompt ends a hold: “Game Won! {names} reached {points} points! They will be ejected and return to the queue.” The table under the card ranks individual players.','<a href="#/m-royal-shuffle-score">Scoring a Royal Shuffle match</a>'),
      opt('Doghouses','Two thresholds instead of one — “Escaped!” at the escape target, and “Ejected! {names} lost {count} games!” at the loss limit.','<a href="#/m-doghouse-score">Scoring a Doghouse match</a>'),
      opt('Royal Rotations','Pairs queue instead of individuals, so the card adds a partner picker — “Pick a partner for the floater” — and the table under it ranks teams.','<a href="#/m-royal-rotation-score">Scoring a Royal Rotation match</a>'),
    ], ['Mode','What is different here','The full card, control by control']),
    grid([
      {icon:'i-crown', label:'Royal Shuffles', cap:'Every control on this card, in one table.', to:'m-royal-shuffle-score'},
      {icon:'i-shield', label:'Doghouses', cap:'Every control on this card, in one table.', to:'m-doghouse-score'},
      {icon:'i-crown', label:'Royal Rotations', cap:'Every control on this card, in one table.', to:'m-royal-rotation-score'},
    ]),
  ],
  next:['queue-modes','scorecards'],
},

/* ── Exported scorecard ──────────────────────────────────────────────── */
exported: {
  title:'Exported Scorecard', route:'/guide/exported-scorecard', icon:'i-qr', parent:'scorecards',
  eyebrow:'Sharing',
  h1:['Exported scorecard'],
  lead:'You cannot stand at four courts at once. Hand a scorecard to whoever is standing at the other three.',
  blocks:[
    panel('How it works',null,[
      step(1,'i-qr','Export the card','TournaQ turns the game — or a whole court — into a QR code.'),
      step(2,'i-share','They scan it','On their own phone. No account, no install of your tournament, no connection needed.'),
      step(3,'i-score','They score the game','A full scorecard on their side, with the right teams and format already on it.'),
      step(4,'i-sync','You collect the result','Scan it back and the result drops into your tournament.', {tone:'tint'}),
    ]),
    fbox('i-off','Paperless and offline','The whole exchange is two QR codes. Nothing goes through a server, so it works on a beach with no signal exactly as well as it does indoors.'),
    note('Draft note · direction of the arrow',
      'Your Principle diagram shows lines running <b>both ways</b> between Tournament and Exported Scorecard, which raised a question in the source notes. The draft treats that as correct and deliberate: the card goes out, the result comes back. It is a round trip, not a one-way export.'),
    sect('What changes on a borrowed card','i-south'),
    opts('The imported card',[
      opt('It writes nowhere but back','Everything scored on a borrowed card stays on that phone until the result QR is scanned back. It never touches the host’s tournament store.','Always'),
      opt('“Export result”','Where your own card offers “Export scorecard”, an imported one offers the result instead — and refuses early: “Finish the match before exporting the result.”','Once the match is complete'),
      opt('The real position','The card carries the host’s own round — “Quarter-final · Match 3” — rather than the receiving phone’s idea of it.','Under the title'),
      opt('Read-only event','The event name and the roster are the host’s, so they are stated rather than offered. Every other event setting is locked with “Not from here”.','The pill row'),
      opt('Upcoming games, frozen','An imported card lists what the host’s schedule looked like at the moment it was shared: “Snapshot from when this was shared — the schedule may have changed since.”','Scramble and queue cards'),
      opt('Back to Hub','There is no schedule underneath a borrowed card, so it returns to the hub instead.','Bottom of the card'),
      opt('Coming home','On the host phone the scanner takes it back: “Result imported.” A code from elsewhere is refused — “This result is for a different tournament.” — and a code that is not a result at all says so.','The tournament page'),
    ], ['Control','What it does','When you see it']),
  ],
  next:['tournament','scorecards'],
},

/* ── Team competitions ───────────────────────────────────────────────── */
brackets: {
  title:'Team Competitions', route:'/guide/team-competitions', icon:'i-bracket', parent:'arena',
  eyebrow:'Competition family',
  h1:['Team Competitions'],
  lead:'Classic tournament modes, where players show up with their partner and stay together all day. Four ways to decide who wins — and a fifth card for the queue engine, where a pair earns its spot on court instead of being scheduled onto it.',
  blocks:[
    imgcards(['league', 'elimination', 'classic', 'swiss', 'queue-modes']),
    fbox('i-people','What they share','Fixed teams, a full schedule, and the classic scorecard. Set them up once and TournaQ handles the rest.', [
      {icon:'i-clock', title:'Scheduled into time slots', body:'Every game has a place in the day'},
      {icon:'i-court', title:'Court allocation', body:'Games spread across whatever courts you have'},
      {icon:'i-people', title:'Teams stay together', body:'Pull them from Administration or build them at setup'},
    ]),
  ],
  next:['m-league','m-elimination','m-classic','m-swiss','queue-modes'],
},

/* ── Scramble Competitions ────────────────────────────────────────────── */
scrambles: {
  title:'Scramble Competitions', route:'/guide/scramble-competitions', icon:'i-people', parent:'arena',
  eyebrow:'Competition family',
  h1:['Scramble ','Competitions'],
  lead:'Nobody needs a partner to enter. Every mode here has the same job — get as many people playing with as many different people as possible. What changes is how TournaQ gets you there, and every result is yours alone.',
  blocks:[
    imgcards(['social-scramble', 'queue-modes']),
    fbox('i-star','Fair by design','Both families balance court time rather than leaving it to the draw. Whoever has played least goes on next, and sitting out rotates — so the standings reflect how you played, not who you were drawn with.'),
    fbox('i-people','And people can arrive late or leave early',null,[
      {icon:'i-check', title:'Add a player mid-session without breaking the queue'},
      {icon:'i-check', title:'Pause somebody for a round — a stand-in takes the seat'},
      {icon:'i-check', title:'Rankings stay comparable across everyone'},
    ]),
  ],
  next:['m-social-scramble','queue-modes'],
},

/* ── Classic modes ────────────────────────────────────────────────────── */

/* ── Queue modes ─────────────────────────────────────────────────────── */
'queue-modes': {
  /* Haengt an der Arena, nicht an einer der beiden Familien: die Seite ist
     dieselbe, ob man von den Scramble- oder von den Team Competitions kommt,
     und ein Krumenpfad darf dann keine der beiden behaupten. */
  title:'Queue Modes', route:'/guide/queue-modes', icon:'i-queue', parent:'arena',
  eyebrow:'Mode family',
  h1:['Queue Modes'],
  lead:'Highly dynamic modes where you have to earn your spot on the court to score points, win games and appear in the ranking. Everybody else is in the queue — and the queue keeps moving, so there are essentially no sit-outs. Three things are worth settling before you start: how the ' + jump('assignment','challengers get assigned') + ', how a game is ' + jump('scoring','scored and a side ejected') + ', and how the ' + jump('standings','final table is ranked') + '.',
  blocks:[
    sect('Setting 1 · Challenger Assignment', 'i-queue'),
    panel('Assignment','Decided at setup: does the coach or admin step onto the court and play, or stand beside it and orchestrate?',[
      item('i-admin','Manual','The admin assigns every challenger by hand — picking the next side up rally by rally, or simply reacting to what just happened on court.'),
      item('i-sync','Automated','The system works out the queue fairly. The admin stays off court and orchestrates: announcing the challengers and the queue, and managing the points.'),
      item('i-people','Auto Allplay','The system works out the queue the same way, but the admins play too. The role rotates: the system decides fairly when you take over the desk, and when you hand it to the next admin in line and rejoin the queue. It asks every player to be able to manage the scoreboard — align on that before you start the game.'),
    ], {id:'assignment'}),
    sect('Setting 2 · Scoring & Ejection Rules', 'i-score'),
    panel('Scoring & ejection','What wins a game on court, and what sends a side back into the queue. The first three rules hold in every queue mode — only the target and the price of a conceded point differ between Royals and Doghouses.',[
      item('i-court','Points only count on court','Only the side holding the court scores. As a challenger you play to take the court, not for the board — nothing you win down there goes into your total.'),
      item('i-swap','Challenger auto ejection','Optional, and it keeps the game dynamic: challengers get one attempt at the court, or several. Set them to be ejected on the first point they concede, on the second, or later. When they go, the team up next moves in.'),
      item('i-admin','Manual ejection','The admin can eject either side by hand at any point — the court team as well as the challengers.'),
      fork(
        arm('Royals', [
          item('i-crown','Strike points','Set how many points make a strike. Score them while you hold the court and you have won the game: the strike is booked and you are ejected — as the winner. Back into the queue, and off after the next one.'),
          item('i-shield','One life on court','Concede a single point and you are out. The challengers move up and you go back into the queue.'),
        ]),
        arm('Doghouses', [
          item('i-check','Escape points','The same target under a harsher name. Reach the escape points you set and you escape — the game is won.'),
          item('i-sync','Back to zero','Concede a point and your count is set back to zero. That escape is gone; you start building it again.'),
          item('i-timer','Loss limit','How many attempts you get. Hit the limit and you are ejected without ever escaping.'),
        ]),
      ),
    ], {id:'scoring'}),
    sect('Setting 3 · Ranking Options', 'i-trophy'),
    panel('Standings','Worth agreeing on before the first whistle — but nothing is locked in. You can change how the table sorts while the tournament runs, and set the baseline you consider fairest for each tournament separately.',[
      item('i-star','Ranking points','Pick this to equalise the rounds. Points are awarded by where you placed on your court, and the winner always takes the most — but only ever one more than second place. So it takes a steady run across every round: killing it once and then laying back is not enough.'),
      item('i-crown','Strikes / escapes','Counts the actual games you win, and nothing else. The totals carry straight through, so a round where you stand out keeps paying off all the way to the final table.'),
      item('i-target','Points','Pick this to look at the points alone, no matter who won the game under the rules of the mode. Every point you scored while on court counts, across all rounds.'),
    ], {id:'standings'}),
    sect('The four modes'),
    imgcards([
      ['royal-rotation', 'Scramble competition'],
      ['royal-shuffle', 'Scramble competition'],
      ['doghouse', 'Scramble competition'],
      ['royal-duo', 'Team competition'],
    ]),
  ],
  next:['m-royal-rotation','m-royal-shuffle','m-doghouse','m-royal-duo','sc-queue'],
},

/* ══ Mode pages ══════════════════════════════════════════════════════ */
'm-league': {
  title:'Leagues', route:'/guide/modes/league', icon:'i-grid', parent:'brackets',
  eyebrow:'Team competition',
  h1:['Leagues'],
  lead:'Round-robin standings across a full season of fixtures, with one or two legs. Everybody plays everybody, and the table decides it.',
  blocks:[
    panel('How it runs',null,[
      step(1,'i-people','Teams enter','Fixed pairs, straight from Administration or built at setup.'),
      step(2,'i-grid','Fixtures generated','Every team against every other. Twice, if you pick two legs.'),
      step(3,'i-clock','Packed into slots','Fixtures fill time slots under each round, across your courts.'),
      step(4,'i-trophy','The table decides','Points, wins and goal difference.', {tone:'tint'}),
    ]),
    sect('The three steps', 'i-south'),
    grid([
      {icon:'i-trophy', label:'Set it up', cap:'Teams, courts, format — and what it costs in time.', to:'m-league-hub'},
      {icon:'i-grid', label:'Run it', cap:'The live screen: standings, schedule, courts.', to:'m-league-run'},
      {icon:'i-score', label:'Score it', cap:'The card you score on, and what it shows.', to:'m-league-score'},
    ]),
  ],
  next:['m-league-hub','brackets'],
  /* ══ INBOX · migriert aus pages/modes/league.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Leagues page · to review','i-south'),
    fbox('i-target','Best for',null,[
      {icon:'i-check', title:'Club leagues and ladders where fairness matters more than drama'},
      {icon:'i-check', title:'Small fields with plenty of time — everyone gets a full card of matches'},
      {icon:'i-check', title:'Events where you want a defensible final ranking, not a knockout'},
    ]),
    fbox('i-grid','The crosstable','Read a row to see how one team has done against the whole field, or a column to see who has beaten them. The W-L and points-for columns on the right are what the final ranking is built from — no interpretation needed, just arithmetic everyone can check.'),
  ],
},

/* ── Royal Duo · placeholder ──────────────────────────────────────────── */
'm-royal-duo': {
  title:'Royal Duos', route:'/guide/modes/royal-duo', icon:'i-people', parent:'queue-modes',
  eyebrow:'Queue mode · team competition · in development',
  h1:['Royal ','Duos'],
  lead:'A fifth team competition, not yet built. This page is a placeholder so the mode has a home in the guide while the format is being worked out.',
  blocks:[
    fbox('i-clock','Nothing to document yet','The rules, the setup and the scorecard are still open. When the mode ships it gets the same three steps as every other one — set it up, run it, score it.'),
    note('Placeholder',
      'This page exists so links to <b>Royal Duo</b> already resolve and the mode appears in the Arena and in Team Competitions. Replace this block with real content once the format is decided — the three step pages can then be generated the same way as for the other modes.'),
  ],
  next:['queue-modes','brackets'],
},

/* ── League · the three steps ─────────────────────────────────────────── */
'm-league-hub': {
  title:'Setting up a League', route:'/guide/modes/league/tournament-hub', icon:'i-trophy', parent:'m-league',
  eyebrow:'League · Tournament Hub',
  h1:['Setting up a ','League'],
  lead:'Add the teams, say how many courts you have, and TournaQ generates the full fixture list — and tells you when it will finish, before you commit to it.',
  blocks:[
    panel('Teams, courts, format','Everything else has a sensible default.',[
      item('i-people','Teams','Fixed pairs, pulled from Administration or built here at setup.'),
      item('i-court','Courts','How many you have. The schedule spreads the fixtures across all of them.'),
      item('i-clock','Match format and duration','Sets, target points, and how long a match runs.'),
      item('i-swap','Seeding','Sits behind a pill, and stays changeable until play starts.'),
    ]),
    fbox('i-grid','See the schedule before you commit','The Schedule Preview does the arithmetic for you. A six-team league is fifteen matches — and it tells you what that costs in time, so you can change the courts or the match length before anyone has played a point.'),
    sect('Every setting on the page','i-south'),
    opts('League · Tournament Setup',[
      opt('Teams','4, 6, 8, 10, 12, 16 — or type any number','8 · 2 to 64',
        {what:'The size of the field. Fixtures, rounds and the length of the day all follow from it.',
         when:'Lower it below the teams you have already added and the surplus drops off the roster.'}),
      opt('Courts','1 to 6 from the list, or type your own','2 · 1 to 32',
        {what:'How many matches run at the same time.',
         when:'More courts than teams ÷ 2 can never all be filled: “Only {usable} courts can be used with {teams} teams — every team plays once per slot.”'}),
      opt('Referees','Fill every court · Keep a referee free','Fill every court',
        {what:'Whether the schedule holds a court back so every match has a referee from the field.',
         when:'“Keep a referee free” only becomes selectable once the field cannot staff every court — and the footnote prices it: “{gap} matches per round starts without a referee … Reserving covers them all and adds about {time}.”',
         help:'“Fill every court — Games run on every available court. There may be no free player left to referee — assign one by hand, or let the teams manage the game themselves.” · “Keep a referee free — Makes sure every game has a referee from the player pool. Only available once every court is filled and too few players sit out — matches wait so someone is free to referee, which makes the tournament longer.”'}),
      opt('Style','1vs1 through 6vs6','2vs2',
        {what:'How many players a side fields.',
         when:'Changing it re-shapes teams you have already added; unfilled places read “Player 2” until you name them.'}),
      opt('Legs','Single · Double','Single',
        {what:'Whether every pair meets once or twice.',
         help:'“Single — Every pair of teams meets exactly once. The shortest format — ideal for a single session.” (6 teams: 5 rounds of 3 matches, 15 in total) · “Double — Every pair meets twice, the second time with the sides reversed. Twice the rounds, and a fairer table.” (6 teams: 30 matches) · “Odd teams — With an odd number of teams, one team sits out each round. The bye rotates, so everyone sits out equally often.”'}),
      opt('Generation','Random · Seeded','Random',
        {what:'How the fixture order is drawn. This is the field the guide calls seeding.',
         when:'“Seeded” is listed but greyed out — it is not shipped yet.'}),
      opt('Back-to-back','Never · Up to 2 · No limit','Up to 2',
        {what:'How hard the schedule may pack the courts before a team gets a rest.',
         when:'The help sheet prices each option in slots for the field you have actually configured.',
         help:'“Never — Every team gets a slot off between matches. Kindest on players, but the longest schedule.” · “Up to 2 — A team plays at most two slots in a row before resting. Balances a full set of courts against recovery.” · “No limit — Pack the courts as tightly as the fixtures allow. The shortest day, but a team can play many matches in a row.”'}),
    ]),
    sect('The rest of the page','i-south'),
    opts('Below the grid — Schedule Preview, roster, name',[
      opt('Start date','Date picker','Today · yesterday to +365 days',
        {what:'Where the plan starts counting — and what makes a two-day event possible.'}),
      opt('Start time','Time picker','One hour from now',
        {what:'The anchor every other time on the page is measured from.'}),
      opt('Game format','Opens the format sheet — sets, target score, side change','1 × 15, sides every 5',
        {what:'How much actually gets played in one match.',
         when:'Once a single round is set differently, the row adds “{count} rounds differ”.',
         help:'“Applies to every round. Individual rounds can differ.”'}),
      opt('Sets per game','1, 3, 5','1',
        {what:'In the format sheet. Best-of format of a match.'}),
      opt('Target score','11, 15, 21, or a number you type','15 · from 1',
        {what:'Points that win a set.'}),
      opt('Side change','Off, 5, 7, or a number you type','Every 5 points · from 1',
        {what:'How often the teams swap ends. “Off” switches it away entirely.'}),
      opt('Notify at target score','On / off','On',
        {help:'“Prompt to finish when a side reaches the target”'}),
      opt('Game pace','Fast · 45s, Standard · 60s, Relaxed · 80s, or a number you type','Standard · 60s · from 5s',
        {what:'The one free variable in a points-target schedule — and the reason the finish time moves.',
         when:'The sheet shows “about {minutes} min a game” underneath.',
         help:'“How long a rally takes on average. Drives every time estimate for this tournament.”'}),
      opt('Break after a slot','0, 5, 10, 15, 20, 30, 45, 60 min, or a length you type','No break · 0 to 1440 min',
        {what:'Lunch, a prize-giving, the gap between two halls.',
         when:'The last slot has nothing to break before. Until you set one, the row reads “Add break”.'}),
      opt('Format for one slot','The same format sheet, plus “Use the default”','Inherits the tournament format',
        {what:'One round played shorter or longer than the rest.',
         when:'Sits in the expanded schedule detail. The reset only appears while that slot really differs.'}),
      opt('Anchored start','“Set start day &amp; time”, or “Remove — back to auto”','Automatic',
        {what:'Pins one slot to a real clock time — a second day, a fixed evening slot.',
         when:'An anchored slot is marked “custom start”.'}),
      opt('Schedule detail','“Show all {count} slots” / “Hide detail”','Collapsed above 4 slots',
        {what:'The slot-by-slot list, and the summary that stands in for it when it is folded away: slots and matches, duration each, the sum of the breaks, anchored starts.'}),
      opt('Pace alerts','On / off','Off',
        {what:'Marks rounds as on track, due or overdue once the event is running.',
         help:'“Flag rounds as on track, due, or overdue”'}),
      opt('Teams','Create new, add from Administration, group chips, search, “Add all ({count})”','Empty',
        {what:'Who is actually taking part. The tile is grey while empty, red while the count is wrong, olive once it matches.',
         when:'Only saved teams that field exactly the Style you chose are offered — a 2vs2 event will not list a three-player team. A name already on the list asks first: “{name} is already added to this tournament. Add anyway?”'}),
      opt('Clear all','Button, with a confirmation','—',
        {when:'“This will remove all added players from the list.”'}),
      opt('Confirm the count','Adjust the plan, or keep it and fix the line-up','—',
        {what:'What happens when you add more or fewer teams than you planned for.',
         help:'“You added {selected} teams, but the setup is planned for {target}. Adjusting updates the bracket, seeding and schedule — keep {target} if you’d rather review the line-up first.”'}),
      opt('Tournament Name','Free text, plus a suggest button','A random name in the mode’s own style',
        {when:'Create stays disabled while the name is empty.',
         help:'“Suggest a name”'}),
      opt('Create Tournament','The button that ends setup','Disabled until the page is ready',
        {what:'Needs a name, at least two teams, and exactly as many teams added as planned.',
         when:'The line above it reads “Ready to start!” or “Setup looks good!” — otherwise “Add all {count} teams to continue”, or “Setup incomplete”.'}),
    ]),
  ],
  next:['m-league-run','tournament-hub'],
  /* ══ INBOX · migriert aus pages/modes/league.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Leagues page · to review','i-south'),
    fbox('i-trophy','The Leagues hub','New Tournament starts a league. Below it sits your history, each entry showing the date, the team count and how far it got.'),
    fbox('i-court','Name and manage the courts','Courts can be named and taken in or out of use, which matters when one has the sun in your eyes or the club needs it back at four.'),
    note('Placement','This one is not a League setting — courts are named and taken in or out of use on every mode. It belongs on <b>Settings Every Mode Shares</b>, which today says “Open and close courts” but never mentions naming them.'),
  ],
},

'm-league-run': {
  title:'Running a League', route:'/guide/modes/league/tournament', icon:'i-grid', parent:'m-league',
  eyebrow:'League · Running it',
  h1:['Running a ','League'],
  lead:'One screen carries the event: the table as it stands, the fixtures still to play, and which court each of them is on.',
  blocks:[
    panel('What the screen gives you',null,[
      item('i-trophy','The table, live','Standings update as results land, and the progress ring shows how much of the league has been played. Nobody has to add anything up between rounds.'),
      item('i-clock','Fixtures by round','Every match grouped by round, with its court, its time slot and its score. Finished rounds collapse and the live one stays open.'),
      item('i-court','Or by court','The same fixtures regrouped so each court lists its own sequence — the view to hand someone who is running one court all afternoon.'),
    ]),
    fbox('i-clock','Timing stays honest mid-session','Change a court or add a break halfway through and TournaQ only re-times what has not been played. Recorded times of finished matches are never rewritten.'),
    sect('Every pill on the page','i-south'),
    opts('League · the pill row',[
      opt('“Standings”','The table as it stands, updated as results land.','Opens the table'),
      opt('“Crosstable”','Every fixture in one grid — who has played whom, and how it finished. League keeps its own pill because its standings have no bracket tab to reach the grid from.','Opens the grid'),
      opt('“Allocation”','The court grid: which fixture is on which court, and the one place to change that.','Opens the grid'),
      opt('“{n} teams”','Opens the roster: edit a team, swap one for another, or withdraw it mid-event.','Opens a sheet'),
      opt('“2v2”','The team size the draw was built against.','Statement — changing it would reshuffle every fixture, so nothing edits it'),
      opt('“{n} courts”','How many run at once. Only the unplayed part is re-timed, so nothing already played moves.','Edit here — until nothing is left to reschedule, and never below a court with a live match'),
      opt('“Refs covered” / “{n} without a ref”','Says whether the matches about to start have anyone to referee them, and lets you switch coverage.','Edit here — applies from the next unplayed round'),
      opt('“Random”','How the draw was made.','Statement — seeded draws are built but not released, so there is one reachable value'),
      opt('“Single” / “Double”','Whether every pair meets once or twice.','Edit here until the first match starts — after that it locks with “The draw is set”'),
      opt('“{n} walkovers”','The matches a withdrawal decided without anyone taking a court.','Opens the list — no tap while the count is zero'),
      opt('“Ends {time}”','The projected finish, read off the laid-out schedule rather than an ideal.','Opens the timeline — start time, each round’s format and break, and the pace-alerts switch'),
    ], ['Pill','What it does','Editable here?']),
    sect('The rest of the page','i-south'),
    grid([
      {icon:'i-edit', label:'Tournament page controls', cap:'QR, workbook, renaming — and why a pill locks.', to:'tournament-controls'},
    ]),
  ],
  next:['m-league-score','tournament'],
  /* ══ INBOX · migriert aus pages/modes/league.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Leagues page · to review','i-south'),
    panel('Finishing the league','When the last fixture is in, the table is the result — every team has played every other, so there is nothing left to argue about.',[
      item('i-check','The completed table',
        'Every fixture played and every result recorded, with the progress ring at a hundred per cent.'),
      item('i-trophy','Final standings',
        'The closing table with the winner at the top, ordered by the record everyone could see building all afternoon.'),
      item('i-grid','The whole picture',
        'The crosstable at the end is the archive of the event: who played whom, and what happened when they did.'),
    ]),
  ],
},

'm-league-score': {
  title:'Scoring a League match', route:'/guide/modes/league/scorecard', icon:'i-score', parent:'m-league',
  eyebrow:'League · Scorecard',
  h1:['Scoring a ','League match'],
  lead:'The same scorecard as everywhere else in TournaQ: big targets, the serving side marked, and undo for when the call goes the other way.',
  blocks:[
    panel('On the card',null,[
      item('i-score','Portrait','Tap a side to award the point. The server is highlighted, and service passes automatically when the other side scores.'),
      item('i-swap','Landscape','Turn the phone and the controls rearrange for a net post or a side table. The layout changes, the functions do not.'),
      item('i-trophy','Standings any time','The standings sheet is a tap away from anywhere in the league, so a team can check where they are without interrupting whoever is scoring.'),
    ]),
    fbox('i-check','Which card this is','The classic scorecard — sets, target points and side switches. The same one every team competition uses.'),
    sect('What this card gives you','i-south'),
    opts('League · the scorecard',[
      opt('The pill row','Event name, then “Round {n} · Match {m}” — a league has no bracket to read a position from — plus court, sets, target points and duration. Standings, Crosstable, Allocation and the walkovers list open from here; the league’s settings are padlocked, because the league page owns them','Under the title'),
      opt('Schedule card','This match’s planned start and end, and “Over schedule!” when it runs long.','Only while pace alerts are on for the event'),
      opt('Set overview','One card per set with its score; tap one to make it the active set.','Formats of more than one set'),
      opt('Serves-first banner','Who starts the match serving, before anyone has scored.','Until the first point — dropped in landscape for room'),
      opt('Referee banner','“{name} suggested as referee”, or “Assign a referee manually”.','When the event reserves referees'),
      opt('Score buttons','Plus awards the point to that side, minus takes one back. Service passes to whoever just scored and the rotation moves on a slot. The score cannot go below zero.','Until the set or match is complete'),
      opt('Side-change reminder','“Total score is {score}. Teams must switch sides now.” Confirm with “Sides Switched — Continue” and the counters swap with you.','When the format carries a side-change interval'),
      opt('Target-reached prompt','“{team} reached the target. Set {set} is won.” — then “Complete Set” (or “Complete Game”), or “Keep Playing” if the day’s rules say win by two.','On reaching the target score, while the format’s prompt is on'),
      opt('Match Options','“Swap Sides — Switch left and right display”, “Change Service — Advance to next server”, “Match History — View point-by-point history”.','The slider icon beside Gameplay Controls'),
      opt('Match History','The rally-by-rally timeline, grouped by set — “Set {n} · to {target}”, ending in “Final: {s1} – {s2}”.','From Match Options'),
      opt('Lock banner','“Match complete” with the winner’s name, or “Set complete — undo set to edit score”. The score buttons go quiet behind it.','Once a set or the match is finished'),
      opt('Match controls','“Start Match” before the first point; then Complete / Undo Set on multi-set formats, Complete / Undo Game, and “Back to Schedule”.','Bottom of the card'),
      opt('App-bar QR menu','“Export scorecard” hands the match to another phone; “Manually Set Score” writes the final score straight in.','At 0–0 and again once complete — hidden mid-match, so nobody exports half a game'),
      opt('Landscape','Turn the phone and the same controls rearrange for a net post or a side table.','Any time'),
    ], ['Control','What it does','When you see it']),
    sect('The card itself','i-south'),
    grid([
      {icon:'i-score', label:'Classic scorecard', cap:'What the other modes on this card do differently.', to:'sc-classic'},
    ]),
  ],
  next:['sc-classic','m-league'],
},

/* ── Elimination · the three steps ──────────────────────────────────── */

'm-elimination-hub': {
  title:'Setting up an Elimination', route:'/guide/modes/elimination/tournament-hub', icon:'i-trophy', parent:'m-elimination',
  eyebrow:'Elimination · Tournament Hub',
  h1:['Setting up an ','Elimination'],
  lead:'Add the teams, choose one life or two, and TournaQ builds the draw — byes included, where the field does not divide evenly.',
  blocks:[
    panel('What you set',null,[
      item('i-people','Teams and courts','Team count, courts and match format, the same as every bracket mode.'),
      item('i-shield','One life or two','Whether a first loss ends the event, or drops a team into the losers bracket instead.'),
      item('i-swap','Seeding','Decides who meets whom, so the strongest teams do not knock each other out in round one.'),
      item('i-bracket','Byes','Where the field is not a power of two, TournaQ works out the byes rather than making you do it.'),
    ]),
    fbox('i-bracket','The draw it produced','Before a point is played you can see the whole bracket — every first-round pairing, every bye, and the path each team would take to the final.'),
    sect('Every setting on the page','i-south'),
    opts('Elimination · Tournament Setup',[
      opt('Teams','4, 6, 8, 10, 12, 16 — or type any number','8 · 2 to 64',
        {what:'The size of the draw, and therefore how many byes it needs.'}),
      opt('Courts','1 to 6 from the list, or type your own','2 · 1 to 32',
        {what:'How many matches run at the same time.'}),
      opt('Referees','Fill every court · Keep a referee free','Fill every court',
        {what:'Whether the schedule holds a court back so every match has a referee from the field.',
         when:'Selectable only once the field cannot staff every court; the footnote says how much time reserving costs.'}),
      opt('Style','1vs1 through 6vs6','2vs2',
        {what:'How many players a side fields.'}),
      opt('Format','Single Elimination · Double Elimination','Single Elimination',
        {what:'One life or two — the choice that decides which of the fields below you even see.',
         help:'“Single elimination: lose once and you’re out. Shortest format, fixed finish time. Double elimination: winners and losers brackets — you need two losses to be eliminated. Roughly twice the matches. On eight teams: 7 matches single, 14 double.”'}),
      opt('Generation','Random · Seeded','Random',
        {what:'How the draw is made.',
         when:'“Seeded” is listed but greyed out — it is not shipped yet.'}),
      opt('Odd Teams','Byes · Play-in · Play-in+','Byes',
        {what:'What happens when the field is not a power of two.',
         when:'Single elimination only — double elimination fixes this to byes and says so under the grand-final field. “Play-in+” is greyed out.',
         help:'“Byes — Top seeds skip round 1 and wait. Weaker seeds play first. Fastest setup — ideal when you want to reward higher seedings without extra matches.” · “Play-in — Bottom seeds play a preliminary round to earn their bracket spot. Nobody gets a free pass — every team has to win to advance.”'}),
      opt('Grand final','Single match · Bracket reset','Single match',
        {what:'How the title is settled between an unbeaten team and one that already lost.',
         when:'Double elimination only.',
         help:'“The winners bracket champion reaches the grand final undefeated; the losers champion already has one loss. Single match: one game decides the title, whoever wins it. Bracket reset: if the losers champion wins, both sides have one loss and a decider is played. Fairer, but the finish time is not fixed.”'}),
      opt('Second chance','All rounds, or “Through round {n}”','All rounds · 1 to one less than the number of main rounds',
        {what:'From which round on a defeat is simply final.',
         when:'Double elimination only, and only once the bracket has more than one main round.',
         help:'“Who drops into the losers bracket after a defeat. All rounds is true double elimination — every loss earns a second life. Capping it shortens the tournament: losers from later rounds are out straight away. On eight teams, capping at round 1 is 11 matches instead of 14.”'}),
      opt('Fill empty places','On / off','On',
        {what:'What a spare place in the losers bracket is worth.',
         when:'Double elimination only.',
         help:'“Give a spare losers-bracket place to the best eliminated team instead of a bye”'}),
    ]),
    sect('The rest of the page','i-south'),
    opts('Below the grid — Schedule Preview, roster, name',[
      opt('Start date','Date picker','Today · yesterday to +365 days',
        {what:'Where the plan starts counting — and what makes a two-day event possible.'}),
      opt('Start time','Time picker','One hour from now',
        {what:'The anchor every other time on the page is measured from.'}),
      opt('Game format','Opens the format sheet — sets, target score, side change','1 × 15, sides every 5',
        {what:'How much actually gets played in one match.',
         when:'Once a single round is set differently, the row adds “{count} rounds differ”.',
         help:'“Applies to every round. Individual rounds can differ.”'}),
      opt('Sets per game','1, 3, 5','1',
        {what:'In the format sheet. Best-of format of a match.'}),
      opt('Target score','11, 15, 21, or a number you type','15 · from 1',
        {what:'Points that win a set.'}),
      opt('Side change','Off, 5, 7, or a number you type','Every 5 points · from 1',
        {what:'How often the teams swap ends. “Off” switches it away entirely.'}),
      opt('Notify at target score','On / off','On',
        {help:'“Prompt to finish when a side reaches the target”'}),
      opt('Game pace','Fast · 45s, Standard · 60s, Relaxed · 80s, or a number you type','Standard · 60s · from 5s',
        {what:'The one free variable in a points-target schedule — and the reason the finish time moves.',
         when:'The sheet shows “about {minutes} min a game” underneath.',
         help:'“How long a rally takes on average. Drives every time estimate for this tournament.”'}),
      opt('Break after a slot','0, 5, 10, 15, 20, 30, 45, 60 min, or a length you type','No break · 0 to 1440 min',
        {what:'Lunch, a prize-giving, the gap between two halls.',
         when:'The last slot has nothing to break before. Until you set one, the row reads “Add break”.'}),
      opt('Format for one slot','The same format sheet, plus “Use the default”','Inherits the tournament format',
        {what:'One round played shorter or longer than the rest.',
         when:'Sits in the expanded schedule detail. The reset only appears while that slot really differs.'}),
      opt('Anchored start','“Set start day &amp; time”, or “Remove — back to auto”','Automatic',
        {what:'Pins one slot to a real clock time — a second day, a fixed evening slot.',
         when:'An anchored slot is marked “custom start”.'}),
      opt('Schedule detail','“Show all {count} slots” / “Hide detail”','Collapsed above 4 slots',
        {what:'The slot-by-slot list, and the summary that stands in for it when it is folded away: slots and matches, duration each, the sum of the breaks, anchored starts.'}),
      opt('Pace alerts','On / off','Off',
        {what:'Marks rounds as on track, due or overdue once the event is running.',
         help:'“Flag rounds as on track, due, or overdue”'}),
      opt('Teams','Create new, add from Administration, group chips, search, “Add all ({count})”','Empty',
        {what:'Who is actually taking part. The tile is grey while empty, red while the count is wrong, olive once it matches.',
         when:'Only saved teams that field exactly the Style you chose are offered — a 2vs2 event will not list a three-player team. A name already on the list asks first: “{name} is already added to this tournament. Add anyway?”'}),
      opt('Clear all','Button, with a confirmation','—',
        {when:'“This will remove all added players from the list.”'}),
      opt('Confirm the count','Adjust the plan, or keep it and fix the line-up','—',
        {what:'What happens when you add more or fewer teams than you planned for.',
         help:'“You added {selected} teams, but the setup is planned for {target}. Adjusting updates the bracket, seeding and schedule — keep {target} if you’d rather review the line-up first.”'}),
      opt('Tournament Name','Free text, plus a suggest button','A random name in the mode’s own style',
        {when:'Create stays disabled while the name is empty.',
         help:'“Suggest a name”'}),
      opt('Create Tournament','The button that ends setup','Disabled until the page is ready',
        {what:'Needs a name, at least two teams and a full roster.',
         when:'The line above it reads “Ready to start!” or “Setup looks good!” — otherwise “Add all {count} teams to continue”, or “Setup incomplete”.'}),
    ]),
  ],
  next:['m-elimination-run','tournament-hub'],
  /* ══ INBOX · migriert aus pages/modes/ko-system.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Eliminations page · to review','i-south'),
    fbox('i-trophy','The Eliminations hub','New Tournament starts a bracket. Below it sits your history, each entry showing the date, the team count and how far it got.'),
  ],
},

'm-elimination-run': {
  title:'Running an Elimination', route:'/guide/modes/elimination/tournament', icon:'i-grid', parent:'m-elimination',
  eyebrow:'Elimination · Running it',
  h1:['Running an ','Elimination'],
  lead:'Round by round, or court by court — whichever matches how the day is actually being run.',
  blocks:[
    panel('What the screen gives you',null,[
      item('i-bracket','The bracket, live','Standings and the tree update as results land, with the progress ring showing how much of the draw has been decided.'),
      item('i-court','By court','The same matches regrouped so each court lists its own sequence — the view to hand someone running one court all day.'),
      item('i-grid','Who is on which court','The allocation grid lays the rounds against the courts, so you can see where the bottleneck is before it becomes one.'),
    ]),
    sect('Every pill on the page','i-south'),
    opts('Elimination · the pill row',[
      opt('“Bracket” / “Standings”','Double elimination opens the bracket canvas; single elimination opens the standings.','Opens the view'),
      opt('“Allocation”','The court grid: which fixture is on which court, and the one place to change that.','Opens the grid'),
      opt('“{n} teams”','Opens the roster: edit a team, swap one for another, or withdraw it mid-event.','Opens a sheet'),
      opt('“2v2”','The team size the draw was built against.','Statement — changing it would reshuffle every fixture, so nothing edits it'),
      opt('“Single Elimination” / “Double Elimination”','Which shape this draw plays. Switching means redrawing, which is why the window closes with the first result.','Edit here until the first match starts — then “The draw is set”'),
      opt('“{n} courts”','How many run at once. Only the unplayed part is re-timed, so nothing already played moves.','Edit here — until nothing is left to reschedule, and never below a court with a live match'),
      opt('“Refs covered” / “{n} without a ref”','Says whether the matches about to start have anyone to referee them, and lets you switch coverage.','Edit here — applies from the next unplayed round'),
      opt('“Random”','How the draw was made.','Statement — seeded draws are built but not released, so there is one reachable value'),
      opt('“Redraw”','Roll every pairing again with the settings unchanged — the answer to “I don’t like this draw”.','Edit here until the first match starts'),
      opt('“Adjust draw”','Place a team by hand instead of rolling again. Always an exchange: pick a team, pick where it should go, pick who comes back the other way.','Edit here until the first match starts'),
      opt('“Byes” / “Play-in”','How an odd field is handled. Single elimination only — double elimination always uses byes and says so under the grand-final pill.','Edit here until the first match starts'),
      opt('“Single match” / “Bracket reset”','How the grand final is settled. Double elimination only — and deliberately editable late, because you know whether you want a reset once you can see who reached the final.','Edit here until the grand final has been played'),
      opt('“{n} byes”','Which teams skipped a round. Shown whether or not there are any, so the row keeps its shape.','Opens the list — no tap while the count is zero'),
      opt('“{n} walkovers”','The matches a withdrawal decided without anyone taking a court.','Opens the list — no tap while the count is zero'),
      opt('“Ends {time}”','The projected finish, read off the laid-out schedule rather than an ideal.','Opens the timeline — start time, each round’s format and break, and the pace-alerts switch'),
    ], ['Pill','What it does','Editable here?']),
    sect('The rest of the page','i-south'),
    grid([
      {icon:'i-edit', label:'Tournament page controls', cap:'QR, workbook, renaming — and why a pill locks.', to:'tournament-controls'},
    ]),
  ],
  next:['m-elimination-score','tournament'],
  /* ══ INBOX · migriert aus pages/modes/ko-system.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Eliminations page · to review','i-south'),
    panel('Deciding it','The bracket resolves itself. When the final is played there is nothing to calculate — the tree already says who won.',[
      item('i-check','The completed bracket',
        'Every match played and every result in place, from the first round through to the final.'),
      item('i-trophy','Final standings',
        'The closing order, with the winner at the top and everyone placed by how far they got.'),
    ]),
    panel('Reusing and sharing it','A bracket you run every month is worth keeping, and a result scored on someone else’s phone is worth taking back.',[
      item('i-copy','Run it again next time',
        'Copy a tournament and you get its settings, its courts and its format as a fresh event — so the monthly open takes a minute to set up rather than a rebuild from scratch.'),
      item('i-qr','Scores from another phone',
        'A scorecard scored on someone else’s device arrives marked as imported, so a bracket run across two phones can be folded back into one.'),
    ]),
  ],
},

'm-elimination-score': {
  title:'Scoring an Elimination match', route:'/guide/modes/elimination/scorecard', icon:'i-score', parent:'m-elimination',
  eyebrow:'Elimination · Scorecard',
  h1:['Scoring an ','Elimination match'],
  lead:'The same scorecard as everywhere else, and the same escape hatch when a match was played while you were looking the other way.',
  blocks:[
    panel('On the card',null,[
      item('i-score','Portrait','Tap a side to award the point. The server is highlighted and service passes automatically when the other side scores.'),
      item('i-swap','Landscape','Turn the phone and the controls rearrange for a net post or a side table. The layout changes, the functions do not.'),
      item('i-edit','Or enter the result','Type the final score straight in and the bracket advances exactly as if you had tapped through every rally.'),
    ]),
    fbox('i-check','Which card this is','The classic scorecard — sets, target points and side switches. The same one every team competition uses.'),
    sect('What this card gives you','i-south'),
    opts('Elimination · the scorecard',[
      opt('The pill row','Event name, the position in the draw (“Quarter-final · Match 3”), court, sets, target points and duration. The bracket or standings, the allocation grid, byes and walkovers open from here; the draw settings are padlocked','Under the title'),
      opt('Schedule card','This match’s planned start and end, and “Over schedule!” when it runs long.','Only while pace alerts are on for the event'),
      opt('Set overview','One card per set with its score; tap one to make it the active set.','Formats of more than one set'),
      opt('Serves-first banner','Who starts the match serving, before anyone has scored.','Until the first point — dropped in landscape for room'),
      opt('Referee banner','“{name} suggested as referee”, or “Assign a referee manually”.','When the event reserves referees'),
      opt('Score buttons','Plus awards the point to that side, minus takes one back. Service passes to whoever just scored and the rotation moves on a slot. The score cannot go below zero.','Until the set or match is complete'),
      opt('Side-change reminder','“Total score is {score}. Teams must switch sides now.” Confirm with “Sides Switched — Continue” and the counters swap with you.','When the format carries a side-change interval'),
      opt('Target-reached prompt','“{team} reached the target. Set {set} is won.” — then “Complete Set” (or “Complete Game”), or “Keep Playing” if the day’s rules say win by two.','On reaching the target score, while the format’s prompt is on'),
      opt('Match Options','“Swap Sides — Switch left and right display”, “Change Service — Advance to next server”, “Match History — View point-by-point history”.','The slider icon beside Gameplay Controls'),
      opt('Match History','The rally-by-rally timeline, grouped by set — “Set {n} · to {target}”, ending in “Final: {s1} – {s2}”.','From Match Options'),
      opt('Lock banner','“Match complete” with the winner’s name, or “Set complete — undo set to edit score”. The score buttons go quiet behind it.','Once a set or the match is finished'),
      opt('Match controls','“Start Match” before the first point; then Complete / Undo Set on multi-set formats, Complete / Undo Game, and “Back to Schedule”.','Bottom of the card'),
      opt('App-bar QR menu','“Export scorecard” hands the match to another phone; “Manually Set Score” writes the final score straight in.','At 0–0 and again once complete — hidden mid-match, so nobody exports half a game'),
      opt('Winner-can’t-change guard','“The next match has already started, so the winner of this match can’t change. You can still correct the points as long as the same team wins.”','When the following match is already under way'),
      opt('Landscape','Turn the phone and the same controls rearrange for a net post or a side table.','Any time'),
    ], ['Control','What it does','When you see it']),
    sect('The card itself','i-south'),
    grid([
      {icon:'i-score', label:'Classic scorecard', cap:'What the other modes on this card do differently.', to:'sc-classic'},
    ]),
  ],
  next:['sc-classic','m-elimination'],
},

/* ── TournaQ Classic · the three steps ──────────────────────────────── */

'm-classic-hub': {
  title:'Setting up a TournaQ Classic', route:'/guide/modes/tournaq-classic/tournament-hub', icon:'i-trophy', parent:'m-classic',
  eyebrow:'TournaQ Classic · Tournament Hub',
  h1:['Setting up a ','TournaQ Classic'],
  lead:'Add the teams and say how many groups you want. TournaQ divides the field, builds both stages and tells you what it will cost in time.',
  blocks:[
    panel('What you set',null,[
      item('i-people','Groups and courts','Team count, number of groups, courts and match format.'),
      item('i-trophy','Qualification','How many teams from each group go through to the knockout stage.'),
      item('i-grid','An uneven field is handled','The groups simply come out different sizes rather than the setup refusing you.'),
    ]),
    fbox('i-clock','The schedule covers both stages','Every pool match, grouped and timed, before a point is played — and the finish time you are shown is the real one, not just the group stage. If it does not fit the day, change the courts or the match length and look again.'),
    sect('Every setting on the page','i-south'),
    opts('TournaQ Classic · Tournament Setup',[
      opt('Teams','4, 6, 8, 10, 12, 16 — or type any number','8 · 2 to 64',
        {what:'The size of the field. Group sizes and the number of qualifiers follow from it.'}),
      opt('Courts','1 to 6 from the list, or type your own','2 · 1 to 32',
        {what:'How many matches run at the same time.',
         when:'Beyond teams ÷ 2 the extra courts stay empty: “Only {usable} courts can be used with {teams} teams — every team plays once per slot.”'}),
      opt('Referees','Fill every court · Keep a referee free','Fill every court',
        {what:'Whether the schedule holds a court back so every match has a referee from the field.',
         when:'Selectable only once the field cannot staff every court.'}),
      opt('Style','1vs1 through 6vs6','2vs2',
        {what:'How many players a side fields.'}),
      opt('Legs','Single · Double','Single',
        {what:'Whether the group stage plays each pairing once or twice. The knockout is unaffected.',
         help:'“Single — Every pair of teams meets exactly once. The shortest format — ideal for a single session.” · “Double — Every pair meets twice, the second time with the sides reversed. Twice the rounds, and a fairer table.”'}),
      opt('Generation','Random · Seeded','Random',
        {what:'How the groups are drawn.',
         when:'“Seeded” is listed but greyed out — it is not shipped yet.'}),
      opt('Groups','2 up to teams ÷ 2','2 · at most 8',
        {what:'The only sizing control on the page — group sizes are derived from it.',
         help:'“Group count is the only sizing control — sizes follow from it. 17 teams into 4 groups gives one group of 5 and three of 4. That is normal and nothing breaks, but teams in the bigger group play one more match, so when the app compares teams across groups it uses points per match rather than totals. More groups is not automatically better: it raises the number of qualifiers, which can push a tier onto a bigger bracket with more byes.”'}),
      opt('One court per group','On / off','On',
        {what:'Keeps a group — and later a tier — on a court of its own.',
         when:'Only takes effect where the courts divide; otherwise it quietly does nothing.',
         help:'“Give each group, and then each tier, a court of its own where the courts allow it.”'}),
      opt('Back-to-back','Never · Up to 2 · No limit','Up to 2',
        {what:'How hard the schedule may pack the courts before a team gets a rest.',
         help:'“Never — Every team gets a slot off between matches. Kindest on players, but the longest schedule.” · “Up to 2 — A team plays at most two slots in a row before resting.” · “No limit — Pack the courts as tightly as the fixtures allow. The shortest day, but a team can play many matches in a row.”'}),
    ]),
    opts('TournaQ Classic · Qualification',[
      opt('Where each place goes','Gold, Silver, Bronze … or “Out”','1st and 2nd to Gold, everyone else out · at most 8 tiers',
        {what:'Row by row, what finishing 1st, 2nd, 3rd in a group is worth.',
         when:'Only the next unused tier can be opened — no Bronze without a Silver — and gaps close themselves if you send a place Out afterwards. With uneven groups a row says “only {have} of {total} groups have one”.'}),
      opt('Format per tier','Single elimination · Double elimination','Single elimination',
        {what:'Set on the tier itself, so a consolation bracket can give knocked-out teams a second life while the top tier runs clean.'}),
      opt('Seeding per tier','Cross-group · Overall rank · Random','Cross-group',
        {what:'How that tier’s qualifiers are drawn against each other.',
         help:'“Cross-group pairs each group winner with another group’s runner-up, and keeps two teams from the same group in opposite halves so they can only meet in the final. Overall rank ranks every qualifier across all groups — on points per match, so uneven groups compare fairly — and seeds them best against worst. Random draws the qualifiers out of a hat.”'}),
      opt('Break before knockout','0 to 60 min from the list, or a length you type','15 min · 0 to 1440 min',
        {what:'The changeover between the two phases. Editable in the timeline, at the point where it happens.'}),
    ]),
    sect('The rest of the page','i-south'),
    opts('Below the grid — Schedule Preview, roster, name',[
      opt('Start date','Date picker','Today · yesterday to +365 days',
        {what:'Where the plan starts counting — and what makes a two-day event possible.'}),
      opt('Start time','Time picker','One hour from now',
        {what:'The anchor every other time on the page is measured from.'}),
      opt('Game format','Opens the format sheet — sets, target score, side change','1 × 15, sides every 5',
        {what:'How much actually gets played in one match.',
         when:'Once a single round is set differently, the row adds “{count} rounds differ”.',
         help:'“Applies to every round. Individual rounds can differ.”'}),
      opt('Sets per game','1, 3, 5','1',
        {what:'In the format sheet. Best-of format of a match.'}),
      opt('Target score','11, 15, 21, or a number you type','15 · from 1',
        {what:'Points that win a set.'}),
      opt('Side change','Off, 5, 7, or a number you type','Every 5 points · from 1',
        {what:'How often the teams swap ends. “Off” switches it away entirely.'}),
      opt('Notify at target score','On / off','On',
        {help:'“Prompt to finish when a side reaches the target”'}),
      opt('Game pace','Fast · 45s, Standard · 60s, Relaxed · 80s, or a number you type','Standard · 60s · from 5s',
        {what:'The one free variable in a points-target schedule — and the reason the finish time moves.',
         when:'The sheet shows “about {minutes} min a game” underneath.',
         help:'“How long a rally takes on average. Drives every time estimate for this tournament.”'}),
      opt('Break after a slot','0, 5, 10, 15, 20, 30, 45, 60 min, or a length you type','No break · 0 to 1440 min',
        {what:'Lunch, a prize-giving, the gap between two halls.',
         when:'The last slot has nothing to break before. Until you set one, the row reads “Add break”.'}),
      opt('Format for one slot','The same format sheet, plus “Use the default”','Inherits the tournament format',
        {what:'One round played shorter or longer than the rest.',
         when:'Sits in the expanded schedule detail. The reset only appears while that slot really differs.'}),
      opt('Anchored start','“Set start day &amp; time”, or “Remove — back to auto”','Automatic',
        {what:'Pins one slot to a real clock time — a second day, a fixed evening slot.',
         when:'An anchored slot is marked “custom start”.'}),
      opt('Schedule detail','“Show all {count} slots” / “Hide detail”','Collapsed above 4 slots',
        {what:'The slot-by-slot list, and the summary that stands in for it when it is folded away: slots and matches, duration each, the sum of the breaks, anchored starts.',
         when:'On a Classic the preview splits in two: the group slots and the knockout slots fold open separately.'}),
      opt('Pace alerts','On / off','Off',
        {what:'Marks rounds as on track, due or overdue once the event is running.',
         help:'“Flag rounds as on track, due, or overdue”'}),
      opt('Teams','Create new, add from Administration, group chips, search, “Add all ({count})”','Empty',
        {what:'Who is actually taking part. The tile is grey while empty, red while the count is wrong, olive once it matches.',
         when:'Only saved teams that field exactly the Style you chose are offered — a 2vs2 event will not list a three-player team. A name already on the list asks first: “{name} is already added to this tournament. Add anyway?”'}),
      opt('Clear all','Button, with a confirmation','—',
        {when:'“This will remove all added players from the list.”'}),
      opt('Confirm the count','Adjust the plan, or keep it and fix the line-up','—',
        {what:'What happens when you add more or fewer teams than you planned for.',
         help:'“You added {selected} teams, but the setup is planned for {target}. Adjusting updates the bracket, seeding and schedule — keep {target} if you’d rather review the line-up first.”'}),
      opt('Tournament Name','Free text, plus a suggest button','A random name in the mode’s own style',
        {when:'Create stays disabled while the name is empty.',
         help:'“Suggest a name”'}),
      opt('Create Tournament','The button that ends setup','Disabled until the page is ready',
        {what:'Needs a name, at least two teams and a full roster.',
         when:'The line above it reads “Ready to start!” or “Setup looks good!” — otherwise “Add all {count} teams to continue”, or “Setup incomplete”.'}),
    ]),
  ],
  next:['m-classic-run','tournament-hub'],
  /* ══ INBOX · migriert aus pages/modes/group-single-elimination.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the TournaQ Classics page · to review','i-south'),
    fbox('i-trophy','The Classics hub','New Tournament starts an event. Below it sits your history, each entry showing the date, the team count and how far it got.'),
    fbox('i-people','Fifteen teams, four groups','The setup form takes the larger field and divides it, unevenly where it has to. Nothing is refused for not being a round number.'),
  ],
},

'm-classic-run': {
  title:'Running a TournaQ Classic', route:'/guide/modes/tournaq-classic/tournament', icon:'i-grid', parent:'m-classic',
  eyebrow:'TournaQ Classic · Running it',
  h1:['Running a ','TournaQ Classic'],
  lead:'The group stage looks like a league; the knockout looks like a bracket. The same screen carries both, in the order they happen.',
  blocks:[
    panel('What the screen gives you',null,[
      item('i-grid','The schedule, live','Pool matches grouped by round with their courts, times and scores, and a progress ring showing how much of the event has been played.'),
      item('i-court','By court','The same matches regrouped so each court lists its own sequence — the view to hand someone running one court all day.'),
      item('i-clock','Who is on which court','The allocation grid lays the rounds against the courts, so you can see the shape of the day and where it will get tight.'),
    ]),
    sect('Every pill on the page','i-south'),
    opts('TournaQ Classic · the pill row',[
      opt('“Standings”','The group tables, and from there the knockout tiers.','Opens the tables'),
      opt('“Allocation”','The court grid: which fixture is on which court, and the one place to change that.','Opens the grid'),
      opt('“{n} teams”','Opens the roster: edit a team, swap one for another, or withdraw it mid-event.','Opens a sheet'),
      opt('“2v2”','The team size the draw was built against.','Statement — changing it would reshuffle every fixture, so nothing edits it'),
      opt('“{n} courts”','How many run at once. Only the unplayed part is re-timed, so nothing already played moves.','Edit here — until nothing is left to reschedule, and never below a court with a live match'),
      opt('“Refs covered” / “{n} without a ref”','Says whether the matches about to start have anyone to referee them, and lets you switch coverage.','Edit here — applies from the next unplayed round'),
      opt('“Random”','How the draw was made.','Statement — seeded draws are built but not released, so there is one reachable value'),
      opt('“Single” / “Double”','Whether the group stage plays each pairing once or twice.','Edit here until the first match starts — then “The draw is set”'),
      opt('“Redraw”','Draw the groups again with the settings unchanged.','Edit here until the first match starts'),
      opt('“Adjust draw”','Move one team between groups by hand — always exchanged with another, so no group grows.','Edit here until the first match starts'),
      opt('“{n} walkovers”','The matches a withdrawal decided without anyone taking a court.','Opens the list — no tap while the count is zero'),
      opt('“Ends {time}”','The projected finish, read off the laid-out schedule rather than an ideal.','Opens the timeline — start time, each round’s format and break, and the pace-alerts switch'),
    ], ['Pill','What it does','Editable here?']),
    sect('The rest of the page','i-south'),
    grid([
      {icon:'i-edit', label:'Tournament page controls', cap:'QR, workbook, renaming — and why a pill locks.', to:'tournament-controls'},
    ]),
  ],
  next:['m-classic-score','tournament'],
  /* ══ INBOX · migriert aus pages/modes/group-single-elimination.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the TournaQ Classics page · to review','i-south'),
    panel('Deciding it','When the pools finish the bracket fills itself from the qualification rule, and the final decides the event.',[
      item('i-check','The completed schedule',
        'Every pool match and every knockout tie played, with the progress ring at a hundred per cent.'),
      item('i-trophy','Final standings',
        'The closing order across the whole event, placing every team by how far they got rather than only naming a winner.'),
    ]),
    panel('The same format, under load','Nothing new to learn: the same form, the same schedule, the same tables — just more of them.',[
      item('i-clock','The schedule it built',
        'Every pool match across four groups, timed and assigned to courts, before anyone plays.'),
      item('i-grid','Four tables at once',
        'Each group keeps its own standings, and qualification is read off all four together.'),
    ]),
  ],
},

'm-classic-score': {
  title:'Scoring a TournaQ Classic match', route:'/guide/modes/tournaq-classic/scorecard', icon:'i-score', parent:'m-classic',
  eyebrow:'TournaQ Classic · Scorecard',
  h1:['Scoring a ','TournaQ Classic match'],
  lead:'The same scorecard through both stages — a pool match and a semi-final are scored identically.',
  blocks:[
    panel('On the card',null,[
      item('i-score','Portrait','Tap a side to award the point. The server is highlighted and service passes automatically when the other side scores.'),
      item('i-swap','Landscape','Turn the phone and the controls rearrange for a net post or a side table. The layout changes, the functions do not.'),
      item('i-trophy','Group standings','Each group table updates as its results land, so teams can see whether they are qualifying while the pool stage is still running.'),
    ]),
    fbox('i-check','Which card this is','The classic scorecard — sets, target points and side switches. The same one every team competition uses.'),
    sect('What this card gives you','i-south'),
    opts('TournaQ Classic · the scorecard',[
      opt('The pill row','Event name, which phase and tier the match belongs to, court, sets, target points and duration. The group tables and the tiers behind them, the allocation grid and the walkovers list open from here','Under the title'),
      opt('Schedule card','This match’s planned start and end, and “Over schedule!” when it runs long.','Only while pace alerts are on for the event'),
      opt('Set overview','One card per set with its score; tap one to make it the active set.','Formats of more than one set'),
      opt('Serves-first banner','Who starts the match serving, before anyone has scored.','Until the first point — dropped in landscape for room'),
      opt('Referee banner','“{name} suggested as referee”, or “Assign a referee manually”.','When the event reserves referees'),
      opt('Score buttons','Plus awards the point to that side, minus takes one back. Service passes to whoever just scored and the rotation moves on a slot. The score cannot go below zero.','Until the set or match is complete'),
      opt('Side-change reminder','“Total score is {score}. Teams must switch sides now.” Confirm with “Sides Switched — Continue” and the counters swap with you.','When the format carries a side-change interval'),
      opt('Target-reached prompt','“{team} reached the target. Set {set} is won.” — then “Complete Set” (or “Complete Game”), or “Keep Playing” if the day’s rules say win by two.','On reaching the target score, while the format’s prompt is on'),
      opt('Match Options','“Swap Sides — Switch left and right display”, “Change Service — Advance to next server”, “Match History — View point-by-point history”.','The slider icon beside Gameplay Controls'),
      opt('Match History','The rally-by-rally timeline, grouped by set — “Set {n} · to {target}”, ending in “Final: {s1} – {s2}”.','From Match Options'),
      opt('Lock banner','“Match complete” with the winner’s name, or “Set complete — undo set to edit score”. The score buttons go quiet behind it.','Once a set or the match is finished'),
      opt('Match controls','“Start Match” before the first point; then Complete / Undo Set on multi-set formats, Complete / Undo Game, and “Back to Schedule”.','Bottom of the card'),
      opt('App-bar QR menu','“Export scorecard” hands the match to another phone; “Manually Set Score” writes the final score straight in.','At 0–0 and again once complete — hidden mid-match, so nobody exports half a game'),
      opt('Landscape','Turn the phone and the same controls rearrange for a net post or a side table.','Any time'),
    ], ['Control','What it does','When you see it']),
    sect('The card itself','i-south'),
    grid([
      {icon:'i-score', label:'Classic scorecard', cap:'What the other modes on this card do differently.', to:'sc-classic'},
    ]),
  ],
  next:['sc-classic','m-classic'],
},

/* ── Swiss System · the three steps ─────────────────────────────────── */

'm-swiss-hub': {
  title:'Setting up a Swiss System', route:'/guide/modes/swiss-system/tournament-hub', icon:'i-trophy', parent:'m-swiss',
  eyebrow:'Swiss System · Tournament Hub',
  h1:['Setting up a ','Swiss System'],
  lead:'Add the teams and choose how many rounds. That is the whole decision — the pairings are worked out as you go, not in advance.',
  blocks:[
    panel('What you set',null,[
      item('i-people','Teams, rounds, courts','Team count, number of rounds, courts and match format.'),
      item('i-target','How many rounds','Fewer rounds is a rougher ranking, more rounds a sharper one. The preview tells you what each costs in time.'),
      item('i-swap','No draw to seed','After round one the results do the seeding for you.'),
    ]),
    fbox('i-sync','Only round one is drawn','The schedule shows round one in full and later rounds as "paired after round 1" and "paired after round 2". That is the format working as intended — it cannot know who plays whom until it knows who won.'),
    sect('Every setting on the page','i-south'),
    opts('Swiss System · Tournament Setup',[
      opt('Teams','4, 6, 8, 10, 12, 16 — or type any number','8 · 2 to 64',
        {what:'The size of the field, and what the automatic round count is calculated from.',
         when:'An odd field gets a note straight away: “One team sits out each round. The bye rotates.”'}),
      opt('Courts','1 to 6 from the list, or type your own','2 · 1 to 32',
        {what:'How many matches run at the same time.',
         when:'Beyond teams ÷ 2 the extra courts stay empty — every team plays once per round.'}),
      opt('Referees','Fill every court · Keep a referee free','Fill every court',
        {what:'Whether the schedule holds a court back so every match has a referee from the field.',
         when:'Selectable only once the field cannot staff every court.'}),
      opt('Style','1vs1 through 6vs6','2vs2',
        {what:'How many players a side fields.'}),
      opt('Rounds','“Auto ({n})”, or 2 up to the maximum','Auto · maximum is teams − 1, never above 9',
        {what:'The one thing that is fixed before the draw: Swiss pairs each round from the one before it.',
         when:'Auto is resolved into a real number when you create the event, so a later withdrawal cannot silently shorten it.',
         help:'“Auto — Enough rounds that only one team can stay unbeaten — log₂ of the field, rounded up.” · “Fewer rounds — Quicker, but more teams finish level and the tiebreak decides more places.” · “More rounds — Separates the field further. Every extra round is another slot on the clock.” · “Maximum here: {max} rounds — beyond that a rematch is unavoidable.”'}),
      opt('Generation','Random · Seeded','Random',
        {what:'How the first round is paired.',
         when:'“Seeded” is listed but greyed out — it is not shipped yet.'}),
    ]),
    sect('The rest of the page','i-south'),
    opts('Below the grid — Schedule Preview, roster, name',[
      opt('Start date','Date picker','Today · yesterday to +365 days',
        {what:'Where the plan starts counting — and what makes a two-day event possible.'}),
      opt('Start time','Time picker','One hour from now',
        {what:'The anchor every other time on the page is measured from.'}),
      opt('Game format','Opens the format sheet — sets, target score, side change','1 × 15, sides every 5',
        {what:'How much actually gets played in one match.',
         when:'Once a single round is set differently, the row adds “{count} rounds differ”.',
         help:'“Applies to every round. Individual rounds can differ.”'}),
      opt('Sets per game','1, 3, 5','1',
        {what:'In the format sheet. Best-of format of a match.'}),
      opt('Target score','11, 15, 21, or a number you type','15 · from 1',
        {what:'Points that win a set.'}),
      opt('Side change','Off, 5, 7, or a number you type','Every 5 points · from 1',
        {what:'How often the teams swap ends. “Off” switches it away entirely.'}),
      opt('Notify at target score','On / off','On',
        {help:'“Prompt to finish when a side reaches the target”'}),
      opt('Game pace','Fast · 45s, Standard · 60s, Relaxed · 80s, or a number you type','Standard · 60s · from 5s',
        {what:'The one free variable in a points-target schedule — and the reason the finish time moves.',
         when:'The sheet shows “about {minutes} min a game” underneath.',
         help:'“How long a rally takes on average. Drives every time estimate for this tournament.”'}),
      opt('Break after a slot','0, 5, 10, 15, 20, 30, 45, 60 min, or a length you type','No break · 0 to 1440 min',
        {what:'Lunch, a prize-giving, the gap between two halls.',
         when:'The last slot has nothing to break before. Until you set one, the row reads “Add break”.'}),
      opt('Format for one slot','The same format sheet, plus “Use the default”','Inherits the tournament format',
        {what:'One round played shorter or longer than the rest.',
         when:'Sits in the expanded schedule detail. The reset only appears while that slot really differs.'}),
      opt('Anchored start','“Set start day &amp; time”, or “Remove — back to auto”','Automatic',
        {what:'Pins one slot to a real clock time — a second day, a fixed evening slot.',
         when:'An anchored slot is marked “custom start”.'}),
      opt('Schedule detail','“Show all {count} slots” / “Hide detail”','Collapsed above 4 slots',
        {what:'The slot-by-slot list, and the summary that stands in for it when it is folded away: slots and matches, duration each, the sum of the breaks, anchored starts.',
         when:'A Swiss round is paired only once the one before it has been played, so the slots carry exact times but no fixtures.'}),
      opt('Pace alerts','On / off','Off',
        {what:'Marks rounds as on track, due or overdue once the event is running.',
         help:'“Flag rounds as on track, due, or overdue”'}),
      opt('Teams','Create new, add from Administration, group chips, search, “Add all ({count})”','Empty',
        {what:'Who is actually taking part. The tile is grey while empty, red while the count is wrong, olive once it matches.',
         when:'Only saved teams that field exactly the Style you chose are offered — a 2vs2 event will not list a three-player team. A name already on the list asks first: “{name} is already added to this tournament. Add anyway?”'}),
      opt('Clear all','Button, with a confirmation','—',
        {when:'“This will remove all added players from the list.”'}),
      opt('Confirm the count','Adjust the plan, or keep it and fix the line-up','—',
        {what:'What happens when you add more or fewer teams than you planned for.',
         help:'“You added {selected} teams, but the setup is planned for {target}. Adjusting updates the bracket, seeding and schedule — keep {target} if you’d rather review the line-up first.”'}),
      opt('Tournament Name','Free text, plus a suggest button','A random name in the mode’s own style',
        {when:'Create stays disabled while the name is empty.',
         help:'“Suggest a name”'}),
      opt('Create Tournament','The button that ends setup','Disabled until the page is ready',
        {what:'Needs a name, at least two teams and a full roster.',
         when:'The line above it reads “Ready to start!” or “Setup looks good!” — otherwise “Add all {count} teams to continue”, or “Setup incomplete”.'}),
    ]),
  ],
  next:['m-swiss-run','tournament-hub'],
  /* ══ INBOX · migriert aus pages/modes/swiss-system.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Swiss Systems page · to review','i-south'),
    fbox('i-trophy','The Swiss hub','New Tournament starts an event. Below it sits your history, each entry showing the date, the team count and how far it got.'),
  ],
},

'm-swiss-run': {
  title:'Running a Swiss System', route:'/guide/modes/swiss-system/tournament', icon:'i-grid', parent:'m-swiss',
  eyebrow:'Swiss System · Running it',
  h1:['Running a ','Swiss System'],
  lead:'Score a round, and the next one is paired from the results. The schedule fills in ahead of you rather than existing from the start.',
  blocks:[
    panel('What the screen gives you',null,[
      item('i-sync','Round by round','The current round with its pairings, courts and scores, and a progress ring showing how far through the event you are.'),
      item('i-court','By court','The same matches regrouped so each court lists its own sequence — the view to hand someone running one court all day.'),
      item('i-grid','Who is on which court','The allocation grid lays the rounds against the courts, so a big field spread over a few courts stays legible.'),
    ]),
    sect('Every pill on the page','i-south'),
    opts('Swiss System · the pill row',[
      opt('“Standings”','The table the next round’s pairings will be drawn from.','Opens the table'),
      opt('“Allocation”','The court grid: which fixture is on which court, and the one place to change that.','Opens the grid'),
      opt('“{n} teams”','Opens the roster: edit a team, swap one for another, or withdraw it mid-event.','Opens a sheet'),
      opt('“2v2”','The team size the draw was built against.','Statement — changing it would reshuffle every fixture, so nothing edits it'),
      opt('“{n} courts”','How many run at once. Only the unplayed part is re-timed, so nothing already played moves.','Edit here — until nothing is left to reschedule, and never below a court with a live match'),
      opt('“Refs covered” / “{n} without a ref”','Says whether the matches about to start have anyone to referee them, and lets you switch coverage.','Edit here — applies from the next unplayed round'),
      opt('“Random”','How the draw was made.','Statement — seeded draws are built but not released, so there is one reachable value'),
      opt('“Round {n} of {total}”','How far through the fixed round count the event is.','Statement'),
      opt('“Reroll round 1”','Only the opening round is a draw — every round after it is paired from the standings, so there is nothing left to roll.','Edit here while round 1 is untouched; after that it locks with “The draw is set”'),
      opt('“Adjust draw”','Exchange two teams in the opening round by hand.','Edit here while round 1 is untouched'),
      opt('“{n} byes”','An odd field sits one team out every round, and the bye rotates. This is the list of who has had one.','Opens the list — no tap while the count is zero'),
      opt('“{n} walkovers”','The matches a withdrawal decided without anyone taking a court.','Opens the list — no tap while the count is zero'),
      opt('“Ends {time}”','The projected finish, read off the laid-out schedule rather than an ideal.','Opens the timeline — start time, each round’s format and break, and the pace-alerts switch'),
    ], ['Pill','What it does','Editable here?']),
    sect('The rest of the page','i-south'),
    grid([
      {icon:'i-edit', label:'Tournament page controls', cap:'QR, workbook, renaming — and why a pill locks.', to:'tournament-controls'},
    ]),
  ],
  next:['m-swiss-score','tournament'],
  /* ══ INBOX · migriert aus pages/modes/swiss-system.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Swiss Systems page · to review','i-south'),
    panel('Finishing it','After the last round the buckets are the ranking. Nobody was eliminated, and everyone played the same number of matches.',[
      item('i-check','Every round played',
        'The complete schedule with every pairing the format produced and every result recorded.'),
      item('i-trophy','Final standings',
        'The closing order, with the winner at the top and the whole field placed — which is what a Swiss buys you that a knockout does not.'),
    ]),
  ],
},

'm-swiss-score': {
  title:'Scoring a Swiss System match', route:'/guide/modes/swiss-system/scorecard', icon:'i-score', parent:'m-swiss',
  eyebrow:'Swiss System · Scorecard',
  h1:['Scoring a ','Swiss System match'],
  lead:'The same scorecard as everywhere else — and here it matters more, because each result decides who you play next.',
  blocks:[
    panel('On the card',null,[
      item('i-score','Portrait','Tap a side to award the point. The server is highlighted and service passes automatically when the other side scores.'),
      item('i-swap','Landscape','Turn the phone and the controls rearrange for a net post or a side table. The layout changes, the functions do not.'),
      item('i-trophy','The table as it stands','Standings update after every result, and they are what the next round pairings will be built from — so the table is a preview of who you are about to play.'),
    ]),
    fbox('i-check','Which card this is','The classic scorecard — sets, target points and side switches. The same one every team competition uses.'),
    sect('What this card gives you','i-south'),
    opts('Swiss System · the scorecard',[
      opt('The pill row','Event name, the round and match, court, sets, target points and duration. The standings the next pairings come from, the allocation grid, byes and walkovers open from here','Under the title'),
      opt('Schedule card','This match’s planned start and end, and “Over schedule!” when it runs long.','Only while pace alerts are on for the event'),
      opt('Set overview','One card per set with its score; tap one to make it the active set.','Formats of more than one set'),
      opt('Serves-first banner','Who starts the match serving, before anyone has scored.','Until the first point — dropped in landscape for room'),
      opt('Referee banner','“{name} suggested as referee”, or “Assign a referee manually”.','When the event reserves referees'),
      opt('Score buttons','Plus awards the point to that side, minus takes one back. Service passes to whoever just scored and the rotation moves on a slot. The score cannot go below zero.','Until the set or match is complete'),
      opt('Side-change reminder','“Total score is {score}. Teams must switch sides now.” Confirm with “Sides Switched — Continue” and the counters swap with you.','When the format carries a side-change interval'),
      opt('Target-reached prompt','“{team} reached the target. Set {set} is won.” — then “Complete Set” (or “Complete Game”), or “Keep Playing” if the day’s rules say win by two.','On reaching the target score, while the format’s prompt is on'),
      opt('Match Options','“Swap Sides — Switch left and right display”, “Change Service — Advance to next server”, “Match History — View point-by-point history”.','The slider icon beside Gameplay Controls'),
      opt('Match History','The rally-by-rally timeline, grouped by set — “Set {n} · to {target}”, ending in “Final: {s1} – {s2}”.','From Match Options'),
      opt('Lock banner','“Match complete” with the winner’s name, or “Set complete — undo set to edit score”. The score buttons go quiet behind it.','Once a set or the match is finished'),
      opt('Match controls','“Start Match” before the first point; then Complete / Undo Set on multi-set formats, Complete / Undo Game, and “Back to Schedule”.','Bottom of the card'),
      opt('App-bar QR menu','“Export scorecard” hands the match to another phone; “Manually Set Score” writes the final score straight in.','At 0–0 and again once complete — hidden mid-match, so nobody exports half a game'),
      opt('Pairs the next round','Finishing the last match of a round draws the next one immediately — this card runs that reconcile itself, so the pairing does not wait for anyone to open the round page.','On completing a match'),
      opt('Landscape','Turn the phone and the same controls rearrange for a net post or a side table.','Any time'),
    ], ['Control','What it does','When you see it']),
    sect('The card itself','i-south'),
    grid([
      {icon:'i-score', label:'Classic scorecard', cap:'What the other modes on this card do differently.', to:'sc-classic'},
    ]),
  ],
  next:['sc-classic','m-swiss'],
},

/* ── Social Scramble · the three steps ──────────────────────────────── */

'm-social-scramble-hub': {
  title:'Setting up a Social Scramble', route:'/guide/modes/social-scramble/tournament-hub', icon:'i-trophy', parent:'m-social-scramble',
  eyebrow:'Social Scramble · Tournament Hub',
  h1:['Setting up a ','Social Scramble'],
  lead:'Tell TournaQ how many players you have, how long you have got and how many courts. It works out the rest — the number of rounds, when you will finish, and whether the plan actually plays well.',
  blocks:[
    panel('What you set',null,[
      item('i-people','Players and courts','Target players, courts and style.'),
      item('i-clock','Rounds and duration','How many rounds, how long each match runs, and the break between them.'),
      item('i-sync','Everything feeds the preview','The predicted finish time moves as you change your mind — no working out how many rounds fit in ninety minutes.'),
    ]),
    fbox('i-star','It tells you when the plan will not work','Six rounds with twelve players means some pairs never play together. TournaQ says so before you start, and offers the number of rounds that would fix it — one tap to accept. That is the difference between a session that felt fair and one that was.'),
    sect('Every setting on the page','i-south'),
    opts('Social Scramble · Tournament Setup',[
      opt('Target Players','4, 6, 8, 10, 12, 16, 20, 24 — or type any number','8 · 4 to 64',
        {what:'How many people you are planning for. The actual names are added further down.',
         help:'“How many players will take part in the session. Used to plan the schedule and rotations. The actual participants are added in the Players section below.”'}),
      opt('Courts','1, 2, 3, 4, 5, 6, 8 — or type your own','1 · 1 to 32',
        {what:'How many matches run at the same time.',
         when:'A court the field cannot fill is flagged: “Only {active} of {courts} courts can be filled with {players} players in {perTeam}v{perTeam}.”',
         help:'“Number of courts available for play. More courts allow more simultaneous matches but require more players active at once.”'}),
      opt('Style','2vs2 through 6vs6','2vs2',
        {what:'How many players a side fields.',
         when:'Too small a field for even one court blocks Create: “At least {n} players are needed for one {perTeam}v{perTeam} court.”'}),
      opt('Rounds','6, 8, 10, 12, 16, 20, 24, 30 — or type any number','12 · 1 to 999',
        {what:'How many times the teams get redrawn. This is what the suggestions below the schedule are about.',
         help:'“How many rounds to play. The suggestions below help balance fresh partnerships against the total round count.”'}),
      opt('Match Duration','5, 8, 10, 12, 15, 20, 25, 30 min — or type any number','4 min · 1 to 999 min',
        {what:'How long one round is played. There is no target score here — the clock ends the round.',
         when:'The default of 4 minutes is below the shortest preset, so the list will not show it as selected.',
         help:'“How long each individual match lasts. Longer matches mean fewer rounds but more play time per match.”'}),
      opt('Break Between Rounds','0, 2, 3, 5, 7, 10 min — or type any number','1 min · 0 to 999 min',
        {what:'The gap in which everyone finds their new court and new partner.',
         help:'“Rest time between rounds. Allows players to rotate, catch their breath, and reset before the next round starts. Set to 0 for back-to-back play.”'}),
    ]),
    fbox('i-check','What the page works out while you type','Suggestions appear under the schedule, and some carry a button that applies the fix. The first three block Create; the rest are advice.',[
      {icon:'i-clock', title:'No rounds, or a duration of zero', body:'“At least 1 round is needed to build a schedule.” and “Match and break duration must be greater than zero.” — both block Create.'},
      {icon:'i-court', title:'Not enough for a single court', body:'“At least {n} players are needed for one {perTeam}v{perTeam} court. Add more players or switch to a smaller format.” — blocks Create.'},
      {icon:'i-queue', title:'Many sitting out', body:'“{sitting} of {players} sit out each round. Full coverage needs {target} rounds; with fewer, some pairs won’t partner.”'},
      {icon:'i-people', title:'Uneven play', body:'“Uneven play at {rounds} rounds. Use a multiple of {unit} for equal games.”'},
      {icon:'i-swap', title:'Partner coverage', body:'“Some partnerships repeat. {target} rounds lets everyone partner with everyone.” — with a one-tap “Use {target} rounds”.'},
      {icon:'i-court', title:'Courts you cannot fill', body:'“Only {active} of {courts} courts can be filled with {players} players in {perTeam}v{perTeam}. Reduce courts to {active} or add more players.”'},
      {icon:'i-shield', title:'Nobody free to referee', body:'“…only {sitting} players sit out each round — {without} courts won’t have a dedicated referee and will need scores entered manually.”'},
      {icon:'i-star', title:'A very large field', body:'“With {n} players the mixing becomes statistical — everyone-against-everyone is no longer guaranteed, but equal play time still is.”'},
    ]),
    sect('The rest of the page','i-south'),
    opts('Below the grid — Schedule Preview, roster, name',[
      opt('Start time','Time picker','Start: Now',
        {what:'The anchor for every time on the card.',
         when:'Reads “Start: Now” until you pick one. A player-pool mode has no start date — only the bracket modes plan across days.'}),
      opt('Schedule Preview','“Predicted end: {time}” and “Round duration: {n}m match + {n}m break = {n}m”','Read-only',
        {what:'What the grid above costs in time. There is no game format here: the round clock decides the length, not a points target.'}),
      opt('Pace alerts','On / off','Off',
        {what:'Marks rounds as on track, due or overdue once the session is running.',
         help:'“Flag rounds as on track, due, or overdue”'}),
      opt('Players','Create new, add from Administration, group chips, search, “Add all ({count})”','Empty',
        {what:'Who is actually taking part. The tile is grey while empty, red while the count is wrong, olive once it matches.',
         when:'A name already on the list asks first: “{name} is already added to this tournament. Add anyway?”'}),
      opt('Fill {count} random','Button','—',
        {what:'Fills the roster up to Target Players — a dry run, or a session with no name list yet.'}),
      opt('Clear all','Button, with a confirmation','—',
        {when:'“This will remove all added players from the list.”'}),
      opt('Confirm the count','Adjust the plan, or keep it and fix the line-up','—',
        {what:'What happens when you add more or fewer people than you planned for.',
         when:'Outside the limits it refuses instead: “The player count runs from {min} to {max}, so it can’t be set to {selected}.”'}),
      opt('Tournament Name','Free text, plus a suggest button','A random name in the mode’s own style',
        {when:'Create stays disabled while the name is empty.',
         help:'“Suggest a name”'}),
      opt('Create Tournament','The button that ends setup','Disabled until the page is ready',
        {what:'Needs a name, a match duration above zero, at least one round, and exactly as many players added as planned.',
         when:'The line above it reads “Ready to start!” or “Setup looks good!” — otherwise it names what is still missing.'}),
    ]),
  ],
  next:['m-social-scramble-run','tournament-hub'],
  /* ══ INBOX · migriert aus pages/modes/social-scramble.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Social Scrambles page · to review','i-south'),
    fbox('i-trophy','The Social Scrambles hub','New Tournament starts a session. Below it sits your history — each entry showing the date, the player count and how far it got, so you can reopen a session or copy its settings.'),
  ],
},

'm-social-scramble-run': {
  title:'Running a Social Scramble', route:'/guide/modes/social-scramble/tournament', icon:'i-grid', parent:'m-social-scramble',
  eyebrow:'Social Scramble · Running it',
  h1:['Running a ','Social Scramble'],
  lead:'Once it starts, one screen carries the whole session: how far along you are, who is on which court, who is sitting out, and when you will be done.',
  blocks:[
    panel('What the screen gives you',null,[
      item('i-target','Progress and settings in one row','Games completed, a progress ring and a row of pills. A pill with a pencil can still be changed; one with a lock was fixed when play started.'),
      item('i-court','Round by round, or court by court','Switch the schedule to Court and each court lists its own sequence — the view to hand someone refereeing one court all session.'),
      item('i-grid','Who is on which court','The allocation grid lays every round against every court. It is the whole game plan on one screen, and the place you notice that someone has been sitting out too often.'),
    ]),
    sect('Every pill on the page','i-south'),
    opts('Social Scramble · the pill row',[
      opt('“Standings”','The ranking as it stands.','Opens the table'),
      opt('“Allocation”','What each court is doing this round.','Opens the court screen'),
      opt('“Teams”','The pairings this round drew.','Opens the sheet'),
      opt('“{n} players”','The roster: add someone mid-session, send a player on a break, or swap one out.','Opens the sheet'),
      opt('“{n}v{n}”','The format each round is drawn against.','Edit here until a round locks in — after that the draw is already built against it'),
      opt('“{n} rounds”','How many times the teams get redrawn.','Edit here'),
      opt('“{n} courts”','How many matches run at once.','Edit here'),
      opt('“Ends {time}”','The projected finish.','Opens the schedule preview'),
    ], ['Pill','What it does','Editable here?']),
    sect('The rest of the page','i-south'),
    grid([
      {icon:'i-edit', label:'Tournament page controls', cap:'QR, workbook, renaming — and why a pill locks.', to:'tournament-controls'},
    ]),
  ],
  next:['m-social-scramble-score','tournament'],
  /* ══ INBOX · migriert aus pages/modes/social-scramble.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Social Scrambles page · to review','i-south'),
    panel('Standings, live and final','Because everyone plays with everyone, the ranking is individual. It updates as results land, so the table is always current — no waiting for the organiser to add it up.',[
      item('i-people','Live standings',
        'Every player with their points, games played and win record, ordered as it stands right now. Players check it between rounds without asking anyone.'),
      item('i-trophy','Final rankings',
        'When the last match is in, the table closes with the winner at the top. This is the screen to hold up at the end of the evening.'),
      item('i-check','The finished session',
        'The schedule keeps every result. A completed session stays in the hub with all its scores, so a question about last month’s ranking has an answer.'),
    ]),
    panel('When the session changes','People arrive late, roll an ankle, or have to leave at six. A session that cannot absorb that is a session someone ends up re-planning on paper.',[
      item('i-admin','The player list is the control panel',
        'Everyone in the session with their games played and points so far. Each row carries the four things you actually need mid-evening: pause a player, correct a name, swap them with someone else, or take them out.'),
      item('i-swap','Someone has to leave',
        'Ejecting a player asks what should happen to the matches they were already drawn into, rather than silently corrupting the rest of the schedule. Re-pair the remaining rounds without them, or leave their seat open so nobody else’s pairings move. Games already played keep counting.'),
    ]),
    panel('Getting it off your phone','The session lives on the device that runs it and nothing needs a signal. Getting it out is deliberate, and there are two ways: a QR code between two phones for a single match, or an Excel workbook for the whole tournament.',[
      item('i-doc','The whole tournament, as a spreadsheet',
        'Export writes a real .xlsx — the schedule, the teams and the results, one row per match. Keep an eye on the event from a laptop, fill in scores away from the phone, then import the file back and TournaQ tells you what it recorded, replaced and skipped.'),
      item('i-qr','One match, by QR code',
        'Every match card carries a QR button. Show the code on one phone, scan it on another, and the scorecard travels between them — no reception, no account, nothing uploaded. A scorecard that arrives this way is marked as imported so you can see where it came from.'),
      item('i-copy','Where they land',
        'The hub keeps imported scorecards on their own tab next to your own history, so it stays obvious which results were scored on this phone and which arrived from somewhere else.'),
    ]),
  ],
},

'm-social-scramble-score': {
  title:'Scoring a Social Scramble match', route:'/guide/modes/social-scramble/scorecard', icon:'i-score', parent:'m-social-scramble',
  eyebrow:'Social Scramble · Scorecard',
  h1:['Scoring a ','Social Scramble match'],
  lead:'Every match in the schedule is a card carrying its court, its players, its referee and its score. Tap it to score it.',
  blocks:[
    panel('On the card',null,[
      item('i-score','Portrait','Tap a side to award the point. The serving side is marked, and the round timer runs in the header so everyone knows how long is left.'),
      item('i-swap','Landscape','Turn the phone and the same controls rearrange for a net post or a table at the side of the court. Nothing is hidden.'),
      item('i-edit','Not every match gets scored live','Someone forgets to open the scorecard, or a court finishes while you are refereeing another one. Type the final score straight into the card and the standings update exactly as if you had tapped through every rally.'),
    ]),
    fbox('i-timer','Which card this is','The scramble scorecard — timed rounds, with the round clock running in the header.'),
    sect('What this card gives you','i-south'),
    opts('Social Scramble · the scorecard',[
      opt('The pill row','Event name — editable, because a name re-forms nothing — then round and court, and Standings, Allocation, Teams and the player count. Format, rounds and courts edit here only on a single-court session, where this card is the session.','Under the title'),
      opt('Round timer','The countdown that ends the round, with Stop, Resume and Start / Restart. A pause freezes the remaining time and stores it, so leaving the page does not cost you the clock.','Always'),
      opt('Serves-first banner','Who starts the round serving.','Until the first point'),
      opt('Referee banner','“{name} refs”, or “Assign a referee manually”.','When this court has a referee slot for the round'),
      opt('Score buttons','Plus and minus per side, with service passing to whoever scored. The score cannot go below zero.','Always'),
      opt('Player pills','Tap a player to send them off: “{name} is on a break — their seat is a Placeholder.” Tap the stand-in to bring them back: “{name} is back in the rotation.” With nothing left to come back to: “No round left to sit out.”','While a later round can bring them back'),
      opt('Upcoming games','The next games still to play, grouped by round, each with its referee and a note when courts run in parallel.','Below the card'),
      opt('App-bar QR menu','“Export scorecard”, and “Manually Set Score” for a game played away from the phone.','While the board is live'),
      opt('Back','“Back to Schedule” on your own device, “Back to Hub” on an imported card.','Bottom of the card'),
      opt('Landscape','Turn the phone and the same controls rearrange for a net post or a side table.','Any time'),
    ], ['Control','What it does','When you see it']),
    sect('The card itself','i-south'),
    grid([
      {icon:'i-timer', label:'Scramble scorecard', cap:'What the other modes on this card do differently.', to:'sc-scramble'},
    ]),
  ],
  next:['sc-scramble','m-social-scramble'],
},

/* ── Royal Rotation · the three steps ────────────────────────────────── */

'm-royal-rotation-hub': {
  title:'Setting up a Royal Rotation', route:'/guide/modes/royal-rotation/tournament-hub', icon:'i-trophy', parent:'m-royal-rotation',
  eyebrow:'Royal Rotation · Tournament Hub',
  h1:['Setting up a ','Royal Rotation'],
  lead:'Set the pool, the courts and the strike target. TournaQ draws the pairs and works out how many rounds fit in the time you have.',
  blocks:[
    panel('What you set',null,[
      item('i-people','The scramble half','Players, rounds, and how often partners change.'),
      item('i-crown','The king half','The strike target, the swap rule and the jumper.'),
      item('i-clock','One form for both','Every field feeds the Schedule Preview, so the finish time moves as you decide.'),
    ]),
    fbox('i-sync','The pairs it drew','Each round produces a fresh set of teams, and the teams sheet shows exactly who has been put with whom. It is the answer to "who am I with this round?" without anyone having to ask.'),
    sect('Every setting on the page','i-south'),
    opts('Royal Rotation · Tournament Setup — the page is titled “Scramble King” in the app',[
      opt('Target Players','8, 12, 16, 20, 24, 32, 48 — or type any number','16 · from twice the side size, up to 128',
        {what:'How many people you are planning for.',
         help:'“How many players you plan to have. Used to size the ‘fill random’ quick-add and to check your court/round settings make sense.”'}),
      opt('Courts','1, 2, 3, 4, 5, 6, 8','2 · 1 to 8',
        {what:'Each court runs its own queue for the round.',
         when:'Blocks Create when the pool cannot fill the courts you asked for.',
         help:'“How many courts run at once, each with its own independent King of the Court queue for the round.”'}),
      opt('Style','2vs2 through 6vs6','2vs2 · 2 to 6 a side',
        {what:'How many players a side fields.',
         when:'A size stays visible but unselectable once the planned field cannot seat two full sides of it; at the ceiling a note says which size is the largest that fits.',
         help:'“The format of each game — 2vs2, 3vs3, and so on. Sets how many players make up each team on court.”'}),
      opt('Rounds','3, 4, 5, 6, 8, 10, 12 — or type any number','6 · 1 to 999',
        {what:'How often the whole pool is reshuffled onto new courts.',
         help:'“How many times the whole player pool gets mixed into new courts and teams.”'}),
      opt('Match Duration','8, 10, 12, 15, 20, 25, 30 min — or type any number','12 min · 1 to 999 min',
        {help:'“How long each round runs before everyone is reshuffled into new courts and teams.”'}),
      opt('Break Between Rounds','0, 2, 3, 5, 7, 10 min — or type any number','2 min · 0 to 999 min'),
      opt('Strike Points','0, 3, 5, 7, 10, 15, 21 — or type any number','5 · 0 to 999',
        {what:'What it takes to win the court and leave it as the winning side.',
         help:'“Points a team must score to win the game and be ejected as winners. Set to 0 to disable — teams stay on court until the coach manually ejects them.”'}),
      opt('Odd player handling','Placeholder · Jumper','Placeholder',
        {what:'What happens to the player the reshuffle cannot pair.',
         when:'Jumper needs four times the side size plus one — nine players at 2vs2. Below that: “Jumper needs {count}+ players; with fewer the queue can loop unfairly, so Placeholder is used.”',
         help:'“When a court can’t be split evenly into teams of two, one player gets their own team and queues like everyone else — only their partner is decided by this setting. Placeholder picks a random free player the first time they take the court, then keeps that same partner for the rest of the round. Jumper re-picks a partner every time, using a fairness calculation so playing time stays balanced across the round.”'}),
      opt('Assignment','Manual · Automated · Auto-Allplay','Manual',
        {what:'How the next team gets onto the court.',
         when:'The mode sets the floor per court: three times the side size, or four times plus one under Auto-Allplay. Below it: “{mode} needs at least {count} players per court.”',
         help:'“How the next court team is chosen. Manual — the coach selects players from the queue by tapping them. Automated — TournaQ suggests the best team, prioritising players who have waited longest and haven’t been paired together recently. The coach can re-roll before confirming. Automated — All Play — like Automated but no dedicated coach. A rotating referee keeps score while everyone else plays. TournaQ picks a random starting referee and suggests the next handoff from the ejected team after each game.”'}),
      opt('Auto-eject challenger','0, 1, 2, 3','0 — off · 0 to 3',
        {what:'Ends a hopeless challenge early instead of watching it out.',
         help:'“Prompts you to eject the challenger team once the on-court team scores this many points against them. With automatic assignment, confirming brings the next team on; with manual assignment you eject them yourself. 0 keeps it off — you can still eject by hand anytime.”'}),
    ]),
    fbox('i-check','What the page refuses, and what it only warns about','Some of these block Create outright; the rest are advice under the schedule.',[
      {icon:'i-clock', title:'No rounds, or a round with no length', body:'“At least 1 round is needed.” and “Round duration must be greater than zero.” — both block Create.'},
      {icon:'i-people', title:'Too small for one court', body:'“At least {min} players are needed for one court.” — blocks Create.'},
      {icon:'i-court', title:'Too small for the courts you asked for', body:'“{courts} courts need {needed} players at {min} each — you have {players}. Add players, use fewer courts, or switch off Auto All-Play.” — blocks Create.'},
      {icon:'i-queue', title:'A court with no queue behind it', body:'“A court has no waiting queue, so challenger rotation can’t happen there. Add players for {min} per court.” — or, with auto-eject off, “The same players stay on court all round.”'},
      {icon:'i-swap', title:'How much mixing you get', body:'“At {rounds} rounds each player shares a court with about {met} of the other {total}. {target} rounds makes it about {more}.” — with a one-tap “Use {target} rounds”.'},
      {icon:'i-star', title:'Full coverage reached', body:'“At {rounds} rounds every player shares a court with all {total} others.”'},
      {icon:'i-sync', title:'Fresh partners', body:'“No repeat partners at {rounds} rounds.” — or “Fresh partners for at least the first {promised} rounds.”'},
    ]),
    sect('The rest of the page','i-south'),
    opts('Below the grid — Schedule Preview, roster, name',[
      opt('Start time','Time picker','Start: Now',
        {what:'The anchor every time on the preview is measured from.',
         when:'The card reads “Start: Now” until you pick one. A queue mode has no start date — only the bracket modes plan across days.'}),
      opt('Schedule Preview','Start time, projected end, round duration, court sizes','Read-only',
        {what:'What the grid above costs in time. On a queue mode the card only reports — the start time is the one thing you can change in it.'}),
      opt('Pace alerts','On / off','Off',
        {what:'Marks rounds as on track, due or overdue once the session is running.',
         help:'“Flag rounds as on track, due, or overdue”'}),
      opt('Players','Create new, add from Administration, group chips, search, “Add all ({count})”','Empty',
        {what:'Who is actually taking part. The tile is grey while empty, red while the count is wrong, olive once it matches.',
         when:'A name already on the list asks first: “{name} is already added to this tournament. Add anyway?”'}),
      opt('Fill {count} random','Button','—',
        {what:'Fills the roster up to Target Players — a dry run, or a session with no name list yet.'}),
      opt('Clear all','Button, with a confirmation','—',
        {when:'“This will remove all added players from the list.”'}),
      opt('Confirm the count','Adjust the plan, or keep it and fix the line-up','—',
        {what:'What happens when you add more or fewer people than you planned for.',
         when:'Outside the limits it refuses instead: “The player count runs from {min} to {max}, so it can’t be set to {selected}.”'}),
      opt('Tournament Name','Free text, plus a suggest button','A random name in the mode’s own style',
        {when:'Create stays disabled while the name is empty.',
         help:'“Suggest a name”'}),
      opt('Create Tournament','The button that ends setup','Disabled until the page is ready',
        {what:'Needs a name, a match duration above zero, at least one round, a full roster, and a plan that can be built — every court you asked for has to reach its player floor.',
         when:'The line above it reads “Ready to start!” or “Setup looks good!” — otherwise it names what is still missing.'}),
    ]),
  ],
  next:['m-royal-rotation-run','tournament-hub'],
  /* ══ INBOX · migriert aus pages/modes/royal-rotation.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Royal Rotations page · to review','i-south'),
    fbox('i-trophy','The Royal Rotations hub','New Tournament starts a session. Below it sits your history, each entry showing the date, the player count and how far it got.'),
  ],
},

'm-royal-rotation-run': {
  title:'Running a Royal Rotation', route:'/guide/modes/royal-rotation/tournament', icon:'i-grid', parent:'m-royal-rotation',
  eyebrow:'Royal Rotation · Running it',
  h1:['Running a ','Royal Rotation'],
  lead:'One screen carries several courts at once: how far along you are, which pairs are where, who is queuing, and when you will finish.',
  blocks:[
    panel('What the screen gives you',null,[
      item('i-target','Progress and settings in one row','Rounds complete, a progress ring and a row of pills — standings, allocation, teams, strike target, swap rule and estimated finish.'),
      item('i-court','Round by round, or court by court','Switch the schedule to Court and each court lists its own sequence — the view you want when three courts run their own king at once.'),
      item('i-grid','Who is on which court','With a big pool spread over several courts, the allocation grid is the screen that shows whether the draw is treating everyone equally.'),
    ]),
    sect('Every pill on the page','i-south'),
    opts('Royal Rotation · the pill row',[
      opt('“Standings”','The overall ranking — and the page where the ranking method itself can still be changed.','Opens the ranking page'),
      opt('“Allocation”','What each court is doing right now — beside the court count, which only says how many there are.','Opens the court screen'),
      opt('“Teams”','The teams currently formed on court.','Opens the sheet'),
      opt('“{n} players”','The roster: add someone mid-session, send a player on a break, or swap one out.','Opens the sheet'),
      opt('“{n}v{n}”','The side size the courts are formed against.','Edit here — it redraws only the rounds nobody has played yet, and a started session asks first'),
      opt('“{n} rounds”','How many times the pool is reshuffled onto fresh courts.','Edit here — opens the format sheet'),
      opt('“{n} courts”','How many independent queues run at once.','Edit here — opens the format sheet'),
      opt('“{n} pt strike”','What it takes to win the court and leave it as the winning side. Hidden when strike points are switched off.','Edit here — opens the format sheet'),
      opt('“Auto-eject @ {n}” / “Auto-eject off”','Whether the challenger prompt is armed, and at what points gap. Always shown, because “off” is exactly the state worth knowing before a session starts.','Edit here — opens the format sheet'),
      opt('“Placeholder” / “Jumper”','How the player the reshuffle cannot pair gets a partner.','Edit here — opens the format sheet'),
      opt('“Manual” / “Automated” / “Auto-Allplay”','How the next team gets onto the court.','Edit here — opens the format sheet'),
      opt('“Est. finish {time}” / “Finished {time}”','The projection. The number is derived, but what drives it is not.','Opens the timeline — start time and each round’s game and break length'),
    ], ['Pill','What it does','Editable here?']),
    sect('The rest of the page','i-south'),
    grid([
      {icon:'i-edit', label:'Tournament page controls', cap:'QR, workbook, renaming — and why a pill locks.', to:'tournament-controls'},
    ]),
  ],
  next:['m-royal-rotation-score','tournament'],
  /* ══ INBOX · migriert aus pages/modes/royal-rotation.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Royal Rotations page · to review','i-south'),
    panel('Fresh pairs, moving queue','Two things rotate here: the partners between rounds, and the challengers within a round. Both are handled for you.',[
      item('i-queue','Challengers rotate automatically',
        'When a hold ends the next pair comes on and the card says who they are. Nobody has to remember whose turn it was, and nobody quietly skips the queue.'),
      item('i-admin','The player list is the control panel',
        'Everyone in the session with their games played and points so far. Each row carries the four things you need mid-evening: pause a player, correct a name, swap them with someone else, or take them out.'),
    ]),
    panel('Standings, live and final','Partners change every round, so the ranking is individual — points follow the player, not the pair.',[
      item('i-people','Live standings',
        'Every player with their points, games played and win record, ordered as it stands right now. Players check it between rounds without asking anyone.'),
      item('i-crown','Final rankings',
        'When the last round is in, the table closes with the winner at the top: the player who held court most across every partner they were given.'),
      item('i-check','The finished session',
        'The schedule keeps every result. A completed session stays in the hub with all its scores, so a question about last month’s session has an answer.'),
    ]),
  ],
},

'm-royal-rotation-score': {
  title:'Scoring a Royal Rotation match', route:'/guide/modes/royal-rotation/scorecard', icon:'i-score', parent:'m-royal-rotation',
  eyebrow:'Royal Rotation · Scorecard',
  h1:['Scoring a ','Royal Rotation match'],
  lead:'Each court runs its own king: the pair on, the pair challenging, and the queue behind them, with the scoring controls under your thumb.',
  blocks:[
    panel('On the card',null,[
      item('i-score','Portrait','The court, the challengers and the queue on one screen, with the session timer in the header. Tap to score, undo to take it back.'),
      item('i-swap','Landscape','Turn the phone and the same controls rearrange for a net post or a table at the side of the court.'),
      item('i-crown','Strikes','A strike is what ends a hold. TournaQ announces it, banks the points and moves the court on, so nobody has to keep a tally in their head while playing.'),
    ]),
    fbox('i-queue','Which card this is','The queue scorecard — the court, the challengers and the queue behind them, with the round clock running in the header.'),
    sect('What this card gives you','i-south'),
    opts('Royal Rotation · the scorecard',[
      opt('The pill row','Standings and Allocation, teams and players, the side size, rounds, courts, strike points, auto-eject, odd-player handling and assignment — plus this round and this court. The format pills edit here only on a single-court session','Under the title'),
      opt('Court','Who is holding the court right now, and the points they have made this turn.','Always'),
      opt('Challengers','The side waiting to come on next.','Always — “Waiting for players…” while the queue is too thin'),
      opt('Up Next','The stage behind the challengers, with “Re-roll” to draw a different pairing.','Automatic assignment — “Not enough players in queue.” when there is nobody left to draw'),
      opt('Score buttons','Count the points the side on court is making.','Always'),
      opt('Session timer','The round’s countdown, with Stop, Resume and Start / Restart.','Always'),
      opt('Eject','Sends the side off and brings the next one on. “Eject / Challenger” where the prompt can rotate a challenger instead.','Always — manual ejection stays available whatever the automatic thresholds say'),
      opt('Strike prompt','“Game Won! They will be ejected and return to the queue.” — confirm with “Eject Team”.','When strike points are set above zero'),
      opt('Partner picker','“Pick a partner for the floater” — the player the reshuffle could not pair gets one, by the rule setup chose: a Placeholder who stays, or a Jumper re-picked each turn.','Odd fields'),
      opt('Undo','Takes the last step back. With points already on the board it asks first: “The team currently on court has {points} point(s) recorded. Undoing will discard them.”','After an ejection, and during a manual pick'),
      opt('Change referee','“Select who referees this court. The current one returns to the queue.” The successor is suggested from the current court team.','Auto-Allplay, where a rotating referee keeps score'),
      opt('Player pills','Send someone on a break — their seat becomes a Placeholder — and tap the stand-in to bring them back.','While a later round can bring them back'),
      opt('Start / Finish court','“Start Court” drops it into live play; “Finish court” asks “Record this court’s results now and end its round.” and is reversible with “Undo Finish”.','Bottom of the card'),
      opt('App-bar QR menu','“Export court” hands the whole court to another phone; “Manually Set Score” writes the results in directly.','While the court is live'),
      opt('Teams table','Wins, points and ranking points per team on this court.','Below the card'),
      opt('Landscape','Turn the phone and the same controls rearrange for a net post or a side table.','Any time'),
    ], ['Control','What it does','When you see it']),
    sect('The card itself','i-south'),
    grid([
      {icon:'i-queue', label:'Queue scorecard', cap:'What the other modes on this card do differently.', to:'sc-queue'},
    ]),
  ],
  next:['sc-queue','m-royal-rotation'],
},

/* ── Royal Shuffles · the three steps ───────────────────────────────── */

'm-royal-shuffle-hub': {
  title:'Setting up a Royal Shuffle', route:'/guide/modes/royal-shuffle/tournament-hub', icon:'i-trophy', parent:'m-royal-shuffle',
  eyebrow:'Royal Shuffle · Tournament Hub',
  h1:['Setting up a ','Royal Shuffle'],
  lead:'Set the pool, the courts and the strike target, and TournaQ works out the rounds, the queue and the finish time. Every field the page asks for is listed here — the queue rules, the schedule card, the roster and the name.',
  blocks:[
    panel('What you set',null,[
      item('i-crown','Strike points','How many points win the court, and with it how long a pair can hold it.'),
      item('i-queue','Assignment and auto-eject','Who puts the next team on, and whether a hopeless challenge is ended early.'),
      item('i-people','Who is playing','Add players by name, pull them from Administration, or fill the session with random names to try the format out.'),
    ]),
    fbox('i-clock','The list stays editable','Players can be added or paused all the way through the session, not just at setup — and every field feeds the Schedule Preview, so the finish time moves as you decide.'),
    sect('Every setting on the page','i-south'),
    opts('Royal Shuffle · Tournament Setup — the page is titled “King of the Court” in the app',[
      opt('Target Players','6, 8, 12, 16, 20, 24, 32 — or type any number','12 · 1 to 128',
        {what:'How many people you are planning for.',
         when:'Below the floor the mode needs: “Auto-Allplay works with fewer players, but rotation may feel clunky below {count} players.”',
         help:'“How many players you plan to have. Used to size the ‘fill random’ quick-add and to check your court/round settings make sense.”'}),
      opt('Courts','1, 2, 3, 4, 5, 6, 8','2 · 1 to 8',
        {what:'Each court runs its own queue for the round.',
         help:'“How many courts run at once, each with its own independent King of the Court queue for the round.”'}),
      opt('Style','2vs2 through 6vs6','2vs2',
        {what:'How many players a side fields — and, with it, how deep each court has to be.',
         help:'“The format of each game — 2vs2, 3vs3, and so on. Sets how many players make up each team on court.”'}),
      opt('Rounds','2, 3, 4, 5, 6, 8, 10 — or type any number','4 · 1 to 999',
        {what:'How often the whole pool is redistributed across the courts.',
         help:'“How many times the whole player pool gets mixed into new courts and teams.”'}),
      opt('Match Duration','8, 10, 12, 15, 20, 25, 30 min — or type any number','12 min · 1 to 999 min',
        {help:'“How long each round runs before everyone is reshuffled into new courts and teams.”'}),
      opt('Break Between Rounds','0, 2, 3, 5, 7, 10 min — or type any number','2 min · 0 to 999 min'),
      opt('Strike Points','0, 3, 5, 7, 10, 15, 21 — or type any number','5 · 0 to 999',
        {what:'What it takes to win the court and leave it as the winning side.',
         help:'“Points a team must score to win the game and be ejected as winners. Set to 0 to disable — teams stay on court until the coach manually ejects them.”'}),
      opt('Assignment','Manual · Automated · Auto-Allplay','Automated',
        {what:'How the next team gets onto the court.',
         when:'The mode sets the floor per court: three times the side size, or four times plus one under Auto-Allplay. Below it: “{mode} needs at least {count} players per court.”',
         help:'“Manual — the coach selects players from the queue by tapping them. Automated — TournaQ suggests the best team, prioritising players who have waited longest and haven’t been paired together recently. The coach can re-roll before confirming. Automated — All Play — like Automated but no dedicated coach. A rotating referee keeps score while everyone else plays.”'}),
      opt('Auto-eject challenger','0, 1, 2, 3','0 — off · 0 to 3',
        {what:'Ends a hopeless challenge early instead of watching it out.',
         help:'“Prompts you to eject the challenger team once the on-court team scores this many points against them. With automatic assignment, confirming brings the next team on; with manual assignment you eject them yourself. 0 keeps it off — you can still eject by hand anytime.”'}),
    ]),
    opts('Below the grid — Schedule Preview, roster, name',[
      opt('Start time','Time picker','Start: Now',
        {what:'The anchor every time on the preview is measured from.',
         when:'The card reads “Start: Now” until you pick one. A queue mode has no start date — only bracket modes plan across days.'}),
      opt('Schedule Preview','Round duration, rounds, scheduled duration, projected end','Read-only',
        {what:'What the grid above costs in time. On a queue mode the card only reports — the start time is the one thing you can change in it.'}),
      opt('Pace alerts','On / off','Off',
        {what:'Marks rounds as on track, due or overdue once the session is running.',
         help:'“Flag rounds as on track, due, or overdue”'}),
      opt('Players','Create new, add from Administration, group chips, search, “Add all ({count})”','Empty',
        {what:'Who is actually taking part. The tile is grey while empty, red while the count is wrong, olive once it matches.',
         when:'A name that is already on the list asks first: “{name} is already added to this tournament. Add anyway?”'}),
      opt('Fill {count} random','Button','—',
        {what:'Fills the roster up to Target Players — a dry run, or a session with no name list yet.'}),
      opt('Clear all','Button, with a confirmation','—',
        {when:'“This will remove all added players from the list.”'}),
      opt('Confirm the count','Adjust the plan, or keep it and fix the line-up','—',
        {what:'What happens when you add more or fewer people than you planned for.',
         when:'Outside the limits it refuses instead: “The player count runs from {min} to {max}, so it can’t be set to {selected}.”'}),
      opt('Tournament Name','Free text, plus a suggest button','A random name in the mode’s own style',
        {when:'Create stays disabled while the name is empty.',
         help:'“Suggest a name”'}),
      opt('Create Tournament','The button that ends setup','Disabled until the page is ready',
        {what:'Needs a name, a match duration above zero, at least one round, a full roster, and a plan that can be built.',
         when:'The line above it reads “Ready to start!” or “Setup looks good!” — otherwise it names what is still missing.'}),
    ]),
    fbox('i-check','What the page refuses, and what it only warns about','Some of these block Create outright; the rest are advice under the schedule.',[
      {icon:'i-clock', title:'No rounds, or a round with no length', body:'“At least 1 round is needed.” and “Round duration must be greater than zero.” — both block Create.'},
      {icon:'i-people', title:'Too small for one court', body:'“At least {min} players are needed for one court.” — blocks Create.'},
      {icon:'i-court', title:'Too small for the courts you asked for', body:'“{courts} courts need {needed} players at {min} each — you have {players}. Add players, use fewer courts, or switch off Auto All-Play.” — blocks Create.'},
      {icon:'i-queue', title:'A court with no queue behind it', body:'“A court has no waiting queue, so challenger rotation can’t happen there. Add players for {min} per court.” — or, with auto-eject off, “The same players stay on court all round.”'},
      {icon:'i-swap', title:'How much mixing you get', body:'“At {rounds} rounds each player shares a court with about {met} of the other {total}. {target} rounds makes it about {more}.” — with a one-tap “Use {target} rounds”.'},
      {icon:'i-star', title:'Full coverage reached', body:'“At {rounds} rounds every player shares a court with all {total} others.”'},
      {icon:'i-sync', title:'Fresh partners', body:'“No repeat partners at {rounds} rounds.” — or “Fresh partners for at least the first {promised} rounds.”'},
    ]),
  ],
  next:['m-royal-shuffle-run','tournament-hub'],
  /* ══ INBOX · migriert aus pages/modes/royal-shuffle.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Royal Shuffles page · to review','i-south'),
    fbox('i-trophy','The Royal Shuffles hub','New Tournament starts a session. Below it sits your history, each entry showing the date, the player count and how far it got.'),
  ],
},

'm-royal-shuffle-run': {
  title:'Running a Royal Shuffle', route:'/guide/modes/royal-shuffle/tournament', icon:'i-grid', parent:'m-royal-shuffle',
  eyebrow:'Royal Shuffle · Running it',
  h1:['Running a ','Royal Shuffle'],
  lead:'One screen carries the session: how far along you are, who is holding each court, who is queuing, and when you will be done.',
  blocks:[
    panel('What the screen gives you',null,[
      item('i-target','Progress and settings in one row','Rounds complete, a progress ring, and a row of pills — standings, allocation, players, strike target, swap rule and estimated finish.'),
      item('i-court','Round by round, or court by court','Switch the schedule to Court and each court lists its own sequence — useful when several courts run at once and each has its own king.'),
      item('i-grid','Who is on which court','The allocation grid lays every round against every court, so you can spot a player who has spent the evening in the queue.'),
    ]),
    sect('Every pill on the page','i-south'),
    opts('Royal Shuffle · the pill row',[
      opt('“Standings”','The overall ranking — and the page where the ranking method itself can still be changed.','Opens the ranking page'),
      opt('“Allocation”','What each court is doing right now — beside the court count, which only says how many there are.','Opens the court screen'),
      opt('“{n} players”','The roster: add someone mid-session, send a player on a break, or swap one out.','Opens the sheet'),
      opt('“{n}v{n}”','The side size the courts were formed against.','Statement — it is chosen at setup and fixed for the event, so there is nothing here to edit into'),
      opt('“{n} rounds”','How many times the pool is reshuffled onto fresh courts.','Edit here — opens the format sheet'),
      opt('“{n} courts”','How many independent queues run at once.','Edit here — opens the format sheet'),
      opt('“{n} pt strike”','What it takes to win the court. Hidden when strike points are switched off.','Edit here — opens the format sheet'),
      opt('“Auto-eject @ {n}” / “Auto-eject off”','Whether the challenger prompt is armed, and at what points gap. Always shown, because “off” is exactly the state worth knowing before a session starts.','Edit here — opens the format sheet'),
      opt('“Manual” / “Automated” / “Auto-Allplay”','How the next team gets onto the court.','Edit here — opens the format sheet'),
      opt('“Est. finish {time}” / “Finished {time}”','The projection. The number is derived, but what drives it is not.','Opens the timeline — start time and each round’s game and break length'),
    ], ['Pill','What it does','Editable here?']),
    sect('The rest of the page','i-south'),
    grid([
      {icon:'i-edit', label:'Tournament page controls', cap:'QR, workbook, renaming — and why a pill locks.', to:'tournament-controls'},
    ]),
  ],
  next:['m-royal-shuffle-score','tournament'],
  /* ══ INBOX · migriert aus pages/modes/royal-shuffle.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Royal Shuffles page · to review','i-south'),
    panel('Keeping the queue honest','The queue is the format. TournaQ runs it, and lets you override it when the evening does not go to plan.',[
      item('i-queue','Challengers rotate automatically',
        'When a game ends the next challengers come on and the card tells you who they are. Nobody has to remember whose turn it was, and nobody quietly skips the queue.'),
      item('i-swap','Or change them yourself',
        'Somebody is tying a shoelace, somebody else has just arrived. Swap the challenging pair by hand and the queue picks up from there without losing anyone’s place.'),
    ]),
    panel('When the session changes','People arrive late, roll an ankle, or have to leave at six. A session that cannot absorb that is one someone ends up re-planning on paper.',[
      item('i-clock','Someone needs a break',
        'Put a player on a break for one round or until you bring them back. Their seat becomes an open placeholder so the court still plays, and every point they have already banked stays with them.'),
      item('i-sync','And comes back',
        'Return them and they slot back into the queue. Nothing is reshuffled and nobody else’s position moves.'),
      item('i-people','Someone steps in',
        'A stand-in can take an open seat on a live court, so a round runs on time instead of playing three against four while you find somebody.'),
    ]),
    panel('Standings, live and final','Points are banked while you hold the court, so the ranking rewards staying on — and everyone’s record is individual.',[
      item('i-people','Live standings',
        'Every player with their points, games played and win record, ordered as it stands right now. Players check it between rounds without asking anyone.'),
      item('i-crown','Final rankings',
        'When the session ends the table closes with the winner at the top: whoever held the court longest and scored most while they were on it.'),
      item('i-check','The finished session',
        'The schedule keeps every result. A completed session stays in the hub with all its scores, so a question about last month’s session has an answer.'),
    ]),
  ],
},

'm-royal-shuffle-score': {
  title:'Scoring a Royal Shuffle match', route:'/guide/modes/royal-shuffle/scorecard', icon:'i-score', parent:'m-royal-shuffle',
  eyebrow:'Royal Shuffle · Scorecard',
  h1:['Scoring a ','Royal Shuffle match'],
  lead:'The court card shows who is on, who is challenging and who is up next, with the scoring controls under your thumb.',
  blocks:[
    panel('On the card',null,[
      item('i-score','Portrait','The court, the challengers and the queue on one screen, with the session timer in the header. Tap to score, undo to take it back.'),
      item('i-swap','Landscape','Turn the phone and the same controls rearrange for a net post or a table at the side of the court.'),
      item('i-crown','Game won','TournaQ says so, banks the points and moves the queue on. The court knows immediately who stays and who steps off.'),
    ]),
    fbox('i-queue','Which card this is','The queue scorecard — the court, the challengers, and who is up next.'),
    sect('What this card gives you','i-south'),
    opts('Royal Shuffle · the scorecard',[
      opt('The pill row','Standings and Allocation, the player count, the side size, rounds, courts, strike points, auto-eject and assignment — plus this round and this court. The format pills edit here only on a single-court session; on more than one they lock, because every court feeds one shared ranking','Under the title'),
      opt('Court','Who is holding the court right now, and the points they have made this turn.','Always'),
      opt('Challengers','The side waiting to come on next.','Always — “Waiting for players…” while the queue is too thin'),
      opt('Up Next','The stage behind the challengers, with “Re-roll” to draw a different pairing.','Automatic assignment — “Not enough players in queue.” when there is nobody left to draw'),
      opt('Score buttons','Count the points the side on court is making.','Always'),
      opt('Session timer','The round’s countdown, with Stop, Resume and Start / Restart.','Always'),
      opt('Eject','Sends the side off and brings the next one on. “Eject / Challenger” where the prompt can rotate a challenger instead.','Always — manual ejection stays available whatever the automatic thresholds say'),
      opt('Strike prompt','“Game Won! {names} reached {points} points! They will be ejected and return to the queue.” — confirm with “Eject Team”.','When strike points are set above zero'),
      opt('Undo','Takes the last step back. With points already on the board it asks first: “The team currently on court has {points} point(s) recorded. Undoing will discard them.”','After an ejection, and during a manual pick'),
      opt('Change referee','“Select who referees this court. The current one returns to the queue.” The successor is suggested from the current court team.','Auto-Allplay, where a rotating referee keeps score'),
      opt('Player pills','Send someone on a break — their seat becomes a Placeholder — and tap the stand-in to bring them back.','While a later round can bring them back'),
      opt('Start / Finish court','“Start Court” drops it into live play; “Finish court” asks “Record this court’s results now and end its round.” and is reversible with “Undo Finish”.','Bottom of the card'),
      opt('App-bar QR menu','“Export court” hands the whole court to another phone; “Manually Set Score” writes the results in directly.','While the court is live'),
      opt('Player table','Wins, points and ranking points for everyone on this court.','Below the card'),
      opt('Landscape','Turn the phone and the same controls rearrange for a net post or a side table.','Any time'),
    ], ['Control','What it does','When you see it']),
    sect('The card itself','i-south'),
    grid([
      {icon:'i-queue', label:'Queue scorecard', cap:'What the other modes on this card do differently.', to:'sc-queue'},
    ]),
  ],
  next:['sc-queue','m-royal-shuffle'],
},

/* ── Doghouses · the three steps ────────────────────────────────────── */

'm-doghouse-hub': {
  title:'Setting up a Doghouse', route:'/guide/modes/doghouse/tournament-hub', icon:'i-trophy', parent:'m-doghouse',
  eyebrow:'Doghouse · Tournament Hub',
  h1:['Setting up a ','Doghouse'],
  lead:'Two numbers define a Doghouse: how many side-outs it takes to get free, and how many losses put you out for good. Everything else is the usual — players, courts, time.',
  blocks:[
    panel('What you set',null,[
      item('i-target','Escape points','How many side-outs a pinned side needs to get free.'),
      item('i-shield','The loss limit','How many losses put a player out for good.'),
      item('i-people','Who is playing','Add players by name, pull them from your saved Players hub, or fill the session with random names to try the format out.'),
    ]),
    fbox('i-clock','The arithmetic follows you','Change any of the numbers and the Schedule Preview re-does the sums, so the predicted finish time moves as you decide how long you want to play. The player list is editable all the way through the session, not just at the start.'),
    sect('Every setting on the page','i-south'),
    opts('Doghouse · Tournament Setup',[
      opt('Target Players','6, 8, 12, 16, 20, 24, 32 — or type any number','12 · 1 to 128',
        {what:'How many people you are planning for.',
         when:'Below the floor the mode needs: “Auto-Allplay works with fewer players, but rotation may feel clunky below {count} players.”',
         help:'“How many players you plan to have. Used to size the ‘fill random’ quick-add and to check your court/round settings make sense.”'}),
      opt('Courts','1, 2, 3, 4, 5, 6, 8','2 · 1 to 8',
        {what:'Each court runs its own queue for the round.',
         help:'“How many courts run at once, each with its own independent King of the Court queue for the round.”'}),
      opt('Style','2vs2 through 6vs6','2vs2',
        {what:'How many players a side fields.',
         help:'“The format of each game — 2vs2, 3vs3, and so on. Sets how many players make up each team on court.”'}),
      opt('Rounds','2, 3, 4, 5, 6, 8, 10 — or type any number','4 · 1 to 999',
        {what:'How often the whole pool is redistributed across the courts.',
         help:'“How many times the whole player pool gets mixed into new courts and teams.”'}),
      opt('Match Duration','8, 10, 12, 15, 20, 25, 30 min — or type any number','12 min · 1 to 999 min',
        {help:'“How long each round runs before everyone is reshuffled into new courts and teams.”'}),
      opt('Break Between Rounds','0, 2, 3, 5, 7, 10 min — or type any number','2 min · 0 to 999 min'),
      opt('Escape Points','0, 2, 3, 4, 5, 7 — or type any number','3 · 0 to 999',
        {what:'What it takes to get out of the doghouse.',
         help:'“Points the doghouse team must score to escape. A point is earned each time the serving (doghouse) team wins a rally. The score resets to zero after each game lost.”'}),
      opt('Loss Limit','0, 2, 3, 4, 5 — or type any number','3 · 0 to 999',
        {what:'How long a side can stay stuck before the queue moves on without it.',
         help:'“How many games the doghouse team can lose before being automatically ejected. Each time the court team wins a rally, one game is lost and the point score resets to zero.”'}),
      opt('Assignment','Manual · Automated · Auto-Allplay','Automated',
        {what:'How the next team gets onto the court.',
         when:'The mode sets the floor per court: three times the side size, or four times plus one under Auto-Allplay. Below it: “{mode} needs at least {count} players per court.”',
         help:'“Manual — the coach selects players from the queue by tapping them. Automated — TournaQ suggests the best team, prioritising players who have waited longest and haven’t been paired together recently. The coach can re-roll before confirming. Automated — All Play — like Automated but no dedicated coach. A rotating referee keeps score while everyone else plays.”'}),
      opt('Auto-eject challenger','0, 1, 2, 3','0 — off · 0 to 3',
        {what:'Ends a hopeless challenge early instead of watching it out.',
         help:'“Prompts you to eject the challenger team once the on-court team scores this many points against them. With automatic assignment, confirming brings the next team on; with manual assignment you eject them yourself. 0 keeps it off — you can still eject by hand anytime.”'}),
    ]),
    fbox('i-check','What the page refuses, and what it only warns about','Some of these block Create outright; the rest are advice under the schedule.',[
      {icon:'i-clock', title:'No rounds, or a round with no length', body:'“At least 1 round is needed.” and “Round duration must be greater than zero.” — both block Create.'},
      {icon:'i-people', title:'Too small for one court', body:'“At least {min} players are needed for one court.” — blocks Create.'},
      {icon:'i-court', title:'Too small for the courts you asked for', body:'“{courts} courts need {needed} players at {min} each — you have {players}. Add players, use fewer courts, or switch off Auto All-Play.” — blocks Create.'},
      {icon:'i-queue', title:'A court with no queue behind it', body:'“A court has no waiting queue, so challenger rotation can’t happen there. Add players for {min} per court.” — or, with auto-eject off, “The same players stay on court all round.”'},
      {icon:'i-swap', title:'How much mixing you get', body:'“At {rounds} rounds each player shares a court with about {met} of the other {total}. {target} rounds makes it about {more}.” — with a one-tap “Use {target} rounds”.'},
      {icon:'i-star', title:'Full coverage reached', body:'“At {rounds} rounds every player shares a court with all {total} others.”'},
      {icon:'i-sync', title:'Fresh partners', body:'“No repeat partners at {rounds} rounds.” — or “Fresh partners for at least the first {promised} rounds.”'},
    ]),
    sect('The rest of the page','i-south'),
    opts('Below the grid — Schedule Preview, roster, name',[
      opt('Start time','Time picker','Start: Now',
        {what:'The anchor every time on the preview is measured from.',
         when:'The card reads “Start: Now” until you pick one. A queue mode has no start date — only the bracket modes plan across days.'}),
      opt('Schedule Preview','Round duration, rounds, scheduled duration, projected end','Read-only',
        {what:'What the grid above costs in time. On a queue mode the card only reports — the start time is the one thing you can change in it.'}),
      opt('Pace alerts','On / off','Off',
        {what:'Marks rounds as on track, due or overdue once the session is running.',
         help:'“Flag rounds as on track, due, or overdue”'}),
      opt('Players','Create new, add from Administration, group chips, search, “Add all ({count})”','Empty',
        {what:'Who is actually taking part. The tile is grey while empty, red while the count is wrong, olive once it matches.',
         when:'A name already on the list asks first: “{name} is already added to this tournament. Add anyway?”'}),
      opt('Fill {count} random','Button','—',
        {what:'Fills the roster up to Target Players — a dry run, or a session with no name list yet.'}),
      opt('Clear all','Button, with a confirmation','—',
        {when:'“This will remove all added players from the list.”'}),
      opt('Confirm the count','Adjust the plan, or keep it and fix the line-up','—',
        {what:'What happens when you add more or fewer people than you planned for.',
         when:'Outside the limits it refuses instead: “The player count runs from {min} to {max}, so it can’t be set to {selected}.”'}),
      opt('Tournament Name','Free text, plus a suggest button','A random name in the mode’s own style',
        {when:'Create stays disabled while the name is empty.',
         help:'“Suggest a name”'}),
      opt('Create Tournament','The button that ends setup','Disabled until the page is ready',
        {what:'Needs a name, a match duration above zero, at least one round, a full roster, and a plan that can be built.',
         when:'The line above it reads “Ready to start!” or “Setup looks good!” — otherwise it names what is still missing.'}),
    ]),
  ],
  next:['m-doghouse-run','tournament-hub'],
  /* ══ INBOX · migriert aus pages/modes/doghouse.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Doghouses page · to review','i-south'),
    fbox('i-trophy','The Doghouses hub','New Tournament starts a session. Below it sits your history, each entry showing the date, the player count and how far it got.'),
  ],
},

'm-doghouse-run': {
  title:'Running a Doghouse', route:'/guide/modes/doghouse/tournament', icon:'i-grid', parent:'m-doghouse',
  eyebrow:'Doghouse · Running it',
  h1:['Running a ','Doghouse'],
  lead:'Once it starts, one screen carries the session: how far along you are, who is on which court, who is sitting out, and when you will be done.',
  blocks:[
    panel('What the screen gives you',null,[
      item('i-target','Progress and settings in one row','Rounds complete, a progress ring, and a row of pills — standings, allocation, players, escape points, loss limit and estimated finish.'),
      item('i-court','Round by round, or court by court','Switch the schedule to Court and each court lists its own sequence — the view to hand someone refereeing one court all session.'),
      item('i-grid','Who is on which court','The allocation grid lays every round against every court. It is the whole session on one screen, and the place you notice someone has been sitting out too often.'),
    ]),
    sect('Every pill on the page','i-south'),
    opts('Doghouse · the pill row',[
      opt('“Standings”','The overall ranking — and the page where the ranking method itself can still be changed.','Opens the ranking page'),
      opt('“Allocation”','What each court is doing right now — beside the court count, which only says how many there are.','Opens the court screen'),
      opt('“{n} players”','The roster: add someone mid-session, send a player on a break, or swap one out.','Opens the sheet'),
      opt('“{n}v{n}”','The side size the courts were formed against.','Statement — chosen at setup and fixed for the event'),
      opt('“{n} rounds”','How many times the pool is reshuffled onto fresh courts.','Edit here — opens the format sheet'),
      opt('“{n} courts”','How many independent queues run at once.','Edit here — opens the format sheet'),
      opt('“{n} pt escape”','What it takes to get out of the doghouse. Hidden when escape points are switched off.','Edit here — opens the format sheet'),
      opt('“{n} loss limit”','How long a side can stay stuck before the queue moves on without it. Hidden when the limit is off.','Edit here — opens the format sheet'),
      opt('“Auto-eject @ {n}” / “Auto-eject off”','Whether the challenger prompt is armed, and at what points gap. Always shown, because “off” is exactly the state worth knowing before a session starts.','Edit here — opens the format sheet'),
      opt('“Manual” / “Automated” / “Auto-Allplay”','How the next team gets onto the court.','Edit here — opens the format sheet'),
      opt('“Est. finish {time}” / “Finished {time}”','The projection. The number is derived, but what drives it is not.','Opens the timeline — start time and each round’s game and break length'),
    ], ['Pill','What it does','Editable here?']),
    sect('The rest of the page','i-south'),
    grid([
      {icon:'i-edit', label:'Tournament page controls', cap:'QR, workbook, renaming — and why a pill locks.', to:'tournament-controls'},
    ]),
  ],
  next:['m-doghouse-score','tournament'],
  /* ══ INBOX · migriert aus pages/modes/doghouse.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Doghouses page · to review','i-south'),
    panel('Standings, live and final','Every player carries their own record, so the ranking is individual even though the teams change all session.',[
      item('i-people','Live standings',
        'Every player with their points, games played and win record, ordered as it stands right now. Players check it between rounds without asking anyone.'),
      item('i-crown','Final rankings',
        'When the last game is in, the table closes with the winner at the top — the player who spent the least time in the doghouse and the most time scoring.'),
      item('i-check','The finished session',
        'The schedule keeps every result. A completed session stays in the hub with all its scores, so a question about last month’s session has an answer.'),
    ]),
  ],
},

'm-doghouse-score': {
  title:'Scoring a Doghouse match', route:'/guide/modes/doghouse/scorecard', icon:'i-score', parent:'m-doghouse',
  eyebrow:'Doghouse · Scorecard',
  h1:['Scoring a ','Doghouse match'],
  lead:'The scorecard is built for one hand at the side of a court: big targets, the running score, and the rotation handled for you as games finish.',
  blocks:[
    panel('On the card',null,[
      item('i-score','Portrait','Tap a side to award the point. The timer runs in the header, the escape count is visible on the card, and undo takes back the last point.'),
      item('i-swap','Landscape','Turn the phone and the same controls rearrange for a net post or a table at the side of the court.'),
      item('i-sync','The queue moves itself','When a game ends the next players are rotated in automatically and the card tells you who is up. Nobody has to remember whose turn it was.'),
    ]),
    fbox('i-queue','Which card this is','The queue scorecard — the court, the challengers, and who is up next.'),
    sect('What this card gives you','i-south'),
    opts('Doghouse · the scorecard',[
      opt('The pill row','Standings and Allocation, the player count, the side size, rounds, courts, escape points, loss limit, auto-eject and assignment — plus this round and this court. The format pills edit here only on a single-court session','Under the title'),
      opt('Court','Who is holding the court right now, and the points they have made this turn.','Always'),
      opt('Challengers','The side waiting to come on next.','Always — “Waiting for players…” while the queue is too thin'),
      opt('Up Next','The stage behind the challengers, with “Re-roll” to draw a different pairing.','Automatic assignment — “Not enough players in queue.” when there is nobody left to draw'),
      opt('Score buttons','Count the points the side on court is making.','Always'),
      opt('Session timer','The round’s countdown, with Stop, Resume and Start / Restart.','Always'),
      opt('Eject','Sends the side off and brings the next one on. “Eject / Challenger” where the prompt can rotate a challenger instead.','Always — manual ejection stays available whatever the automatic thresholds say'),
      opt('Escape prompt','“Escaped! {names} reached {points} points! They will be ejected and return to the queue.”','When escape points are set above zero'),
      opt('Loss-limit prompt','“Ejected! {names} lost {count} games! They are ejected from the doghouse and return to the queue.”','When a loss limit is set'),
      opt('Undo','Takes the last step back. With points already on the board it asks first: “The team currently on court has {points} point(s) recorded. Undoing will discard them.”','After an ejection, and during a manual pick'),
      opt('Change referee','“Select who referees this court. The current one returns to the queue.” The successor is suggested from the current court team.','Auto-Allplay, where a rotating referee keeps score'),
      opt('Player pills','Send someone on a break — their seat becomes a Placeholder — and tap the stand-in to bring them back.','While a later round can bring them back'),
      opt('Start / Finish court','“Start Court” drops it into live play; “Finish court” asks “Record this court’s results now and end its round.” and is reversible with “Undo Finish”.','Bottom of the card'),
      opt('App-bar QR menu','“Export court” hands the whole court to another phone; “Manually Set Score” writes the results in directly.','While the court is live'),
      opt('Player table','Wins, points and ranking points for everyone on this court.','Below the card'),
      opt('Landscape','Turn the phone and the same controls rearrange for a net post or a side table.','Any time'),
    ], ['Control','What it does','When you see it']),
    sect('The card itself','i-south'),
    grid([
      {icon:'i-queue', label:'Queue scorecard', cap:'What the other modes on this card do differently.', to:'sc-queue'},
    ]),
  ],
  next:['sc-queue','m-doghouse'],
  /* ══ INBOX · migriert aus pages/modes/doghouse.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Doghouses page · to review','i-south'),
    panel('Into the doghouse, and out again','The two moments that define the format, and TournaQ announces both so the court knows where it stands without anyone keeping count.',[
      item('i-check','Escaped',
        'Score your way to the escape target and you are out, back into normal play with a clean slate. The dialog names who got out, so the rest of the court knows the pecking order has changed.'),
      item('i-shield','Out on the loss limit',
        'Hit the loss limit and you are ejected from the session. Games already played still count towards the ranking, so a bad run does not erase what came before it.'),
    ]),
  ],
},

/* ── Quick Game · the three steps ───────────────────────────────────── */

'quick-game-hub': {
  title:'Setting up a Quick Game', route:'/guide/modes/quick-game/tournament-hub', icon:'i-trophy', parent:'quick-game',
  eyebrow:'Quick Game · Tournament Hub',
  h1:['Setting up a ','Quick Game'],
  lead:'One sheet, and most of it is optional. The only thing you truly need is two team names — and TournaQ will invent those if you want.',
  blocks:[
    panel('What you set',null,[
      item('i-target','Target score and sets','Leave them alone and the defaults are a normal game; change them and the scorecard follows.'),
      item('i-people','Name the sides, or do not','Type the two team names, pull in a pair you have saved, or tap generate and let TournaQ name them.'),
      item('i-swap','Who serves first','Set it, or let it be decided the usual way.'),
    ]),
    fbox('i-bolt','No schedule, no roster','There is nothing to build and nobody to register — this is the shortest path in the app from opening it to counting points.'),
  ],
  next:['quick-game-score','tournament-hub'],
  /* ══ INBOX · migriert aus pages/modes/quick-game.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Quick Game page · to review','i-south'),
    panel('Starting a match','One sheet, and most of it is optional. The only thing you truly need is two team names — and TournaQ will invent those if you want.',[]),
    shot('guide/02_quick_games/03_quick_start_sheet',430,932,[430, 860],
      'The quick start sheet',
      'Target score, number of sets, and who serves first. Leave them alone and the defaults are a normal game; change them and the scorecard follows. There is no schedule to build and no players to register — this is the shortest path in the app between opening it and keeping score.',
      'The quick start sheet with target score, sets and serve settings'),
    shot('guide/02_quick_games/04_quick_start_teams',430,932,[430, 860],
      'Name the sides, or don’t',
      'Type the two team names, pull in a pair you have saved, or tap generate and let TournaQ name them. It is the difference between starting now and starting in a minute.',
      'Team naming in Quick Game setup, with an option to generate random names'),
  ],
},

'quick-game-score': {
  title:'Scoring a Quick Game', route:'/guide/modes/quick-game/scorecard', icon:'i-score', parent:'quick-game',
  eyebrow:'Quick Game · Scorecard',
  h1:['Scoring a ','Quick Game'],
  lead:'Built for one hand at the side of a court: big targets, the serving side marked, and undo for when the call goes the other way.',
  blocks:[
    panel('On the card',null,[
      item('i-score','Portrait','Tap a side to award the point. The server is highlighted, service passes automatically when the other side scores, and the set score sits above the running total.'),
      item('i-swap','Landscape','Turn the phone and the same controls rearrange for a net post or a table at the side of the court.'),
      item('i-sync','Change ends','When the combined score reaches the side-change point TournaQ says so and swaps the counters for you, so the scoreboard still matches which side of the net each team is standing on.'),
    ]),
    fbox('i-check','Which card this is','The classic scorecard — sets, target points and side switches. The same one every team competition uses.'),
    sect('What this card gives you','i-south'),
    opts('Quick Game · the scorecard',[
      opt('Score buttons','Plus and minus per side. Service passes to whoever just scored and the rotation moves on a slot; the score cannot go below zero.','Always'),
      opt('Serving indicator','The player pills mark who is serving, and rotate with the service.','Always'),
      opt('Target score','A dropdown on the card — 11, 15, 21, or a number you type. A Quick Game has no tournament to inherit it from, so it is set here.','Always'),
      opt('Side swap','A second dropdown: “No side swap”, every 5, every 7, or a number you type.','Always'),
      opt('Side-change reminder','“Total score is {score}. Teams must switch sides now.” — and the counters swap with you.','While a side-swap interval is set'),
      opt('Target-reached prompt','“{team} reached the target. Set {set} is won.” — then “Complete Set” (or “Complete Game”), or “Keep Playing”.','On reaching the target'),
      opt('Set overview','One card per set with its score; tap one to make it the active set.','Multi-set formats'),
      opt('Game Options','“Swap Teams — Switch left and right sides”, “Change Service — Advance to next server”, “Match History — Point-by-point scoring timeline”.','The options button'),
      opt('Match History','The rally-by-rally timeline, grouped by set, ending in the final score.','From Game Options'),
      opt('Lock banner','“Winner: {name}”, or “No winner determined”. The score buttons go quiet behind it.','Once the game is complete'),
      opt('Lineup','Tap a team name to edit who is playing.','When the game came from a saved team'),
      opt('Match controls','Complete / Undo Set, Complete / Undo Game, and “Save & Return to Games”.','Bottom of the card'),
      opt('Landscape','Turn the phone and the same controls rearrange for a net post or a side table.','Any time'),
    ], ['Control','What it does','When you see it']),
    sect('The card itself','i-south'),
    grid([
      {icon:'i-score', label:'Classic scorecard', cap:'What the other modes on this card do differently.', to:'sc-classic'},
    ]),
  ],
  next:['sc-classic','quick-game'],
  /* ══ INBOX · migriert aus pages/modes/quick-game.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Quick Game page · to review','i-south'),
    panel('Scoring the match','Built for one hand at the side of a court: big targets, the serving side marked, and undo for when the call goes the other way.',[]),
    shot('guide/02_quick_games/06_scorecard',430,932,[430, 860],
      'Portrait',
      'Tap a side to award the point. The server is highlighted, service passes automatically when the other side scores, and the set score sits above the running total.',
      'The Quick Game scorecard in portrait with both teams and the running score'),
    shot('guide/02_quick_games/07_scorecard_landscape',860,397,[860, 1600],
      'Landscape',
      'Turn the phone and the same controls rearrange for a net post or a table at the side of the court. Nothing is hidden — the layout changes, the functions do not.',
      'The same Quick Game scorecard rotated to landscape'),
    shot('guide/02_quick_games/09_dialog_switch_sides',430,932,[430, 860],
      'Change ends',
      'When the combined score reaches the side-change point TournaQ says so and swaps the counters for you, so the scoreboard still matches which side of the net each team is standing on.',
      'A dialog prompting the teams to change ends, with the counters swapping automatically'),
    panel('Finishing and keeping it','The match ends itself when someone reaches the target, and what happened is kept on the device without you saving anything.',[]),
    shot('guide/02_quick_games/10_dialog_game_won',430,932,[430, 860],
      'Game won',
      'Reach the target and TournaQ calls it, showing the final score for the set and the match. Nothing is submitted anywhere — the result is simply recorded on the phone that kept it.',
      'A dialog announcing the winning team and the final score'),
    shot('guide/02_quick_games/02_games_full',430,1112,[430, 645],
      'Your history',
      'Every finished match stays in the list with the full score for each set, so a disagreement about last Tuesday has an answer. It works with no signal, because nothing ever left the device.',
      'The full Quick Games history with the score of every recorded match'),
  ],
},

'm-elimination': {
  title:'Eliminations', route:'/guide/modes/elimination', icon:'i-bracket', parent:'brackets',
  eyebrow:'Team competition',
  h1:['Eliminations'],
  lead:'A plain knockout. Two flavours, depending on how harsh you want the first loss to be.',
  blocks:[
    panel('Two variants',null,[
      item('i-bracket','Single elimination','Lose once and you are out. Shortest possible format.'),
      item('i-sync','Double elimination','A loss drops you into the lower bracket. Lose twice and you are out.'),
    ]),
    fbox('i-target','Seeding','Seed the bracket or let TournaQ draw it. Either way the tree is built for you and results advance automatically.'),
    fbox('i-map','Read it as a bracket, not a list','Eliminations come with a zoomable bracket canvas — the actual tree — alongside the plain match list.'),
    sect('The three steps', 'i-south'),
    grid([
      {icon:'i-trophy', label:'Set it up', cap:'Teams, courts, format — and what it costs in time.', to:'m-elimination-hub'},
      {icon:'i-grid', label:'Run it', cap:'The live screen: standings, schedule, courts.', to:'m-elimination-run'},
      {icon:'i-score', label:'Score it', cap:'The card you score on, and what it shows.', to:'m-elimination-score'},
    ]),
  ],
  next:['m-elimination-hub','brackets'],
  /* ══ INBOX · migriert aus pages/modes/ko-system.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Eliminations page · to review','i-south'),
    fbox('i-target','Best for',null,[
      {icon:'i-check', title:'Events with a title at the end and limited time to decide it'},
      {icon:'i-check', title:'Fields where a seeded draw matters and the strongest teams should meet late'},
      {icon:'i-check', title:'Doubles: giving everyone a second chance without doubling the schedule'},
    ]),
    fbox('i-bracket','The draw, filling itself in','Teams enter on the left and the winners advance as results come in. Slots that are still undecided read TBD, so at any moment the tree shows exactly what is settled and what is not — which is the thing a printed bracket on a wall can never keep up with.'),
    fbox('i-sync','Winners, losers, grand final','The two halves run in parallel and converge on a grand final, so a team that lost early can still play its way back. It costs more matches than a straight knockout and delivers a fairer winner — which is the trade you are making when you pick it at setup.'),
  ],
},

'm-classic': {
  title:'TournaQ Classics', route:'/guide/modes/tournaq-classic', icon:'i-trophy', parent:'brackets',
  eyebrow:'Team competition',
  h1:['TournaQ ','Classics'],
  lead:'The full tournament day: a qualification phase first, then knockout tiers assigned by how you did in it.',
  blocks:[
    panel('How it runs',null,[
      step(1,'i-people','Groups drawn','Teams split into groups for the qualification phase.'),
      step(2,'i-grid','Group stage','Round robin inside each group.'),
      step(3,'i-bracket','Tier assignment','Where you finish decides which knockout tier you enter — everybody keeps playing, not just the top half.'),
      step(4,'i-trophy','Knockout','Tiers play out to their own finals.', {tone:'tint'}),
    ]),
    fbox('i-star','Why tiers','Nobody drives an hour to play two games and go home. Tiers keep every team in a competition they can still win.'),
    sect('The three steps', 'i-south'),
    grid([
      {icon:'i-trophy', label:'Set it up', cap:'Teams, courts, format — and what it costs in time.', to:'m-classic-hub'},
      {icon:'i-grid', label:'Run it', cap:'The live screen: standings, schedule, courts.', to:'m-classic-run'},
      {icon:'i-score', label:'Score it', cap:'The card you score on, and what it shows.', to:'m-classic-score'},
    ]),
  ],
  next:['m-classic-hub','brackets'],
  /* ══ INBOX · migriert aus pages/modes/group-single-elimination.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the TournaQ Classics page · to review','i-south'),
    fbox('i-target','Best for',null,[
      {icon:'i-check', title:'Day-long events where everyone should get a decent number of matches'},
      {icon:'i-check', title:'Fields too big for a straight round robin and too good for a straight knockout'},
      {icon:'i-check', title:'Tournaments that want a real winner and a fair route to it'},
    ]),
    fbox('i-map','How a team gets to the final','Finish first or second in your group and you are into the Gold bracket, in a slot decided by where you came. The labels — A1, B2, B1, A2 — are the qualification rule written on the diagram, so nobody has to be told how the draw was made.'),
    fbox('i-bracket','Gold and Silver, from uneven groups','Four groups of four, four and three. First and second go to Gold, third and fourth to Silver — and because the short group has no fourth place, Silver draws seven qualifiers into eight slots and carries a real bye. TournaQ works that out rather than making you fudge it.'),
  ],
},

'm-swiss': {
  title:'Swiss Systems', route:'/guide/modes/swiss-system', icon:'i-swap', parent:'brackets',
  eyebrow:'Team competition',
  h1:['Swiss Systems'],
  lead:'Paired each round against someone on the same score as you. No eliminations, a full schedule for everybody, and the field sorts itself.',
  blocks:[
    panel('How it runs',null,[
      step(1,'i-swap','Round 1 drawn','Pairings from the seeding, or at random.'),
      step(2,'i-target','Then: like against like','Every following round pairs teams by current score, so games stay close.'),
      step(3,'i-grid','As many rounds as you want','Take the suggested number of games, or set your own.'),
      step(4,'i-trophy','Standings decide','No bracket, no knockout — the table at the end is the result.', {tone:'tint'}),
    ]),
    fbox('i-check','Best when the field is large','Swiss gets a fair ranking out of many teams in far fewer games than a full round robin would take.'),
    sect('The three steps', 'i-south'),
    grid([
      {icon:'i-trophy', label:'Set it up', cap:'Teams, courts, format — and what it costs in time.', to:'m-swiss-hub'},
      {icon:'i-grid', label:'Run it', cap:'The live screen: standings, schedule, courts.', to:'m-swiss-run'},
      {icon:'i-score', label:'Score it', cap:'The card you score on, and what it shows.', to:'m-swiss-score'},
    ]),
  ],
  next:['m-swiss-hub','brackets'],
  /* ══ INBOX · migriert aus pages/modes/swiss-system.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Swiss Systems page · to review','i-south'),
    fbox('i-target','Best for',null,[
      {icon:'i-check', title:'Large fields with limited time — a Swiss ranks everyone in far fewer rounds than a round robin'},
      {icon:'i-check', title:'Events where knocking half the field out after one loss would empty the venue'},
      {icon:'i-check', title:'Mixed-ability fields that sort themselves into competitive matches within a round or two'},
    ]),
    fbox('i-swap','How the field sorts itself','Read it left to right: round one is drawn at random, then every round after pairs teams inside their own score group. A dashed line is a team floated down because its group had an odd number. By the last round the buckets are the ranking, and every match along the way was between teams with the same record.'),
  ],
},

'm-social-scramble': {
  title:'Social Scrambles', route:'/guide/modes/social-scramble', icon:'i-people', parent:'scrambles',
  eyebrow:'Scramble mode',
  h1:['Social Scrambles'],
  lead:'A timed, rotating mixer where teams are redrawn every round. Nobody stays partnered for long — the whole point is to play with and against as many different people as possible.',
  blocks:[
    panel('How a round works',null,[
      step(1,'i-people','Teams are drawn','Randomly, at the start of every round.'),
      step(2,'i-court','All courts play at once','For the set match duration.'),
      step(3,'i-timer','Time, then a short break','Before the next round is drawn.'),
      step(4,'i-trophy','Wins accumulate','Cumulative across all rounds — the standings are yours, not your team’s.', {tone:'tint'}),
    ]),
    panel('The two settings that matter most','Everything else has a sensible default.',[
      item('i-people','Players','Who is in the pool. Add or pause them at any point during the session.'),
      item('i-clock','Rounds','How many, and how long each one runs. That is your session length.'),
    ]),
    fbox('i-star','Fair by design','TournaQ schedules every player into the maximum number of rounds while keeping wait times as short as possible. When not everyone fits on court, sitting-out rotations are balanced so no player waits longer than others.'),
    fbox('i-check','Good for','Beach sessions, open days, and any group that wants competitive play without the pressure of a fixed bracket.'),
    sect('The three steps', 'i-south'),
    grid([
      {icon:'i-trophy', label:'Set it up', cap:'Teams, courts, format — and what it costs in time.', to:'m-social-scramble-hub'},
      {icon:'i-grid', label:'Run it', cap:'The live screen: standings, schedule, courts.', to:'m-social-scramble-run'},
      {icon:'i-score', label:'Score it', cap:'The card you score on, and what it shows.', to:'m-social-scramble-score'},
    ]),
  ],
  next:['m-social-scramble-hub','queue-modes'],
  /* ══ INBOX · migriert aus pages/modes/social-scramble.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Social Scrambles page · to review','i-south'),
    fbox('i-target','Best for',null,[
      {icon:'i-check', title:'Social beach volleyball sessions where mixing people is the whole point'},
      {icon:'i-check', title:'Club training nights where every player should meet every other player'},
      {icon:'i-check', title:'Groups of roughly 6 to 20 players with a fixed time slot'},
    ]),
  ],
},

'm-royal-rotation': {
  title:'Royal Rotations', route:'/guide/modes/royal-rotation', icon:'i-crown', parent:'queue-modes',
  eyebrow:'Queue mode · scramble competition',
  h1:['Royal ','Rotations'],
  lead:'King of the court, played as a scramble. You get a partner for the round, hold the court as long as you can win, and then the whole field rotates.',
  blocks:[
    panel('How it works',null,[
      step(1,'i-people','Partners drawn for the round','Your partner is fixed for the round — and different in the next one.'),
      step(2,'i-crown','Hold the court','Win and you stay. Lose and you go back to the queue.'),
      step(3,'i-timer','The round ends on the clock','Then the field is scrambled again.'),
      step(4,'i-trophy','Individual standings','Every point and every game is credited to you, not to the pairing.', {tone:'tint'}),
    ]),
    sect('What happens with an odd player', 'i-people'),
    panel('Odd player handling','Royal Rotations draws temporary teams for each round, so an odd roster leaves one team short. This is the only mode that has to answer the question — everywhere else players queue one by one, or arrive as a fixed pair.',[
      item('i-target','Placeholder','Any available player joins the short team, and stays with it for the rest of the round.'),
      item('i-swap','Jumper','Available players rotate fairly through the round to fill the short team, re-picked each time.'),
    ]),
    fbox('i-sync','Referees rotate independently','Whoever is off court can be suggested as referee, drawn fairly and independently of the partner rotation — it does not depend on there being an odd player.'),
    note('Draft note · which wording is right?',
      'The source diagrams disagree: one says “<b>a new partner every round</b>”, the other “<b>a fixed partner for 1 round</b>”. The draft assumes these describe the same thing from two sides — <b>fixed within the round, new in the next</b> — and words it that way. Confirm before this ships.'),
    sect('The three steps', 'i-south'),
    grid([
      {icon:'i-trophy', label:'Set it up', cap:'Teams, courts, format — and what it costs in time.', to:'m-royal-rotation-hub'},
      {icon:'i-grid', label:'Run it', cap:'The live screen: standings, schedule, courts.', to:'m-royal-rotation-run'},
      {icon:'i-score', label:'Score it', cap:'The card you score on, and what it shows.', to:'m-royal-rotation-score'},
    ]),
  ],
  next:['m-royal-rotation-hub','queue-modes'],
  /* ══ INBOX · migriert aus pages/modes/royal-rotation.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Royal Rotations page · to review','i-south'),
    fbox('i-target','Best for',null,[
      {icon:'i-check', title:'Bigger groups across several courts who want movement and a scoreboard'},
      {icon:'i-check', title:'Sessions where a plain scramble feels too gentle and a straight king feels too static'},
      {icon:'i-check', title:'Clubs mixing abilities — new pairs each round keep the games level'},
    ]),
  ],
},

'm-royal-shuffle': {
  title:'Royal Shuffles', route:'/guide/modes/royal-shuffle', icon:'i-crown', parent:'queue-modes',
  eyebrow:'Queue mode · scramble competition',
  h1:['Royal ','Shuffles'],
  lead:'A King of the Court mode where you are shuffled together with a new partner for every new rally on your court — and over a tournament you will have played alongside just about everyone in the group. This is a queue mode: if you have not read how the queue, the ejections and the ranking work, start with ' + pageLink('queue-modes','Queue Modes') + '.',
  blocks:[
    panel('How a game works',null,[
      step(1,'i-bolt','Define who serves','Either the challengers serve or the court team does — decided once, and it stays that way for the whole tournament.'),
      step(2,'i-score','Align on the scoring and ejection rules','Everyone on court should know what wins a game and what sends a side back into the queue. They are set out under ' + pageLink('queue-modes','Queue Modes') + '.'),
      step(3,'i-admin','Brief your referees','Make sure whoever referees knows what they are doing before the first rally.'),
      step(4,'i-timer','The referee starts the round','The referee calls the round on and keeps it running from there.'),
      step(5,'i-queue','Everyone moves up','The challengers move up to the court once the court team is ejected, and Up Next moves up to challengers once the challenger team is ejected.'),
    ]),
    fbox('i-sync','How the rounds run','Each round mixes the whole pool into fresh courts, and within a court players cycle on and off as they win or lose. Only the side currently on court can score. When the round timer runs out, everyone is mixed again.'),
    fbox('i-star','Fair by design','The queue always draws from the players with the least court time, so everybody plays about the same amount — and because partners keep changing, the standings reflect how you played, not who you were drawn with.'),
    sect('The three steps', 'i-south'),
    grid([
      {icon:'i-trophy', label:'Set it up', cap:'Teams, courts, format — and what it costs in time.', to:'m-royal-shuffle-hub'},
      {icon:'i-grid', label:'Run it', cap:'The live screen: standings, schedule, courts.', to:'m-royal-shuffle-run'},
      {icon:'i-score', label:'Score it', cap:'The card you score on, and what it shows.', to:'m-royal-shuffle-score'},
    ]),
  ],
  next:['m-royal-shuffle-hub','queue-modes'],
},

'm-doghouse': {
  title:'Doghouses', route:'/guide/modes/doghouse', icon:'i-shield', parent:'queue-modes',
  eyebrow:'Queue mode · scramble competition',
  h1:['Doghouses'],
  lead:'The same queue, with a crueller rule. The pinned side scores side-outs to escape — and one lost rally sends the count back to zero.',
  blocks:[
    panel('How a game works',null,[
      item('i-target','Win a rally','Score a side-out.'),
      item('i-sync','Lose a rally','Game lost — and the side-out count resets to zero.'),
      item('i-check','Reach your escape points target','Escaped. Back to the queue, with the win.'),
      item('i-swap','Hit the loss limit','Ejected. The next players step in.'),
      item('i-star','Ranking points by placement','Score at least one side-out and you earn at least one ranking point.'),
    ]),
    fbox('i-sync','How the rounds run','Each round mixes the whole pool into fresh courts, and within a court players cycle on and off. When the round timer runs out, everyone is mixed again.'),
    fbox('i-star','Fair by design','The queue always draws from the players with the least court time, so everybody plays about the same amount.'),
    sect('The three steps', 'i-south'),
    grid([
      {icon:'i-trophy', label:'Set it up', cap:'Teams, courts, format — and what it costs in time.', to:'m-doghouse-hub'},
      {icon:'i-grid', label:'Run it', cap:'The live screen: standings, schedule, courts.', to:'m-doghouse-run'},
      {icon:'i-score', label:'Score it', cap:'The card you score on, and what it shows.', to:'m-doghouse-score'},
    ]),
  ],
  next:['m-doghouse-hub','queue-modes'],
  /* ══ INBOX · migriert aus pages/modes/doghouse.html ══
     Zur Durchsicht geparkt, nicht platziert. Key loeschen, sobald der
     Inhalt in blocks steht. Sichtbar ueber SHOW_INBOX in render.js. ══ */
  inbox:[
    sect('From the Doghouses page · to review','i-south'),
    fbox('i-target','Best for',null,[
      {icon:'i-check', title:'Sessions with a competitive edge where nobody wants an easy game'},
      {icon:'i-check', title:'Groups that want continuous play with no downtime between rounds'},
      {icon:'i-check', title:'Anywhere a bit of jeopardy makes people try harder'},
    ]),
  ],
},

};

/* ══ Sidebar structure ═══════════════════════════════════════════════════ */
/* Seiten der Website, die im Rail stehen, aber keine Guide-Knoten sind. Sie
   tragen ihre Adresse selbst — relativ zu pages/, damit derselbe Eintrag aus
   pages/guide.html heraus und aus einer gebackenen Seite unter beliebiger
   Tiefe aufloest. Den Praefix setzt setzeKontext({nachbar}).

   Die Modus-Seiten stehen hier *und* als Guide-Knoten weiter unten, also
   zweimal mit zwei Zielen. Das ist bewusst und vorlaeufig: erst soll der
   Bestand vollstaendig sichtbar sein, dann wandern die Inhalte in den Guide,
   und dieser Ast faellt weg. */
const EXTERN = {
  'site-home':       {title:'Home',                              icon:'i-court',    url:'index.html'},

  'site-features':   {title:'Features',                          icon:'i-target',   url:'features.html'},

  'site-matrix':     {title:'Platform Features Hub',             icon:'i-grid',     url:'features/feature-matrix.html'},
  'site-scoring':    {title:'Match Controls',                    icon:'i-score',    url:'features/scoring.html'},
  'site-tournament': {title:'Tournament Management',             icon:'i-edit',     url:'features/tournament-features.html'},
  'site-live':       {title:'Live Tournament',                   icon:'i-timer',    url:'features/live-tournament.html'},
  'site-device':     {title:'Device &amp; Screen',               icon:'i-copy',     url:'features/device-scalability.html'},
  'site-navigation': {title:'Navigation',                        icon:'i-map',      url:'features/navigation.html'},
  'site-admin':      {title:'Player &amp; Team Administration',  icon:'i-admin',    url:'features/user-administration.html'},

  'site-hub':        {title:'Games &amp; Tournaments Hub',       icon:'i-arena',    url:'modes/games-and-tournaments.html'},
  'site-quick':      {title:'Quick Game',                        icon:'i-bolt',     url:'modes/quick-game.html'},
  'site-social':     {title:'Social Scrambles',                  icon:'i-people',   url:'modes/social-scramble.html'},
  'site-rotations':  {title:'Royal Rotations',                   icon:'i-crown',    url:'modes/royal-rotation.html'},
  'site-doghouses':  {title:'Doghouses',                         icon:'i-shield',   url:'modes/doghouse.html'},
  'site-shuffles':   {title:'Royal Shuffles',                    icon:'i-crown',    url:'modes/royal-shuffle.html'},
  'site-elim':       {title:'Eliminations',                      icon:'i-bracket',  url:'modes/ko-system.html'},
  'site-leagues':    {title:'Leagues',                           icon:'i-grid',     url:'modes/league.html'},
  'site-classics':   {title:'TournaQ Classics',                  icon:'i-trophy',   url:'modes/group-single-elimination.html'},
  'site-swiss':      {title:'Swiss Systems',                     icon:'i-swap',     url:'modes/swiss-system.html'},
  'site-other':      {title:'Other Modes',                       icon:'i-star',     url:'modes/other-tournament-modes.html'},

  'site-platform':   {title:'Platform',                          icon:'i-star',     url:'platform.html'},
  'site-downloads':  {title:'Downloads',                         icon:'i-download', url:'downloads.html'},
  'site-legal':      {title:'Legal',                             icon:'i-doc',      url:'legal.html'},
  /* Die drei Rechtstexte liegen nicht unter pages/, sondern in legal/. Weil
     jede Adresse hier relativ zu pages/ steht, geht es einen Ordner hoch —
     der Praefix aus setzeKontext({nachbar}) legt sich davor und hebt sich
     mit dem ../ auf, egal aus welcher Tiefe die Seite die Karte zeichnet. */
  'site-privacy':    {title:'Privacy Policy',                     icon:'i-shield',  url:'../legal/privacy-policy.html'},
  'site-terms':      {title:'Terms of Use',                       icon:'i-doc',     url:'../legal/terms-of-use.html'},
  'site-notice':     {title:'Legal Notice',                       icon:'i-admin',   url:'../legal/legal-notice.html'},
  'site-contact':    {title:'Contact',                           icon:'i-share',    url:'contact.html'},
};


/* ══ Sidebar structure ═══════════════════════════════════════════════════
   Der ganze Auftritt in einem Baum: die obere Reihe der Website als oberste
   Ebene, der User Guide als einer ihrer Aeste. Tiefe steht pro Eintrag; ein
   Kind ist schlicht der naechste Eintrag mit groesserer Tiefe.

   Queue Modes haengt unter beiden Wettbewerbsfamilien: eine Seite, von zwei
   Seiten erreichbar. Der dritte Eintrag ist der eigene Schluessel der Zeile,
   damit die zwei Zweige unabhaengig auf- und zuklappen.
   ══════════════════════════════════════════════════════════════════════════ */
const NAV = [
  {group:null, ids:[
     'site-home',
     'site-features',
       ['site-matrix',1],
         ['site-scoring',2],['site-tournament',2],['site-live',2],
         ['site-device',2],['site-navigation',2],['site-admin',2],
       ['site-hub',1],
         ['site-quick',2],['site-social',2],['site-rotations',2],['site-doghouses',2],
         ['site-shuffles',2],['site-elim',2],['site-leagues',2],['site-classics',2],
         ['site-swiss',2],['site-other',2],
     'site-platform',

     'home',
       ['administration',1],
         ['admin-hand',2],['admin-bulk',2],['admin-setup',2],
       ['arena',1],
         ['quick-game',2],['quick-game-hub',3],['quick-game-score',3],
         ['brackets',2],
           ['m-league',3],['m-league-hub',4],['m-league-run',4],['m-league-score',4],
           ['m-elimination',3],['m-elimination-hub',4],['m-elimination-run',4],['m-elimination-score',4],
           ['m-classic',3],['m-classic-hub',4],['m-classic-run',4],['m-classic-score',4],
           ['m-swiss',3],['m-swiss-hub',4],['m-swiss-run',4],['m-swiss-score',4],
           ['queue-modes',3,'queue-modes@brackets'],
             ['m-royal-duo',4],
         ['scrambles',2],
           ['m-social-scramble',3],['m-social-scramble-hub',4],['m-social-scramble-run',4],['m-social-scramble-score',4],
           ['queue-modes',3],
             ['m-royal-rotation',4],['m-royal-rotation-hub',5],['m-royal-rotation-run',5],['m-royal-rotation-score',5],
             ['m-royal-shuffle',4],['m-royal-shuffle-hub',5],['m-royal-shuffle-run',5],['m-royal-shuffle-score',5],
             ['m-doghouse',4],['m-doghouse-hub',5],['m-doghouse-run',5],['m-doghouse-score',5],
       ['tournament-hub',1],['setup-settings',2],
       ['tournament',1],['tournament-controls',2],
       ['scorecards',1],['sc-classic',2],['sc-scramble',2],['sc-queue',2],['exported',2],

     'site-downloads',
     'site-legal',
       ['site-privacy',1],['site-terms',1],['site-notice',1],
     'site-contact',
  ]},
];

