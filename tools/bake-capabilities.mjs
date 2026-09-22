#!/usr/bin/env node
/* Backt den Capability Explorer aus den Quellen, die es schon gibt.
 *
 * Zwei Quellen, ein Datensatz:
 *
 *   js/guide/pages.js                       die 536 opt()-Zeilen des Guide.
 *                                           Modus und Flaeche stehen in der
 *                                           Route, die Details in der Zeile.
 *   archive/features/feature-matrix.html    die 59 Plattform-Features mit
 *                                           ihren handgepflegten Zellen.
 *
 * Jede Zeile ist eine von drei Arten, und die Art wird gelesen, nicht geraten:
 *
 *   capability   Was die App kann. Kommt aus der Feature-Matrix.
 *   setting      Ein Feld mit Werten und Standard. Eine opts()-Tabelle ohne
 *                eigene Spaltenkoepfe — der Guide faellt dann auf
 *                "Setting / Options / Default & range" zurueck.
 *   control      Ein Bedienelement oder ein Verhalten. Eine opts()-Tabelle
 *                mit eigenen Koepfen ("Control / What it does / When ...").
 *
 * Alles Uebrige hier ist Zuordnung, nicht Inhalt: welcher Modus in welchen
 * Familien steht, welche Modi eine gemeinsame Guide-Seite mitmeint, und welche
 * Zeilen dieselbe Sache von verschiedenen Seiten beschreiben. Diese drei
 * Tabellen sind die einzige Handarbeit — sie stehen bewusst offen und
 * kommentiert da, statt in den Daten zu verschwinden.
 *
 *     node tools/bake-capabilities.mjs
 *
 * Schreibt die Daten inline in pages/capabilities.html, zwischen die beiden
 * DATEN-Marken. Inline, weil die Seite von file:// aus funktionieren muss —
 * ein fetch() waere dort von CORS geblockt. Dieselbe Entscheidung wie in
 * archive/features/feature-matrix.html.
 */
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const WURZEL = path.dirname(fileURLToPath(new URL('.', import.meta.url)).replace(/\/$/, ''));
/* fileURLToPath statt .pathname: eine file:-URL ist prozentkodiert, und ein
   Leerzeichen im Projektpfad kam hier als %20 an — 'Project%20TournaQ' gibt es
   auf keiner Platte, also scheiterte jeder Lauf mit ENOENT. */
const lies = (p) => fs.readFileSync(path.join(WURZEL, p), 'utf8');

/* ── Die Modi, in der Reihenfolge des NAV-Baums ───────────────────────────
   `families` sind die Familien der Arena, `unit` die Frage, ob gemeldete
   Teams oder einzelne Spieler antreten, `card` die Scorecard-Familie (die
   Zuordnung steht als Fliesstext auf der Scorecards-Seite des Guide). Drei
   Achsen, die sich absichtlich nicht deckungsgleich schneiden: Royal
   Rotations sind ein Queue-Modus, spielen aber auf der Scramble-Karte. */
const MODES = [
  { id:'quick-game',      short:'Quick', name:'Quick Game',        families:['Quick'],             unit:'—',      card:'classic'  },
  { id:'league',          short:'Leag',  name:'Leagues',           families:['Team'],              unit:'Teams',  card:'classic'  },
  { id:'elimination',     short:'Elim',  name:'Eliminations',      families:['Team'],              unit:'Teams',  card:'classic'  },
  { id:'tournaq-classic', short:'Clsc',  name:'TournaQ Classics',  families:['Team'],              unit:'Teams',  card:'classic'  },
  { id:'swiss-system',    short:'Swis',  name:'Swiss Systems',     families:['Team'],              unit:'Teams',  card:'classic'  },
  { id:'royal-duo',       short:'Duos',  name:'Royal Duos',        families:['Team','Queue'],      unit:'Teams',  card:'queue'    },
  { id:'social-scramble', short:'Soci',  name:'Social Scrambles',  families:['Scramble'],          unit:'Player', card:'scramble' },
  { id:'royal-shuffle',   short:'Shfl',  name:'Royal Shuffles',    families:['Scramble','Queue'],  unit:'Player', card:'queue'    },
  { id:'royal-rotation',  short:'Rota',  name:'Royal Rotations',   families:['Scramble','Queue'],  unit:'Player', card:'scramble' },
  { id:'doghouse',        short:'Dogh',  name:'Doghouse Shuffles', families:['Scramble','Queue'],  unit:'Player', card:'queue'    },
];

/* ── Die vier Familien der Arena ──────────────────────────────────────────
   Queue ist keine fuenfte Familie neben den anderen, sondern eine Spielart
   quer durch zwei: Royal Duos ist eine Team Competition, die als Queue
   laeuft; Shuffles und Rotations sind Scrambles, die als Queue laufen. Die
   App sagt das selbst — "Queue Modes — Sit inside both families". Deshalb
   traegt jeder Modus oben eine Liste und keine einzelne Familie, und die
   Reihenfolge hier ist die der Arena. */
const FAMILIEN = [
  { id:'Quick',    label:'Quick Game'        },
  { id:'Scramble', label:'Scramble Modes'    },
  { id:'Team',     label:'Team Competitions' },
  { id:'Queue',    label:'Queue Modes'       },
];

const MODE_IDS = MODES.map(m => m.id);
const TURNIER = MODE_IDS.filter(id => id !== 'quick-game');   // die neun

/* ── Gemeinsame Guide-Seiten: wen meinen sie mit? ─────────────────────────
   Eine Zeile auf einer dieser Seiten gilt fuer mehrere Modi, ohne auf deren
   eigener Seite zu stehen. Die Matrix zeigt das als `inherited` — hellerer
   Haken —, damit sichtbar bleibt, wo der Guide zentral dokumentiert und wo
   er es je Modus ausbuchstabiert. */
const GETEILT = {
  'setup-settings':      { surface:'Setup',     modes:TURNIER },
  'tournament-controls': { surface:'Run',       modes:TURNIER },
  'sc-classic':          { surface:'Scorecard', modes:MODES.filter(m=>m.card==='classic').map(m=>m.id) },
  'sc-scramble':         { surface:'Scorecard', modes:MODES.filter(m=>m.card==='scramble').map(m=>m.id) },
  'sc-queue':            { surface:'Scorecard', modes:MODES.filter(m=>m.card==='queue').map(m=>m.id) },
  'exported':            { surface:'Scorecard', modes:TURNIER },
};

const FLAECHE = { 'tournament-hub':'Setup', 'tournament':'Run', 'scorecard':'Scorecard' };

/* ── Bloecke, die keine Faehigkeiten auflisten ────────────────────────────
   "What differs, mode by mode" ist ein Verweisblock: seine Zeilen heissen
   nach Modi ("Leagues", "Quick Game") und sagen, wo man weiterliest. Als
   Zeile im Explorer stand da eine Faehigkeit namens "Quick Game", die es
   angeblich in fuenf Modi gibt — Unsinn, der nur entsteht, weil die Tabelle
   dieselbe Form hat wie eine Optionstabelle. Sie faellt hier raus. */
const KEINE_FAEHIGKEIT = new Set(['What differs, mode by mode']);

/* ── Die Art einer Zeile ──────────────────────────────────────────────────
   Nicht geraten, sondern aus der Form der Guide-Tabelle gelesen. `opts()`
   ohne eigene Spaltenkoepfe faellt auf "Setting / Options / Default & range"
   zurueck — das ist eine Einstellung mit Wert und Standard. Wer eigene
   Koepfe setzt ("Control / What it does / When you see it", "Pill / ...",
   "Lock / ..."), beschreibt ein Bedienelement oder ein Verhalten der App.
   Der Guide haelt das sauber auseinander: von 536 opt()-Zeilen landen 213
   in der einen und 323 in der anderen Sorte, und nur drei Namen (Target
   score, Courts, Referees) kommen in beiden vor — zu Recht, das sind je
   eine Einstellung im Setup und eine Anzeige auf der Karte.

   Die dritte Art, `capability`, kommt aus der Feature-Matrix: dort steht
   nicht, was man einstellt, sondern was die App kann. */
const art = (block) => block.cols ? 'control' : 'setting';


/* ── Guide-Adressen, nach derselben Regel wie tools/bake-guide.mjs ────────
   Nicht jeder Knoten hat eine eigene Datei. Wer keine hat, haengt als
   Hash-Route an der Datei seines naechsten gebackenen Vorfahren. Die Liste
   ist bewusst dieselbe wie dort — waechst sie da, muss sie hier nachziehen. */
const EIGENE_SEITE = [
  'home', 'administration', 'arena', 'quick-game',
  'brackets', 'm-league', 'm-elimination', 'm-classic', 'm-swiss',
  'scrambles', 'm-social-scramble',
  'queue-modes', 'm-royal-rotation', 'm-royal-shuffle', 'm-doghouse', 'm-royal-duo',
  'tournament-hub', 'tournament', 'scorecards',
  'sc-classic', 'sc-scramble', 'sc-queue', 'exported',
  'navigation',
];

/* ── Quelle 1: die opt()-Zeilen des Guide ────────────────────────────────── */
const ktx = vm.createContext({});
vm.runInContext(lies('js/guide/pages.js'), ktx);
const PAGES = vm.runInContext('PAGES', ktx);

const datei = (id) => {
  const r = PAGES[id].route.replace(/^\//, '');
  return r === 'guide' ? 'guide.html' : r + '.html';
};
const HAT_DATEI = new Set(EIGENE_SEITE.filter(id => PAGES[id]));
const vorfahr = (id) => {
  let e = id;
  while (e && !HAT_DATEI.has(e)) e = PAGES[e] && PAGES[e].parent;
  return e || 'home';
};
/* Relativ von drafts/ aus — dort liegt der Prototyp. Zieht die Seite nach
   pages/, wird daraus ein Pfad ohne '../'. */
const href = (id) => {
  const ziel = vorfahr(id);
  return '../pages/' + datei(ziel) + (ziel === id ? '' : '#/' + id);
};

/* Schluessel einer Zeile ist Flaeche + Name, nicht der Name allein: "Rounds"
   im Setup und "Rounds" auf der Turnierseite sind zwei verschiedene Dinge. */
const settings = new Map();
const nimm = (surface, name) => {
  const key = surface + '|' + name;
  if (!settings.has(key)) settings.set(key, {
    key, art:null, name, surface, cells:{}, blocks:new Set(),
  });
  return settings.get(key);
};

let zeilen = 0, bloecke = 0, verwiesen = 0;
/* ── Wie die Spalten der Quelltabelle heissen ─────────────────────────────
   `opt()` ist positionsbasiert: Position 2 und 3 landen im Datensatz immer
   als `values` und `dflt`. Wie sie WIRKLICH heissen, entscheidet die
   Kopfzeile ihres Blocks — in einer Einstellungstabelle „Options / Default &
   range", in einer Pillentabelle „What it does / Editable here?". Bisher
   wurden die `cols` nur zur Artbestimmung gelesen und dann weggeworfen, und
   die Detailkarte beschriftete beide Spalten fest mit „Werte" und
   „Standard". Auf der Pille „{n}v{n}" stand damit „Standard: Edit here — it
   redraws only the rounds nobody has played yet" — die Auskunft, ob man die
   Sache im laufenden Turnier ueberhaupt noch aendern kann, unter der
   Ueberschrift „Standard".

   Gespeichert wird der Index in eine Tabelle der verschiedenen Kopfzeilen
   (es sind sechs), nicht die Zeichenketten je Zelle: bei ueber tausend
   Zellen waere das dieselbe Angabe tausendmal. */
const SPALTEN = [];
const spalten = (cols) => {
  if (!cols) return undefined;
  const k = cols.join('|');
  let i = SPALTEN.findIndex(x => x.join('|') === k);
  if (i < 0) { SPALTEN.push(cols.slice()); i = SPALTEN.length - 1; }
  return i;
};

for (const [id, p] of Object.entries(PAGES)) {
  for (const b of (p.blocks || [])) {
    if (!b || b.t !== 'opts') continue;
    if (KEINE_FAEHIGKEIT.has(b.label)) { verwiesen += b.rows.length; continue; }
    bloecke++;

    const m = /^\/guide\/modes\/([a-z-]+)\/([a-z-]+)$/.exec(p.route || '');
    const eigen = m && MODE_IDS.includes(m[1]);
    const geteilt = GETEILT[id];
    if (!eigen && !geteilt) {
      console.warn(`  ! opts-Block ohne Zuordnung: ${id} (${p.route}) — uebersprungen`);
      continue;
    }
    const surface = eigen ? FLAECHE[m[2]] : geteilt.surface;
    const ziele   = eigen ? [m[1]] : geteilt.modes;
    if (!surface) { console.warn(`  ! unbekannte Flaeche: ${p.route}`); continue; }

    for (const r of b.rows) {
      zeilen++;
      const row = nimm(surface, r.name);
      row.blocks.add(b.label);
      /* Eine Zeile ist eine Einstellung, sobald sie irgendwo als eine
         auftritt — die Werte-und-Standard-Fassung ist die genauere. */
      if (row.art !== 'setting') row.art = art(b);
      for (const mode of ziele) {
        /* Die eigene Seite eines Modus gewinnt immer gegen die geteilte:
           steht die Zeile dort mit eigenen Werten, sind das die genauen. */
        const vorhanden = row.cells[mode];
        if (vorhanden && vorhanden.own && !eigen) continue;
        row.cells[mode] = {
          own: !!eigen,
          values: r.values || '', dflt: r.dflt || '',
          what: r.what || '', when: r.when || '', help: r.help || '',
          ci: spalten(b.cols),
          page: id, route: p.route, block: b.label, href: href(id),
        };
      }
    }
  }
}

/* ── Quelle 2: die 59 Features aus der archivierten Matrix ───────────────── */
/* Ein Klammernzaehler statt einer Regex: die Literale enthalten Klammern und
   Anfuehrungszeichen, eine Regex bricht daran. */
function literal(src, anfang) {
  const i = src.indexOf(anfang);
  if (i < 0) throw new Error(`nicht gefunden: ${anfang}`);
  let j = i + anfang.length - 1, tief = 0, str = null, esc = false;
  for (; j < src.length; j++) {
    const c = src[j];
    if (str) {
      if (esc) esc = false;
      else if (c === '\\') esc = true;
      else if (c === str) str = null;
      continue;
    }
    if (c === '"' || c === "'") { str = c; continue; }
    if (c === '[' || c === '{') tief++;
    else if (c === ']' || c === '}') { tief--; if (!tief) return src.slice(i + anfang.length - 1, j + 1); }
  }
  throw new Error(`unbalanciert: ${anfang}`);
}

const matrixHtml = lies('archive/features/feature-matrix.html');
const FEATURES = vm.runInNewContext('(' + literal(matrixHtml, 'var FEATURES = [') + ')');
const CELLS    = vm.runInNewContext('(' + literal(matrixHtml, 'var DEFAULT_CELLS = {') + ')');

/* Die alte Matrix benennt zwei Modi anders und fuehrt eine Spalte fuer noch
   nicht gebaute Modi. Die Spalte fliegt raus, die Namen ziehen nach. */
const ALT = { 'ko-system':'elimination', 'group-single-elimination':'tournaq-classic' };
const SEKTION = {
  scoring:'Scorecard', tournament:'Run', live:'Run',
  device:'Scorecard', navigation:'Navigation', administration:'Administration',
};
const SEKTION_LABEL = {
  scoring:'Match Controls', tournament:'Tournament Management', live:'Live Tournament',
  device:'Device & Screen', navigation:'Navigation', administration:'Player & Team Administration',
};
const GUIDE_ZIEL = {
  scoring:'sc-classic', tournament:'tournament', live:'tournament',
  device:'scorecards', navigation:'navigation', administration:'administration',
};

const features = FEATURES.map(f => {
  const cells = {};
  for (const [alt, v] of Object.entries(CELLS[f.id] || {})) {
    const mode = ALT[alt] || alt;
    if (!MODE_IDS.includes(mode)) continue;          // other-tournament-modes
    if (v === 'yes')          cells[mode] = { own:true, state:'yes' };
    else if (v === 'planned') cells[mode] = { own:true, state:'planned' };
    else if (v === 'na')      cells[mode] = { own:true, state:'na' };
  }
  const zielId = GUIDE_ZIEL[f.section];
  return {
    key: 'feature|' + f.id, kind:'capability', name:f.title, desc:f.desc,
    surface: SEKTION[f.section], section: SEKTION_LABEL[f.section],
    status: f.status, cells,
    href: PAGES[zielId] ? href(zielId) : null,
  };
});

/* ── Was zusammengehoert ──────────────────────────────────────────────────
   Die dritte und letzte Handtabelle. Der Guide beschreibt eine Faehigkeit an
   so vielen Stellen, wie sie Gesichter hat: der Seitenwechsel ist eine
   Einstellung im Setup ("Side change"), ein Hinweis auf der Karte
   ("Side-change reminder"), ein Dropdown auf der Quick-Game-Karte ("Side
   swap") und ein Punkt in der Feature-Matrix ("Side Change Automation").
   Vier Zeilen, eine Sache. Ohne diese Tabelle sieht der Leser vier
   unverbundene Eintraege und die Suche nach "side swap" findet die
   Einstellung nicht, weil sie im Guide anders heisst.

   Schluessel sind `Flaeche|Name` fuer Guide-Zeilen und `feature|<id>` fuer
   Matrix-Zeilen — genau die Schluessel, die oben entstehen. Jede Zeile darf
   in hoechstens einem Buendel stehen; Tippfehler und Doppelungen meldet der
   Lauf unten. `suche` sind zusaetzliche Woerter, unter denen man das Buendel
   finden koennen soll, auch wenn sie in keiner Zeile stehen.

   `zweck` sagt, wofuer die Sache gut ist — EIN Satz fuer alle Zeilen des
   Buendels. Er steht hier von Hand, und das ist kein Rueckfall: keine der
   beiden Quellen kennt ihn. Die Feature-Matrix beschreibt eine Faehigkeit,
   der Guide eine Einstellung; was 21 Zeilen ueber Setup, Run und Scorecard
   hinweg zu einer Sache macht, ist genau die Behauptung, die diese Tabelle
   aufstellt — also gehoert ihre Begruendung daneben, zum Namen und den
   Suchwoertern, die auch von Hand stehen. Die naheliegende Ableitung waere
   falsch: nimmt man den Satz der fuehrenden Zeile, traegt „Aufstellung“
   den Untertitel „Every player and team import panel offers a group
   filter“ — ein Mitglied, das sich als Zusammenfassung ausgibt. Genau
   dieser Fehler stand schon einmal im Untertitel der Zeilen (siehe unten).

   Ein Buendel ohne `zweck` faellt nicht still auf die Zaehlung zurueck,
   sondern wird unten gemeldet.

   `name` und `zweck` stehen in en/de/es, und das ist der Unterschied zu
   allem anderen hier: die Zeilen selbst kommen englisch aus dem Guide und
   aus der Matrix, das Buendel dagegen ist Text dieser Tabelle. Stand er nur
   auf Deutsch, las die englische Seite deutsche Ueberschriften und deutsche
   Untertitel — genau das war der Fehler. Englisch ist wie in der Oberflaeche
   des Explorers Vorgabe und Rueckfall; fehlt eine Sprache, steht der
   englische Satz da. `suche` bleibt einsprachig und mischt die Woerter
   aller drei, denn es wird nie gezeigt, nur durchsucht — und die Suche
   bekommt ohnehin alle drei Namen und Zwecksaetze in den Heuhaufen.

   Unvollstaendig und soll es sein: was hier fehlt, bleibt eine einzelne
   Zeile und ist damit nicht falsch, nur unverbunden. */
const BUENDEL = [
  { name:{ en:'Side change', de:'Seitenwechsel', es:'Cambio de lado' },
    suche:'side swap change ends switch sides Seiten wechseln',
    zweck:{
      en:'When the sides swap: the change point in Setup, the announcement with the counter turned round on the card — or switched off and swiped across by hand.',
      de:'Wann die Seiten getauscht werden: der Wechselpunkt im Setup, die Ansage samt gedrehter Zähler auf der Karte — oder abgeschaltet und von Hand gewischt.',
      es:'Cuándo se cambian los lados: el punto de cambio en el Setup, el aviso con el marcador girado en la planilla — o desactivado y deslizado a mano.' }, keys:[
    'feature|scoring-10', 'Setup|Side change',
    'Scorecard|Side-change reminder', 'Scorecard|Side swap' ]},
  { name:{ en:'Target score', de:'Zielpunktzahl', es:'Puntos meta' },
    suche:'target points Zielpunkte Punktziel puntos meta',
    zweck:{
      en:'How far the game runs: the score in Setup, always visible on the card, and the prompt as soon as one side reaches it.',
      de:'Bis wohin gespielt wird: die Punktzahl im Setup, auf der Karte immer sichtbar, und die Nachfrage, sobald eine Seite sie erreicht.',
      es:'Hasta dónde se juega: los puntos en el Setup, siempre visibles en la planilla, y el aviso en cuanto un lado los alcanza.' }, keys:[
    'feature|scoring-9', 'Setup|Target score', 'Setup|Notify at target score',
    'Scorecard|Target score', 'Scorecard|Target-reached prompt' ]},
  { name:{ en:'Sets', de:'Sätze', es:'Sets' },
    suche:'sets best of Satz Saetze',
    zweck:{
      en:'Whether the game runs over sets and over how many: the app keeps the set score and moves into the next set by itself.',
      de:'Ob über Sätze gespielt wird und über wie viele: die App führt den Satzstand mit und wechselt von sich aus in den nächsten Satz.',
      es:'Si se juega por sets y por cuántos: la app lleva el marcador de sets y pasa al siguiente por su cuenta.' }, keys:[
    'feature|scoring-2', 'Setup|Sets per game', 'Scorecard|Set overview' ]},
  { name:{ en:'Serve', de:'Aufschlag', es:'Saque' },
    suche:'serve service serving Aufschlag Angabe saque',
    zweck:{
      en:'Who serves: the first serve is announced, after that the indicator moves on by itself with every point the other side wins.',
      de:'Wer angibt: die erste Angabe wird angesagt, danach wandert die Anzeige mit jedem Punktgewinn der Gegenseite selbst weiter.',
      es:'Quién saca: el primer saque se anuncia, y después el indicador avanza solo con cada punto que gana el otro lado.' }, keys:[
    'feature|scoring-3', 'Scorecard|Serves-first banner', 'Scorecard|Serving indicator' ]},
  { name:{ en:'Referee', de:'Schiedsrichter', es:'Árbitro' },
    suche:'referee ref umpire Schiri árbitro arbitro',
    zweck:{
      en:'Who runs a game: suggestions from the player pool, the choice between full courts and a referee kept free, and on every card, who is whistling right now.',
      de:'Wer ein Spiel leitet: Vorschläge aus dem Spielerfeld, die Wahl zwischen vollen Plätzen und freigehaltenem Schiri, und auf jeder Karte, wer gerade pfeift.',
      es:'Quién dirige un partido: sugerencias del grupo de jugadores, la elección entre pistas llenas y un árbitro reservado, y en cada planilla, quién pita en ese momento.' }, keys:[
    'feature|scoring-11', 'Setup|Referees', 'Run|Referees',
    'Run|“Refs covered” / “{n} without a ref”',
    'Scorecard|Referee banner', 'Scorecard|Change referee' ]},
  { name:{ en:'Courts', de:'Plätze', es:'Pistas' },
    suche:'court courts Platz Plaetze Feld Felder pista pistas',
    zweck:{
      en:'How many courts run at the same time and how the games are spread across them — mid-tournament too, when a court is added or drops out.',
      de:'Auf wie vielen Feldern gleichzeitig gespielt wird und wie die Spiele darauf verteilt werden — auch mitten im Turnier, wenn ein Platz dazukommt oder wegfällt.',
      es:'En cuántas pistas se juega a la vez y cómo se reparten los partidos — también a mitad del torneo, cuando se suma o se cae una pista.' }, keys:[
    'feature|tournament-10', 'feature|tournament-7',
    'Setup|Courts', 'Setup|One court per group',
    'Run|Courts', 'Run|Court allocation', 'Run|“{n} courts”',
    'Scorecard|Court', 'Scorecard|Start / Finish court' ]},
  { name:{ en:'Schedule & pace', de:'Zeitplan & Tempo', es:'Horario y ritmo' },
    suche:'schedule pace timing Zeitplan Tempo Startzeit horario ritmo',
    zweck:{
      en:'When it starts, how fast it runs and how you can tell whether it still fits: start time, game pace, preview and the “due / overdue” hint.',
      de:'Wann es losgeht, wie schnell gespielt wird und woran man sieht, ob es noch passt: Startzeit, Spieltempo, Vorschau und der Hinweis „fällig / überfällig“.',
      es:'Cuándo empieza, a qué ritmo se juega y en qué se ve si todavía cuadra: hora de inicio, ritmo de partido, vista previa y el aviso «pendiente / retrasado».' }, keys:[
    'feature|tournament-2', 'feature|tournament-3',
    'Setup|Start date', 'Setup|Start time', 'Setup|Anchored start',
    'Setup|Game pace', 'Setup|Pace alerts', 'Setup|Schedule detail',
    'Setup|Schedule Preview', 'Run|Schedule preview',
    'Run|“Est. finish {time}” / “Finished {time}”', 'Run|“Ends {time}”',
    'Scorecard|Schedule card' ]},
  { name:{ en:'Breaks', de:'Pausen', es:'Descansos' },
    suche:'break breaks rest Pause Pausen descanso descansos',
    zweck:{
      en:'How much rest sits between the games: a break after a round, after a slot and before the knockout — and how many games in a row anyone is asked to play.',
      de:'Wie viel Ruhe zwischen den Spielen liegt: Pause nach Runde, nach Slot und vor dem K.-o. — und wie viele Spiele hintereinander jemandem zugemutet werden.',
      es:'Cuánto descanso hay entre partidos: pausa tras la ronda, tras el bloque y antes de la eliminatoria — y cuántos partidos seguidos se le piden a alguien.' }, keys:[
    'Setup|Break after a round', 'Setup|Break Between Rounds', 'Setup|Break after a slot',
    'Setup|Break before knockout', 'Setup|Back-to-back' ]},
  { name:{ en:'Draw', de:'Auslosung', es:'Sorteo' },
    suche:'draw pairing seeding random Auslosung Setzung sorteo',
    zweck:{
      en:'How the pairings come about: random or seeded, rolled again or swapped one by one by hand — until the first game is running, then the draw is set.',
      de:'Wie die Paarungen zustande kommen: zufällig oder gesetzt, neu gewürfelt oder einzeln von Hand getauscht — bis das erste Spiel läuft, dann steht die Auslosung fest.',
      es:'Cómo salen los emparejamientos: al azar o preclasificados, vueltos a sortear o cambiados uno a uno a mano — hasta que arranca el primer partido; entonces el sorteo queda fijado.' }, keys:[
    'Setup|Pairing', 'Setup|Pair up players', 'Setup|Draw again', 'Setup|Swap {name} with',
    'Setup|Generation', 'Run|Bracket generation', 'Run|Adjust draw', 'Run|The draw is set',
    'Run|“Redraw”', 'Run|“Adjust draw”', 'Run|“Random”',
    'Run|“Reroll round 1”', 'Scorecard|Pairs the next round' ]},
  { name:{ en:'Game format', de:'Spielformat', es:'Formato de juego' },
    suche:'format 2v2 3v3 Spielformat formato',
    zweck:{
      en:'The rules by which a game is won — sets, target score, side change — as the default for the whole tournament and differing per round, slot or tier.',
      de:'Nach welchen Regeln ein Spiel gewonnen wird — Sätze, Zielpunktzahl, Seitenwechsel — als Vorgabe fürs ganze Turnier und abweichend je Runde, Slot oder Ebene.',
      es:'Con qué reglas se gana un partido — sets, puntos meta, cambio de lado — como ajuste para todo el torneo y distinto por ronda, bloque o nivel.' }, keys:[
    'Setup|Game format', 'Setup|Format', 'Setup|Format for one round',
    'Setup|Format for one slot', 'Setup|Format per tier',
    'Run|“{n}v{n}”', 'Run|“2v2”' ]},
  { name:{ en:'Clock', de:'Uhr', es:'Reloj' },
    suche:'timer clock time control duration Uhr Dauer reloj temporizador',
    zweck:{
      en:'When the game runs on time instead of points: round duration and session length, and on the card stop the clock, let it run on or correct the time.',
      de:'Wenn nicht auf Punkte, sondern auf Zeit gespielt wird: Rundendauer und Sessionlänge, und auf der Karte Uhr anhalten, weiterlaufen lassen oder Zeit korrigieren.',
      es:'Cuando no se juega a puntos sino a tiempo: duración de ronda y de la sesión, y en la planilla parar el reloj, dejarlo correr o corregir el tiempo.' }, keys:[
    'feature|scoring-5', 'feature|scoring-8', 'Setup|Match Duration',
    'Scorecard|Round timer', 'Scorecard|Session timer' ]},
  { name:{ en:'Counting points', de:'Punkte zählen', es:'Contar puntos' },
    suche:'scoring points history Punkte Verlauf puntos historial',
    zweck:{
      en:'The heart of the scorecard: tap point by point, every score stays saved with its history, and a finished card is locked instead of changed on.',
      de:'Der Kern der Scorecard: Punkt für Punkt tippen, jeder Stand bleibt mit seinem Verlauf gespeichert, und eine fertige Karte wird gesperrt statt weiter verändert.',
      es:'El núcleo de la planilla: tocar punto a punto, cada marcador queda guardado con su historial, y una planilla terminada se bloquea en vez de seguir cambiando.' }, keys:[
    'feature|scoring-1', 'feature|scoring-6', 'Scorecard|Score buttons',
    'Scorecard|Match History', 'Scorecard|Lock banner' ]},
  { name:{ en:'Entering a result later', de:'Ergebnis nachtragen', es:'Añadir el resultado después' },
    suche:'correct manual undo korrigieren nachtragen corregir deshacer',
    zweck:{
      en:'For everything that was not tapped live: take the last point back, or enter the final score of a game already played by hand.',
      de:'Für alles, was nicht live getippt wurde: den letzten Punkt zurücknehmen, oder das Endergebnis eines fertig gespielten Spiels von Hand eintragen.',
      es:'Para todo lo que no se registró en vivo: deshacer el último punto, o introducir a mano el resultado final de un partido ya jugado.' }, keys:[
    'feature|scoring-4', 'Run|Manually Set Score', 'Scorecard|Undo' ]},
  { name:{ en:'Tournament as Excel', de:'Turnier als Excel', es:'Torneo en Excel' },
    suche:'excel xlsx workbook export import Tabelle hoja de cálculo',
    zweck:{
      en:'The whole tournament out as a spreadsheet and back in again: an overview on paper or at the computer, and the results entered there come back into the app.',
      de:'Das ganze Turnier als Tabelle heraus und wieder herein: Übersicht auf Papier oder am Rechner, und die dort eingetragenen Ergebnisse kommen zurück in die App.',
      es:'Todo el torneo a una hoja de cálculo y de vuelta: una vista en papel o en el ordenador, y los resultados anotados allí regresan a la app.' }, keys:[
    'feature|tournament-11', 'Run|Export tournament', 'Run|Import tournament' ]},
  { name:{ en:'QR handover', de:'QR-Übergabe', es:'Traspaso por QR' },
    suche:'QR export import share Uebergabe traspaso',
    zweck:{
      en:'Hand a game to another phone and fetch the result back, with no network at all. The borrowed card knows its real position and writes nowhere but back.',
      de:'Ein Spiel an ein anderes Handy geben und das Ergebnis zurückholen, ganz ohne Netz. Die geliehene Karte kennt ihre echte Position und schreibt nirgends hin außer zurück.',
      es:'Pasar un partido a otro móvil y recuperar el resultado, sin red alguna. La planilla prestada conoce su posición real y no escribe en ningún sitio salvo de vuelta.' }, keys:[
    'feature|tournament-6', 'Run|Export game', 'Run|Import result',
    'Scorecard|App-bar QR menu', 'Scorecard|“Export result”',
    'Scorecard|The real position', 'Scorecard|Read-only event',
    'Scorecard|Upcoming games, frozen', 'Scorecard|It writes nowhere but back',
    'Scorecard|Back to Hub', 'Scorecard|Coming home' ]},
  { name:{ en:'Eject', de:'Rauswurf', es:'Expulsión' },
    suche:'eject kick out Rauswerfen expulsar',
    zweck:{
      en:'When a side leaves the court: automatically at the threshold of the mode, with a prompt on the card, or by hand — sit out one round or out for good.',
      de:'Wann eine Seite den Platz verlässt: automatisch an der Schwelle des Modus, mit Nachfrage auf der Karte, oder von Hand — eine Runde aussetzen oder ganz raus.',
      es:'Cuándo un lado deja la pista: automáticamente en el umbral del modo, con un aviso en la planilla, o a mano — saltar una ronda o fuera del todo.' }, keys:[
    'Setup|Auto-eject challenger',
    'Run|“Auto-eject @ {n}” / “Auto-eject off”',
    'Scorecard|Eject', 'Scorecard|Automatic eject prompts', 'Scorecard|Take this duo out' ]},
  { name:{ en:'Strike points', de:'Strafpunkte', es:'Puntos de strike' },
    suche:'strike strikes Strafpunkte',
    zweck:{
      en:'The threshold at which the side on court leaves as the winner instead of playing on — along with the prompt once it is reached. At 0 it is switched off.',
      de:'Die Schwelle, ab der die Seite am Platz als Sieger geht statt weiterzuspielen — samt der Nachfrage, wenn sie erreicht ist. Auf 0 ist sie abgeschaltet.',
      es:'El umbral a partir del cual el lado en pista se va como ganador en vez de seguir jugando — con el aviso al alcanzarlo. En 0 está desactivado.' }, keys:[
    'Setup|Strike Points', 'Run|“{n} pt strike”', 'Scorecard|Strike prompt' ]},
  { name:{ en:'Escape', de:'Ausbruch', es:'Escape' },
    suche:'escape doghouse Ausbruch',
    zweck:{
      en:'How many points the side in the Doghouse needs to get out again — along with the message once they have made it. At 0 it is switched off.',
      de:'Wie viele Punkte die Seite im Doghouse braucht, um wieder herauszukommen — samt der Meldung, wenn sie es geschafft hat. Auf 0 ist sie abgeschaltet.',
      es:'Cuántos puntos necesita el lado en el Doghouse para volver a salir — con el mensaje cuando lo consigue. En 0 está desactivado.' }, keys:[
    'Setup|Escape Points', 'Run|“{n} pt escape”', 'Scorecard|Escape prompt' ]},
  { name:{ en:'Loss limit', de:'Niederlagengrenze', es:'Límite de pérdidas' },
    suche:'loss limit out Niederlagen pérdidas perdidas',
    zweck:{
      en:'After how many lost games the side in the Doghouse is swapped out automatically, so that nobody gets stuck there. At 0 the limit is switched off.',
      de:'Nach wie vielen verlorenen Spielen die Seite im Doghouse automatisch getauscht wird, damit dort niemand festhängt. Auf 0 ist die Grenze abgeschaltet.',
      es:'Tras cuántos partidos perdidos se cambia automáticamente al lado en el Doghouse, para que nadie se quede atascado allí. En 0 el límite está desactivado.' }, keys:[
    'Setup|Loss Limit', 'Run|“{n} loss limit”', 'Scorecard|Loss-limit prompt' ]},
  { name:{ en:'Roster', de:'Aufstellung', es:'Participantes' },
    suche:'roster players teams fill random Aufstellung Meldeliste participantes',
    zweck:{
      en:'Who is playing: pull players and teams out of Administration, filter by group, create new ones or fill at random — and swap, pause or withdraw them mid-tournament.',
      de:'Wer mitspielt: Spieler und Teams aus der Verwaltung holen, nach Gruppe filtern, neu anlegen oder zufällig füllen — und mitten im Turnier tauschen, pausieren, abmelden.',
      es:'Quién juega: traer jugadores y equipos desde Administración, filtrar por grupo, crearlos nuevos o llenar al azar — y cambiarlos, pausarlos o retirarlos a mitad del torneo.' }, keys:[
    'feature|administration-8', 'feature|administration-9', 'feature|administration-10',
    'feature|administration-13',
    'Setup|Roster — Teams or Players', 'Setup|Teams', 'Setup|Players',
    'Setup|Target Players', 'Setup|Fill random', 'Setup|Fill {count} random',
    'Setup|Clear all', 'Setup|Count mismatch', 'Setup|Confirm the count',
    'Setup|Add existing teams', 'Setup|Create a duo', 'Setup|{count} duos',
    'Run|Teams / Players', 'Run|“{n} teams”', 'Run|“{n} players”',
    'Run|“Teams”', 'Run|“Duos”' ]},
  { name:{ en:'Landscape', de:'Querformat', es:'Horizontal' },
    suche:'landscape rotate Querformat drehen horizontal girar',
    zweck:{
      en:'Lay the phone on its side: the same controls rearranged, for the net post or the table at the edge of the court.',
      de:'Das Handy quer legen: dieselben Bedienelemente neu angeordnet, für den Netzpfosten oder den Tisch am Spielfeldrand.',
      es:'Poner el móvil de lado: los mismos controles reordenados, para el poste de la red o la mesa junto a la pista.' }, keys:[
    'feature|scoring-7', 'feature|device-3', 'Scorecard|Landscape' ]},
];

/* ── Der Untertitel ───────────────────────────────────────────────────────
   Hier stand vorher `[...s.blocks][0]` — die Ueberschrift des Blocks, der
   zufaellig zuerst gelesen wurde. Weil Royal Duo im Guide die erste
   Modusseite ist, trug jede Einstellung, die es in neun Modi gibt, den
   Untertitel "Royal Duo · Tournament Setup". Der Text beschrieb also nicht
   die Zeile, sondern die Reihenfolge, in der PAGES iteriert. Falsch, und
   auf eine Art falsch, die nach Absicht aussieht.

   Jetzt beschreibt der Untertitel die Sache selbst. Das Material steht in
   den Zellen: bei einer Einstellung sind das die Werte, bei einer Bedienung
   der Was-es-tut-Text — dieselbe Spalte, weil `opt()` positionsbasiert ist
   und die Kopfzeile der Tabelle entscheidet, wie sie heisst.

   Der Guide formuliert das je Modus verschieden, teils weil die Sache
   verschieden IST (Rounds sind bei Swiss "Auto ({n})" und bei Social
   Scramble "6, 8, 10, 12 …"). Genommen wird die haeufigste Fassung, und
   wie viele es sonst noch gibt, sagt die Zeile dazu — ausbuchstabiert
   stehen sie ohnehin aufgeklappt bei jedem Modus. */
const haeufigste = (texte) => {
  const n = new Map();
  /* Ein blosser Gedankenstrich ist im Guide die Angabe "hier gibt es dazu
     nichts" — Royal Duo fuehrt "Odd player handling" so, weil die Frage
     dort nicht gestellt wird. Als Untertitel waere das ein Strich, wo eine
     Beschreibung stehen soll; er zaehlt deshalb nicht mit. */
  texte.filter(t => t && !/^[\u2014\u2013-]$/.test(t.trim()))
       .forEach(t => n.set(t, (n.get(t) || 0) + 1));
  if (!n.size) return { text:'', varianten:0 };
  const beste = [...n.entries()].sort((a, b) => b[1] - a[1])[0];
  return { text:beste[0], varianten:n.size };
};

const rows = [
  ...features,
  ...[...settings.values()].map(s => {
    const zellen = Object.values(s.cells);
    const d = haeufigste(zellen.map(c => c.values));
    return {
      key:s.key, kind:s.art, name:s.name, surface:s.surface,
      desc:d.text, varianten:d.varianten,
      /* Die Blockueberschriften bleiben in den Daten — sie sind die Antwort
         auf "wo im Guide steht das", nur eben nicht auf "was ist das". Die
         Seite zeigt sie je Modus im aufgeklappten Teil. */
      blocks:[...s.blocks], section:'', status:'available',
      cells:Object.fromEntries(Object.entries(s.cells).map(([m, c]) => [m, { ...c, state:'yes' }])),
    };
  }),
];

/* ── Gegenprobe: widerspricht eine Feature-Zeile ihrer Kartenfamilie? ─────
   Modi, die auf derselben Scorecard spielen, koennen bei einer Faehigkeit
   DIESER Karte nicht auseinanderfallen. Steht sie fuer einen Modus auf
   'yes' und fuer einen anderen derselben Familie auf 'planned', ist das
   logisch unmoeglich — eine Karte hat etwas oder hat es nicht.

   Nur dieser Fall wird gemeldet. 'yes' gegen 'na' kann echt sein: Quick Game
   hat keinen Bracket, Social Scrambles keine Gameplay-Rotation, obwohl sie
   die Karte mit anderen teilen. Die Pruefung ist eine Leselupe fuer die
   handgepflegte Haelfte, kein Urteil. */
const KARTE = {};
MODES.forEach(m => { (KARTE[m.card] ||= []).push(m.id); });

for (const r of rows) {
  r.conflict = null;
  if (r.kind !== 'capability' || r.surface !== 'Scorecard') continue;
  for (const [fam, ids] of Object.entries(KARTE)) {
    const zust = ids.map(m => (r.cells[m] && r.cells[m].state) || 'na');
    if (zust.includes('yes') && zust.includes('planned')) {
      r.conflict = {
        card: fam,
        yes:     ids.filter((m, i) => zust[i] === 'yes'),
        planned: ids.filter((m, i) => zust[i] === 'planned'),
      };
      break;
    }
  }
}

/* Reichweite: die Facette, die "zeig mir nur, was diesen Modus anders macht"
   beantwortet. Gezaehlt werden nur Modi, die die Zeile wirklich haben. */
for (const r of rows) {
  const hat = Object.entries(r.cells).filter(([, c]) => c.state === 'yes').map(([m]) => m);
  /* "Eine Familie" heisst jetzt: es gibt EINE Familie, die alle Modi der
     Zeile enthaelt — nicht mehr "alle Modi tragen dieselbe Nummer". Bei
     mehrwertigen Familien ist das der Unterschied zwischen einer Zeile, die
     alle vier Team Competitions samt Royal Duos abdeckt (eine Familie), und
     einer, die Duos und Leagues meint, aber Eliminations auslaesst. */
  const traegt = (f) => hat.every(m => MODES.find(x => x.id === m).families.includes(f));
  const einzelne = FAMILIEN.map(f => f.id).filter(traegt);
  /* "Modusunabhaengig" ist keine leere Zeile, sondern eine eigene Aussage:
     die Faehigkeit existiert, aber sie hat gar keine Modusachse. Die alte
     Matrix schreibt das als 'na' in JEDE Spalte — More, der Teams-Hub und
     die Gruppen sind keine Turniereigenschaften, sie stehen daneben. Ohne
     eigenen Zustand landeten sie bei 'none' neben Sachen, die es wirklich
     noch nirgends gibt, und die Liste zeigte zehn graue Chips fuer eine
     Zeile, bei der die Frage "in welchem Modus?" schon falsch ist. */
  const zellen = Object.values(r.cells);
  const unabhaengig = zellen.length > 0 && zellen.every(c => c.state === 'na');
  r.reach = unabhaengig ? 'independent'
          : hat.length === 0 ? 'none'
          : hat.length === 1 ? 'unique'
          : hat.length >= MODE_IDS.length - 1 ? 'all'
          : einzelne.length ? 'family'
          : 'several';
  r.family = einzelne[0] || null;
  r.n = hat.length;
}

/* ── Buendel anhaengen, mit Gegenprobe ────────────────────────────────────
   Eine Handtabelle gegen erzeugte Schluessel ist die Stelle, an der ein
   Tippfehler still verschwindet: der Schluessel trifft nichts, das Buendel
   ist einen Eintrag kleiner, und niemand merkt es. Deshalb wird jeder
   Schluessel geprueft und jeder Treffer nur einmal vergeben. */
const nachKey = new Map(rows.map(r => [r.key, r]));
const vergeben = new Map();
const unbekannt = [], doppelt = [];
const RANG = { capability:0, setting:1, control:2 };

const bundles = BUENDEL.map((b, i) => {
  const id = 'b' + i;
  const keys = [];
  for (const k of b.keys) {
    const r = nachKey.get(k);
    if (!r)               { unbekannt.push(`${b.name.de}: ${k}`); continue; }
    if (vergeben.has(k))  { doppelt.push(`${k} — ${vergeben.get(k)} und ${b.name.de}`); continue; }
    vergeben.set(k, b.name.de);
    r.bundle = id;
    keys.push(k);
  }
  /* Die Faehigkeit fuehrt das Buendel an, sonst die Einstellung, sonst was
     kommt — das Buendel soll dort in der Liste stehen, wo man die Sache
     einstellt, nicht dort, wo sie zufaellig zuerst erwaehnt wird. */
  const lead = keys.slice().sort((x, y) =>
    RANG[nachKey.get(x).kind] - RANG[nachKey.get(y).kind])[0] || null;
  return { id, name:b.name, suche:b.suche || '', zweck:b.zweck || null, keys, lead };
}).filter(b => b.keys.length);

/* Gezaehlt wird je Sprache, nicht je Buendel. Fehlt nur eine, steht dort der
   englische Satz — lesbar, aber unuebersetzt. Fehlt auch der englische, faellt
   das Buendel auf seine Zusammensetzung zurueck: "1× Einstellung · 12×
   Bedienung". Das ist der Zustand, von dem die Zweckzeile weggefuehrt hat,
   deshalb wird beides gemeldet und die fehlende Sprache dazu. */
const SPRACHEN = ['en', 'de', 'es'];
const ohneZweck = bundles.filter(b => SPRACHEN.some(l => !(b.zweck && b.zweck[l])));

/* Dasselbe fuer den Namen: faellt eine Sprache aus, steht auf der Seite die
   englische Ueberschrift — richtig, aber nicht uebersetzt. Still bleibt das
   nicht. */
const ohneName = bundles.filter(b => SPRACHEN.some(l => !(b.name && b.name[l])));

/* ── Gegenprobe 2: sagt der Guide etwas anderes als die Matrix? ──────────
   Die erste Gegenprobe vergleicht die Matrix mit sich selbst. Diese hier
   vergleicht sie mit dem Guide — moeglich erst, seit die Buendel sagen,
   welche Guide-Zeilen dieselbe Sache beschreiben wie eine Faehigkeit.

   Gemeldet wird nur der eine Fall, der nicht wahr sein kann: die Matrix
   fuehrt etwas als GEPLANT, waehrend der Guide es fuer denselben Modus
   ausbuchstabiert — mit Werten, Standard und Hilfetext. "Export Tournament
   to Excel" steht auf planned, und zwei Zeilen weiter unten beschreibt der
   Guide den Vorabdialog des Imports im Wortlaut.

   'yes' gegen 'na' wird bewusst NICHT gemeldet: dass eine Karte etwas hat
   und eine andere nicht, ist der Normalfall. Nur 'planned' ist eine Aussage
   ueber die Zukunft, und die widerlegt ein Guide-Eintrag in der Gegenwart. */
for (const b of bundles) {
  const mit = b.keys.map(k => nachKey.get(k));
  const faehig = mit.filter(r => r.kind === 'capability');
  const ausGuide = mit.filter(r => r.kind !== 'capability');
  if (!faehig.length || !ausGuide.length) continue;

  const belegt = new Set();
  ausGuide.forEach(r => Object.entries(r.cells).forEach(([m, c]) => {
    if (c.state === 'yes') belegt.add(m);
  }));
  if (!belegt.size) continue;

  for (const f of faehig) {
    const modi = [...belegt].filter(m => f.cells[m] && f.cells[m].state === 'planned');
    if (!modi.length && f.status !== 'planned') continue;
    f.stale = {
      modes: modi,
      status: f.status === 'planned',
      quelle: ausGuide.filter(r => [...belegt].some(m => r.cells[m] && r.cells[m].state === 'yes'))
                      .map(r => r.name),
    };
  }
}

const DATEN = { modes:MODES, families:FAMILIEN, rows, bundles, cols:SPALTEN,
                built:new Date().toISOString().slice(0, 10) };

const ZIEL = 'pages/capabilities.html';
const seite = lies(ZIEL);
const A = '/* ==DATEN-ANFANG== */', E = '/* ==DATEN-ENDE== */';
const [i, j] = [seite.indexOf(A), seite.indexOf(E)];
if (i < 0 || j < 0) throw new Error(`Marken fehlen in ${ZIEL}`);
fs.writeFileSync(path.join(WURZEL, ZIEL),
  seite.slice(0, i + A.length) + '\n  var DATA = ' + JSON.stringify(DATEN) + ';\n  ' + seite.slice(j));

const zaehl = (k) => rows.filter(r => r.kind === k).length;
console.log(`${bloecke} opts-Bloecke, ${zeilen} opt-Zeilen gelesen` +
  (verwiesen ? ` (${verwiesen} Verweiszeilen uebersprungen)` : ''));
console.log(`${zaehl('capability')} Faehigkeiten + ${zaehl('setting')} Einstellungen + ` +
  `${zaehl('control')} Bedienung/Verhalten = ${rows.length} Zeilen → ${ZIEL}`);
console.log(`${bundles.length} Buendel fassen ${vergeben.size} davon zusammen, ` +
  `${rows.length - vergeben.size} stehen allein`);
const fehlend = (feld) => (b) => SPRACHEN.filter(l => !(b[feld] && b[feld][l])).join('/');
if (ohneZweck.length) {
  console.log(`\n${ohneZweck.length} Buendel ohne Zwecksatz — dort steht die englische Fassung`);
  console.log('oder, fehlt auch die, nur die Zaehlung:');
  ohneZweck.forEach(b => console.log(`   ${b.name.de || b.name.en} — fehlt: ${fehlend('zweck')(b)}`));
}
if (ohneName.length) {
  console.log(`\n${ohneName.length} Buendel ohne uebersetzten Namen — dort steht die englische Ueberschrift:`);
  ohneName.forEach(b => console.log(`   ${b.name.en || b.id} — fehlt: ${fehlend('name')(b)}`));
}
if (unbekannt.length) {
  console.log(`\n${unbekannt.length} Buendel-Schluessel treffen keine Zeile:`);
  unbekannt.forEach(u => console.log('   ' + u));
}
if (doppelt.length) {
  console.log(`\n${doppelt.length} Zeilen sind zweimal vergeben (die erste gewinnt):`);
  doppelt.forEach(d => console.log('   ' + d));
}
console.log(`${SPALTEN.length} verschiedene Spaltenkoepfe: ` +
  SPALTEN.map(c => c.slice(1).join(' / ')).join(' · '));
console.log('Reichweite:', ['all','several','family','unique','independent','none']
  .map(k => `${k} ${rows.filter(r => r.reach === k).length}`).join(' · '));

/* Zeilen ohne einen einzigen Modus sind kein Fehler, sondern eine Frage an
   die Redaktion — und es sind zwei verschiedene Fragen. Steht in JEDER Spalte
   'na', hat die Zeile keine Modusachse (More, Teams-Hub, Gruppen): das ist
   'independent' und beantwortet. Steht ueberall 'planned', gibt es die Sache
   wirklich noch nirgends. Beide beim Namen genannt, damit sie nicht still in
   der Liste haengen — aber getrennt, weil nur die zweite Sorte offen ist. */
const streit = rows.filter(r => r.conflict);
if (streit.length) {
  console.log(`\n${streit.length} Feature-Zeilen widersprechen ihrer Scorecard-Familie:`);
  const kurz = (id) => MODES.find(m => m.id === id).short;
  streit.forEach(r => console.log(
    `   ${r.name.padEnd(36)} [${r.conflict.card}] ` +
    `${r.conflict.yes.map(kurz).join('+')}=vorhanden, ` +
    `${r.conflict.planned.map(kurz).join('+')}=geplant`));
  console.log('   → die Zellen stammen aus DEFAULT_CELLS der archivierten Matrix,');
  console.log('     nicht aus dem Guide. Dieselbe Karte kann nicht beides sein.');
}

const alt2 = rows.filter(r => r.stale);
if (alt2.length) {
  console.log(`\n${alt2.length} Faehigkeiten stehen auf "geplant", obwohl der Guide sie beschreibt:`);
  const kurz = (id) => MODES.find(m => m.id === id).short;
  alt2.forEach(r => console.log(
    `   ${r.name.padEnd(34)} ` +
    (r.stale.status ? 'Zeile=geplant ' : '') +
    (r.stale.modes.length ? `Zellen=geplant: ${r.stale.modes.map(kurz).join('+')} ` : '') +
    `\n      im Guide: ${r.stale.quelle.join(', ')}`));
  console.log('   → die Matrix ist die aeltere Quelle. Der Guide ist gepflegt.');
}

const unabh = rows.filter(r => r.reach === 'independent');
if (unabh.length) {
  console.log(`\n${unabh.length} Zeilen sind modusunabhaengig (alle Zellen 'na'):`);
  unabh.forEach(r => console.log(`   [${r.kind}] ${r.surface} · ${r.name}`));
}

const leer = rows.filter(r => r.reach === 'none');
if (leer.length) {
  console.log(`\n${leer.length} Zeilen gibt es in keinem Modus — zu pruefen:`);
  leer.forEach(r => console.log(
    `   [${r.kind}] ${r.surface} · ${r.name}` +
    (Object.values(r.cells).some(c => c.state === 'planned') ? ' (ueberall geplant)' : '')));
}
