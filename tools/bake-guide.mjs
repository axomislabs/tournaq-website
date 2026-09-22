/* Backt die oberen Knoten des User Guide in echte Dateien mit echten Adressen.
 *
 *     node tools/bake-guide.mjs [--out v2]
 *
 * Warum: der Guide ist eine Datei mit Hash-Routen, und fuer Suchmaschinen
 * damit *eine* Seite mit *einem* Titel. Diese 24 Knoten tragen das Gewicht —
 * die Modi, die Familien, die Scorecards. Was darunter liegt, bleibt
 * Hash-Route innerhalb der Seite, zu der es gehoert.
 *
 * Es gibt keinen zweiten Renderer: js/guide/render.js wird hier unter Node
 * ausgefuehrt und im Browser geladen. Aendert sich der Guide, aendert sich
 * beides zugleich — genau die Drift, die uns die Modusnamen zerlegt hat, kann
 * hier nicht entstehen.
 *
 * Quelle ist js/guide/pages.js. An den erzeugten Dateien nichts von Hand
 * aendern, der naechste Lauf ueberschreibt sie.
 */
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const WURZEL = path.dirname(fileURLToPath(new URL('.', import.meta.url)).replace(/\/$/, ''));
/* fileURLToPath statt .pathname: eine file:-URL ist prozentkodiert, und ein
   Leerzeichen im Projektpfad kam hier als %20 an — 'Project%20TournaQ' gibt es
   auf keiner Platte, also scheiterte jeder Lauf mit ENOENT. */
const arg = process.argv.indexOf('--out');
const AUS = path.join(WURZEL, arg > 0 ? process.argv[arg + 1] : 'pages');

/* Die Knoten mit eigener Datei. Bewusst eine Liste und keine abgeleitete
 * Regel: welche Seite ihre eigene Adresse verdient, ist eine redaktionelle
 * Entscheidung, keine Eigenschaft der Daten. */
const EIGENE_SEITE = [
  'home', 'administration', 'arena', 'quick-game',
  'brackets', 'm-league', 'm-elimination', 'm-classic', 'm-swiss',
  'scrambles', 'm-social-scramble',
  'queue-modes', 'm-royal-rotation', 'm-royal-shuffle', 'm-doghouse', 'm-royal-duo',
  'tournament-hub', 'tournament', 'scorecards',
  // Eigene Adresse, damit der Menuepunkt verlinkbar ist und nicht nur als
  // Hash-Route unter guide.html existiert.
  'demo-data',
  'sc-classic', 'sc-scramble', 'sc-queue', 'exported',
  'navigation',
];

/* Alles relativ, nichts wurzelrelativ. Der Guide liegt mit im Baum unter
 * pages/, es gibt keinen Umzug mehr, den absolute Pfade ueberstehen muessten
 * — und relative Pfade haben den Vorzug, dass die Seiten sich auch per
 * Doppelklick aus dem Ordner oeffnen lassen, ohne Server.
 *
 * Zwei Praefixe je Datei: BASIS zeigt auf die Wurzel des Projekts (fuer
 * assets/, css/, js/), NACHBAR auf pages/ (fuer index.html und Geschwister). */
const tiefe = id => {
  const d = path.dirname(datei(id));          // '.' fuer pages/guide.html
  return d === '.' ? 0 : d.split('/').length;
};
const BASIS = id => '../'.repeat(tiefe(id) + 1);
const NACHBAR = id => '../'.repeat(tiefe(id));

/* ── Renderer laden ────────────────────────────────────────────────────── */
const ktx = vm.createContext({ console });
for (const f of ['js/guide/pages.js', 'js/guide/render.js']) {
  vm.runInContext(fs.readFileSync(path.join(WURZEL, f), 'utf8'), ktx, { filename: f });
}
const PAGES = vm.runInContext('PAGES', ktx);
const EXTERN = vm.runInContext('EXTERN', ktx);
const SEITENZAHL = vm.runInContext('navSeitenZahl()', ktx);

/* Das Sprite ist eine Quelle, keine Ausgabe: js/guide/sprite.js haelt es als
 * Zeichenkette, weil js/site-map.js es auf Seiten nachlegt, die keines
 * eingebettet haben. Von dort gelesen — nicht aus pages/guide.html, denn das
 * schreibt dieses Skript selbst, und es duerfte sich nicht aus seiner eigenen
 * Ausgabe speisen. */
const sprKtx = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(WURZEL, 'js/guide/sprite.js'), 'utf8'),
                sprKtx, { filename: 'js/guide/sprite.js' });
const SPRITE = vm.runInContext('GUIDE_SPRITE', sprKtx);
if (!SPRITE) throw new Error('Kein Sprite in js/guide/sprite.js');

/* ── Adressen ──────────────────────────────────────────────────────────── */
const datei = id => {
  const r = PAGES[id].route.replace(/^\//, '');       // "guide/modes/league"
  /* Die Wurzel des Guides ist pages/guide.html, nicht guide/index.html: so
     bleibt es eine Adresse statt zweier, der Eintrag in der oberen Reihe
     stimmt weiter, und alte Links auf guide.html#/... landen richtig. */
  return r === 'guide' ? 'guide.html' : r + '.html';
};
const DATEI = Object.fromEntries(EIGENE_SEITE.map(id => [id, datei(id)]));

/* Von welcher Datei aus welcher Knoten wie erreicht wird. Die Regel: jede
 * gebackene Seite besitzt ihren Unterbaum. Ein Ziel mit eigener Datei wird
 * ein Dateilink, ein Knoten darunter bleibt Hash-Route auf derselben Datei,
 * und ein Knoten aus einem fremden Unterbaum haengt als Hash an der Datei
 * seines naechsten gebackenen Vorfahren. So ist kein Knoten unter zwei
 * Dateiadressen erreichbar. */
function vorfahr(id) {
  let e = id;
  while (e && !DATEI[e]) e = PAGES[e] && PAGES[e].parent;
  return e || 'home';
}
function linkVon(vonId) {
  const hier = path.dirname(datei(vonId));
  return zuId => {
    const ziel = vorfahr(zuId);
    const hash = ziel === zuId ? '' : '#/' + zuId;
    /* Die eigene Zeile zeigt auf den eigenen Knoten, nicht auf '#/': ein
       leerer Hash faellt in render() auf 'home' zurueck, und ein Klick auf
       "Leagues" haette die Startseite in die Leagues-Adresse gezeichnet. */
    if (ziel === vonId) return hash || ('#/' + (vonId === 'home' ? '' : vonId));
    let rel = path.relative(hier, DATEI[ziel]);
    return (rel.startsWith('.') ? rel : './' + rel) + hash;
  };
}

/* ── Kopf und Rumpf ────────────────────────────────────────────────────── */
const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
                          .replace(/>/g, '&gt;').replace(/"/g, '&quot;');

/* Die Description kommt aus dem Lead — der sagt in einem Satz, was die Seite
 * ist, und genau danach fragt eine Suchmaschine. */
function description(lead) {
  const roh = String(lead).replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();
  if (roh.length <= 155) return roh;
  const kurz = roh.slice(0, 155);
  return kurz.slice(0, kurz.lastIndexOf(' ')) + '…';
}

function dokument(s, id, link) {
  const basis = BASIS(id);
  const nachbar = NACHBAR(id);
  return `<!DOCTYPE html>
<!--
  Erzeugt von tools/bake-guide.mjs aus js/guide/pages.js — nicht von Hand
  aendern, der naechste Lauf ueberschreibt diese Datei. Inhalt bearbeiten:
  js/guide/pages.js, dann "node tools/bake-guide.mjs".
-->
<html lang="en" data-nav-base="${nachbar}" data-nav-active="guide.html">

<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${esc(s.titel)}</title>
  <meta name="description" content="${esc(description(s.lead))}">
  <link rel="canonical" href="https://tournaq.com/pages/${datei(id)}">
  <link rel="icon" href="${basis}favicon.ico" sizes="any">
  <link rel="icon" type="image/png" sizes="32x32" href="${basis}assets/favicon-32.png">
  <link rel="icon" type="image/png" sizes="16x16" href="${basis}assets/favicon-16.png">
  <link rel="apple-touch-icon" href="${basis}apple-touch-icon.png">
  <link rel="manifest" href="${basis}site.webmanifest">
  <meta name="theme-color" content="#3A3E16">
  <link rel="stylesheet" href="${basis}css/style.css">
  <link rel="stylesheet" href="${basis}css/cards.css">
  <link rel="stylesheet" href="${basis}css/guide.css">
  <script src="${basis}js/main-nav.js" defer></script>
  <script src="${basis}js/i18n.js" defer></script>
</head>

<body>

${SPRITE}

  <header>
    <nav class="nav">
      <a class="logo" href="${nachbar}index.html">
        <img src="${basis}assets/brand/tournaq-logo-land-450.webp" alt="TournaQ" width="225" height="150" loading="eager" decoding="async">
      </a>
      <input type="checkbox" id="nav-toggle" class="nav-toggle" aria-label="Toggle navigation">
      <label for="nav-toggle" class="nav-burger" aria-label="Open navigation menu">
        <span></span><span></span><span></span>
      </label>
      <div id="main-nav-links"></div>
      <div class="lang-switcher"></div>
    </nav>

    <div class="lang-switcher"></div>

    <div class="hero">
      <h1 data-i18n="guide.hero.title">User Guide</h1>
      <p class="subtitle" data-i18n="guide.hero.subtitle">Every path through TournaQ, from the first tap to the finished scorecard.</p>
    </div>
  </header>

  <main>
    <div class="guide">

      <aside class="g-map" id="g-map" aria-label="Guide map">
        <p class="g-map-h">TournaQ</p>
        <p class="g-map-sub">${SEITENZAHL} pages</p>
        <nav id="g-mapnav">${s.navi}</nav>
      </aside>

      <div class="g-col">
        <div class="g-topbar">
          <button class="g-menu" id="g-menu" aria-label="Open guide map" aria-expanded="false" aria-controls="g-map">
            <svg class="g-ic"><use href="#i-menu"/></svg>Map
          </button>
          <div class="g-crumbs" id="g-crumbs">${s.crumbs}</div>
        </div>
        <div class="g-body" id="g-body" tabindex="-1">${s.body}</div>
      </div>

    </div>
  </main>

  <footer>
    <p data-i18n="footer.copyright">© 2026 Martin Adam · TournaQ</p>
    <p>
      <a href="${nachbar}index.html" data-i18n="footer.home">Home</a> &nbsp;·&nbsp;
      <a href="${nachbar}legal.html" data-i18n="footer.legalHub">Legal Hub</a> &nbsp;·&nbsp;
      <a href="${nachbar}contact.html" data-i18n="footer.contact">Contact</a>
    </p>
  </footer>

<!-- Der Inhalt oben steht fertig im Dokument. Diese Angaben sagen dem Guide,
     wo er liegt und wie er verlinkt, damit ein Sprung auf einen Unterknoten
     dieselben Adressen erzeugt wie das Backskript. -->
<script>
window.__guideBaked = true;
window.__guideNode  = ${JSON.stringify(id)};
window.__guideKontext = {
  basis: ${JSON.stringify(basis)},
  nachbar: ${JSON.stringify(nachbar)},
  datei: ${JSON.stringify(Object.fromEntries(EIGENE_SEITE.map(z => [z, link(z)])))},
  link: function (id) {
    return this.datei[id] || '#/' + (id === 'home' ? '' : id);
  }
};
window.__guideKontext.link = window.__guideKontext.link.bind(window.__guideKontext);
</script>
<script src="${basis}js/guide/pages.js" defer></script>
<script src="${basis}js/guide/render.js" defer></script>
<!-- Der Guide in DE/ES. Der Inhalt oben steht englisch im Dokument und ist der
     Fallback; locales.js haelt die Uebersetzungen, uebersetzen.js legt sie
     ueber PAGES, bevor boot.js zeichnet. Nur die Guide-Seiten laden das —
     js/i18n.js bleibt fuer alle uebrigen Seiten zustaendig. -->
<script src="${basis}js/guide/locales.js" defer></script>
<script src="${basis}js/guide/uebersetzen.js" defer></script>
<script src="${basis}js/guide/boot.js" defer></script>

</body>

</html>
`;
}

/* ── Backen ────────────────────────────────────────────────────────────── */
let n = 0;
const geschrieben = [];
for (const id of EIGENE_SEITE) {
  if (!PAGES[id]) throw new Error('Unbekannter Knoten: ' + id);
  const link = linkVon(id);
  const s = vm.runInContext(
    `setzeKontext({basis: ${JSON.stringify(BASIS(id))},` +
    ` nachbar: ${JSON.stringify(NACHBAR(id))},` +
    ` link: (id) => (${JSON.stringify(Object.fromEntries(
        Object.keys(PAGES).map(z => [z, link(z)])))})[id]});` +
    `zuruecksetzenNav(); renderPage(${JSON.stringify(id)})`, ktx);

  const ziel = path.join(AUS, datei(id));
  fs.mkdirSync(path.dirname(ziel), { recursive: true });
  fs.writeFileSync(ziel, dokument(s, id, link));
  geschrieben.push(datei(id));
  n++;
}
console.log(`${n} Seiten nach ${path.relative(WURZEL, AUS)}/ geschrieben`);

/* ── Der Baum fuer alle anderen Seiten ─────────────────────────────────── */
/* Dieselben Zeilen wie im Guide, aber ohne dessen Inhalt: js/guide/pages.js
 * waegt 180 KB, und die auf jeder Seite der Website zu laden, nur um eine
 * Navigation zu zeichnen, waere Verschwendung. Hier bleiben Titel, Symbol,
 * Elternteil und Route — mehr braucht renderNav nicht. */
const NAV_DATEN = vm.runInContext('NAV', ktx);
const stumpf = Object.fromEntries(Object.entries(PAGES).map(([id, s2]) =>
  [id, { title: s2.title, icon: s2.icon, parent: s2.parent || null, route: s2.route }]));
const baum = `/* Erzeugt von tools/bake-guide.mjs aus js/guide/pages.js — nicht von Hand
   aendern. Traegt denselben Baum wie der Guide, aber ohne dessen Inhalt, fuer
   die Seiten der Website ausserhalb des Guides. Zusammen mit
   js/guide/render.js und js/site-map.js ergibt das dieselbe Karte. */
const PAGES = ${JSON.stringify(stumpf)};
const EXTERN = ${JSON.stringify(EXTERN)};
const NAV = ${JSON.stringify(NAV_DATEN)};

/* Wohin ein Guide-Knoten zeigt, von pages/ aus gesehen. Die Knoten mit eigener
   Datei bekommen sie, alle anderen die Datei ihres naechsten gebackenen
   Vorfahren plus Hash-Route. js/site-map.js schlaegt hier nach. */
const GUIDE_DATEI = ${JSON.stringify(Object.fromEntries(Object.keys(PAGES).map(id => {
  const ziel = vorfahr(id);
  return [id, datei(ziel) + (ziel === id ? '' : '#/' + id)];
})))};
`;
fs.writeFileSync(path.join(WURZEL, 'js/guide/tree.js'), baum);

console.log(`js/guide/tree.js: ${Object.keys(stumpf).length} Knoten, ${Math.round(baum.length / 1024)} KB`);

/* ── Erkennungsbilder fuer pages/feedback.html ─────────────────────────────
 * Wer eine Rueckmeldung schreibt, muss zuerst wiedererkennen, wo er stand.
 * Der Guide hat die Bilder dafuer laengst — dieselben Aufnahmen, die auf den
 * Guide-Seiten unter einer Bildunterschrift stehen und auf pages/index.html
 * die Abschnitte tragen. Hier werden sie je Knoten gebuendelt, damit die
 * Feedback-Seite neben dem Namen einer Stelle auch ihr Bild zeigen kann.
 *
 * Eine eigene Datei und nicht js/guide/tree.js: den Baum laden alle Seiten
 * mit Karte, die Bilder braucht bisher nur eine. Was eine Seite braucht,
 * soll nicht jede tragen.
 *
 * Hoechstens drei je Knoten, und hochkant vor quer: im Streifen zaehlt der
 * erste Blick, und die Hochkant-Aufnahme ist die, unter der man den Schirm
 * im Kopf hat. Nur wo es ausschliesslich Querformat gibt (die Scorecards im
 * Liegen), steht eben das.
 */
const JE_KNOTEN = 3;

/* Die Knoten ohne eigene Aufnahme — Familien und Uebersichtsseiten, deren
 * Inhalt aus Karten und Text besteht. Welches Bild eine Stelle am besten
 * wiedererkennbar macht, ist eine redaktionelle Entscheidung wie EIGENE_SEITE
 * oben, keine Eigenschaft der Daten. Steht ein Knoten hier nicht, erbt er
 * weiter unten von seinem ersten Kind, sonst von seinem Elternteil.
 *
 * Der Alternativtext steht nur dort, wo die Aufnahme im Guide selbst nicht
 * vorkommt; sonst wird ihrer von dort genommen und bleibt eine Quelle. Er
 * steht dann in allen drei Sprachen hier, und nicht in js/guide/locales.js:
 * dessen Schluessel ist der englische Satz *aus dem Guide*, und diese Saetze
 * stehen nirgends im Guide. tools/guide-merge.mjs schoebe sie beim naechsten
 * Lauf unter WAISEN — als Beleg dafuer, dass jemand einen englischen Satz
 * geaendert hat, was hier schlicht nicht stimmte. */
const ERKENNUNG = {
  /* 'home' heisst auf der Feedback-Seite "Woanders" — was zu keinem Schirm
     gehoert. Ein Bild daneben wuerde genau das Gegenteil behaupten. */
  'home': [],

  'administration': [['guide/01_admin/01_administration', {
    en: 'The Administration screen with Players, Teams and Groups',
    de: 'Der Verwaltungsschirm mit Spielern, Teams und Gruppen',
    es: 'La pantalla de Administración con Jugadores, Equipos y Grupos' }]],
  'admin-hand': [['guide/01_admin/02_players'], ['guide/01_admin/07_teams'],
                 ['guide/01_admin/11_groups']],

  'arena': [['guide/00_shell/04_arena', {
    en: 'The TournaQ Arena with the game families and their modes',
    de: 'Die TournaQ Arena mit den Spielfamilien und ihren Modi',
    es: 'La TournaQ Arena con las familias de juego y sus modos' }]],
  'quick-game': [['guide/02_quick_game/01_games', {
    en: 'The Quick Games screen with Start Game above the match history',
    de: 'Der Schirm Quick Games mit Start Game über der Spielhistorie',
    es: 'La pantalla Quick Games con Start Game sobre el historial de partidos' }]],

  'tournament-hub': [['guide/08_league/01_hub', {
    en: 'A Tournament Hub with its setup card above the tournament history',
    de: 'Ein Turnier-Hub mit seiner Einrichtungskarte über der Turnierhistorie',
    es: 'Un Hub de Torneos con su tarjeta de configuración sobre el historial de torneos' }]],
  'tournament': [['guide/08_league/04_table'], ['guide/03_social_scramble/04_overview']],

  'brackets': [['guide/09_elimination_single/04_bracket'], ['guide/08_league/04_table']],
  'scrambles': [['guide/03_social_scramble/04_overview']],
  'queue-modes': [['guide/06_royal_shuffle/04_overview']],

  'm-league': [['guide/08_league/01_hub', {
    en: 'The Leagues Tournament Hub',
    de: 'Der Turnier-Hub der Ligen',
    es: 'El Hub de Torneos de las Ligas' }], ['guide/08_league/04_table']],
  'm-elimination': [['guide/09_elimination_single/01_hub', {
    en: 'The Eliminations Tournament Hub',
    de: 'Der Turnier-Hub der Eliminations',
    es: 'El Hub de Torneos de las Eliminaciones' }], ['guide/09_elimination_single/04_bracket']],
  'm-classic': [['guide/11_tournaq_classic/01_hub', {
    en: 'The TournaQ Classics Tournament Hub',
    de: 'Der Turnier-Hub der TournaQ Classics',
    es: 'El Hub de Torneos de los TournaQ Classics' }], ['guide/11_tournaq_classic/04_schedule']],
  'm-swiss': [['guide/12_swiss_system/01_hub', {
    en: 'The Swiss Systems Tournament Hub',
    de: 'Der Turnier-Hub der Schweizer Systeme',
    es: 'El Hub de Torneos de los Sistemas Suizos' }], ['guide/12_swiss_system/04_rounds']],
  'm-social-scramble': [['guide/03_social_scramble/01_hub', {
    en: 'The Social Scrambles Tournament Hub',
    de: 'Der Turnier-Hub der Social Scrambles',
    es: 'El Hub de Torneos de los Social Scrambles' }], ['guide/03_social_scramble/04_overview']],
  'm-royal-rotation': [['guide/04_royal_rotation/01_hub', {
    en: 'The Royal Rotations Tournament Hub',
    de: 'Der Turnier-Hub der Royal Rotations',
    es: 'El Hub de Torneos de las Royal Rotations' }], ['guide/04_royal_rotation/04_overview']],
  'm-royal-shuffle': [['guide/06_royal_shuffle/01_hub', {
    en: 'The Royal Shuffles Tournament Hub',
    de: 'Der Turnier-Hub der Royal Shuffles',
    es: 'El Hub de Torneos de los Royal Shuffles' }], ['guide/06_royal_shuffle/04_overview']],
  'm-doghouse': [['guide/07_doghouse_shuffle/01_hub', {
    en: 'The Doghouse Shuffles Tournament Hub',
    de: 'Der Turnier-Hub der Doghouse Shuffles',
    es: 'El Hub de Torneos de los Doghouse Shuffles' }], ['guide/07_doghouse_shuffle/04_overview']],
  'm-royal-duo': [['guide/05_royal_duo/01_hub', {
    en: 'The Royal Duos Tournament Hub',
    de: 'Der Turnier-Hub der Royal Duos',
    es: 'El Hub de Torneos de los Royal Duos' }], ['guide/05_royal_duo/04_overview']],
};

/* Jede Aufnahme, die im Guide vorkommt, mit ihren Massen und ihrem
 * Alternativtext. Der erste Fund gewinnt: dieselbe Datei steht auf mehreren
 * Seiten, beschrieben ist sie dort, wo sie zuerst erklaert wird. */
const AUFNAHMEN = {};
for (const s of Object.values(PAGES)) {
  for (const b of (s.blocks || [])) {
    if (b && b.t === 'shot' && !AUFNAHMEN[b.src]) {
      AUFNAHMEN[b.src] = { w: b.w, h: b.h, sizes: b.sizes, alt: b.alt || '' };
    }
  }
}

/* Masse und vorhandene Breiten einer Aufnahme, die der Guide nicht selbst
 * zeigt — von der Platte gelesen statt geraten. Ein falsches Seitenverhaeltnis
 * im width/height-Paar laesst die Seite beim Laden springen, und genau davor
 * schuetzt das Paar ja. */
function vp8Masse(datei) {
  const b = fs.readFileSync(datei);
  if (b.toString('latin1', 0, 4) !== 'RIFF' || b.toString('latin1', 8, 12) !== 'WEBP') {
    throw new Error('Kein WebP: ' + datei);
  }
  const art = b.toString('latin1', 12, 16);
  if (art === 'VP8 ') return { w: b.readUInt16LE(26) & 0x3fff, h: b.readUInt16LE(28) & 0x3fff };
  if (art === 'VP8L') {
    const v = b.readUInt32LE(21);
    return { w: (v & 0x3fff) + 1, h: ((v >> 14) & 0x3fff) + 1 };
  }
  if (art === 'VP8X') {
    return { w: (b[24] | (b[25] << 8) | (b[26] << 16)) + 1,
             h: (b[27] | (b[28] << 8) | (b[29] << 16)) + 1 };
  }
  throw new Error('Unbekannte WebP-Form ' + art + ': ' + datei);
}

function vonPlatte(src, alt) {
  const ordner = path.join(WURZEL, 'assets', path.dirname(src));
  const stamm = path.basename(src);
  const sizes = fs.readdirSync(ordner)
    .map(f => new RegExp('^' + stamm.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '-(\\d+)\\.webp$').exec(f))
    .filter(Boolean).map(m => Number(m[1])).sort((a, b) => a - b);
  if (!sizes.length) throw new Error('Keine Aufnahme zu ' + src);
  const { w, h } = vp8Masse(path.join(ordner, stamm + '-' + sizes[0] + '.webp'));
  return { w, h, sizes, alt: alt || '' };
}

/* Die Uebersetzungen des Guides. Sein Schluessel ist der englische Satz
 * selbst, also findet ein Alternativtext aus einem shot-Block seine deutsche
 * und spanische Fassung hier, ohne dass irgendwo eine zweite Liste entstuende.
 * Die Feedback-Seite laedt js/guide/locales.js nicht — 750 KB fuer drei
 * Bildunterschriften —, deshalb reisen die paar Saetze mit, die sie braucht. */
const sprKtx2 = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(WURZEL, 'js/guide/locales.js'), 'utf8'),
                sprKtx2, { filename: 'js/guide/locales.js' });
const UEBERSETZT = vm.runInContext('GUIDE_LOCALES', sprKtx2);
const SPRACHEN = ['de', 'es'];

/* Eine Aufnahme, wie der Streifen sie braucht — aus dem Guide, wenn er sie
 * kennt, sonst von der Platte. `alt` ist entweder nichts (dann steht der
 * Alternativtext im Guide) oder {en, de, es} aus der Tabelle oben. */
function aufnahme(src, alt) {
  const a = AUFNAHMEN[src] || vonPlatte(src, alt && alt.en);
  const en = (alt && alt.en) || a.alt;
  const aus = { src, w: a.w, h: a.h, sizes: a.sizes, alt: en };
  for (const s of SPRACHEN) {
    const u = (alt && alt[s]) || (UEBERSETZT[s] && UEBERSETZT[s][en]);
    /* Fehlt eine Uebersetzung, bleibt der englische Satz stehen — dieselbe
       Zusage wie ueberall sonst auf der Site. */
    if (u) aus[s] = u;
  }
  return aus;
}

const hochkant = a => a.h > a.w;

/* Was ein Knoten selbst zeigt: seine eigenen Aufnahmen in der Reihenfolge der
   Guide-Seite — dort steht die kennzeichnende zuerst, und die zu erraten waere
   schlechter, als sie abzuschreiben. Querformat faellt weg, solange es
   Hochkantes gibt: die Kachel im Streifen ist hochkant.

   Die langen darunter ("_full", eine gescrollte Liste ueber drei
   Schirmhoehen) bleiben drin. Die Kachel beschneidet sie oben, und oben steht,
   woran man den Schirm erkennt: Titelzeile, erste Zeilen. */
function eigene(id) {
  const alle = (PAGES[id].blocks || []).filter(b => b && b.t === 'shot')
    .map(b => aufnahme(b.src));
  const h = alle.filter(hochkant);
  return (h.length ? h : alle).slice(0, JE_KNOTEN);
}

const KINDER = {};
for (const [id, s] of Object.entries(PAGES)) {
  if (s.parent) (KINDER[s.parent] = KINDER[s.parent] || []).push(id);
}

/* Erst das Kuratierte, dann das Eigene, dann das erste Kind, das etwas hat,
 * und zuletzt das Elternteil. Die Reihenfolge ist die der Naehe: je weiter
 * oben gegriffen wird, desto ungefaehrer wird das Bild — aber ein ungefaehres
 * Bild verortet immer noch besser als gar keines. */
const gesehen = {};
function erkennung(id) {
  if (gesehen[id]) return gesehen[id];
  gesehen[id] = [];                       /* gegen Ringe, falls je einer entsteht */

  let aus;
  if (ERKENNUNG[id]) {
    aus = ERKENNUNG[id].map(([src, alt]) => aufnahme(src, alt));
  } else {
    aus = eigene(id);
    if (!aus.length) {
      for (const k of (KINDER[id] || [])) {
        aus = erkennung(k);
        if (aus.length) break;
      }
    }
    if (!aus.length && PAGES[id].parent) aus = erkennung(PAGES[id].parent);
  }
  gesehen[id] = aus;
  return aus;
}

const BILDER = {};
for (const id of Object.keys(PAGES)) {
  const a = erkennung(id);
  if (a.length) BILDER[id] = a;
}

const bilder = `/* Erzeugt von tools/bake-guide.mjs aus js/guide/pages.js — nicht von Hand
   aendern. Zu jedem Knoten des Guides die Aufnahmen, an denen man die Stelle
   in der App wiedererkennt: dieselben, die der Guide unter seinen
   Bildunterschriften zeigt. js/feedback.js zeichnet sie als Streifen neben
   den Namen der Stelle; \`src\` ist der Pfad unter assets/ ohne Groessensuffix,
   \`sizes\` sind die Breiten, die auf der Platte liegen. \`alt\` ist englisch,
   \`de\` und \`es\` tragen dieselbe Beschreibung in den beiden anderen Sprachen
   — fehlt eine, bleibt es beim englischen Satz. */
const GUIDE_SHOT = ${JSON.stringify(BILDER)};
`;
fs.writeFileSync(path.join(WURZEL, 'js/guide/shots.js'), bilder);

console.log(`js/guide/shots.js: ${Object.keys(BILDER).length} Knoten, ` +
            `${Object.values(BILDER).reduce((n, a) => n + a.length, 0)} Aufnahmen, ` +
            `${Math.round(bilder.length / 1024)} KB`);

/* ── Linkpruefung ──────────────────────────────────────────────────────── */
let tot = 0;
for (const rel of geschrieben) {
  const html = fs.readFileSync(path.join(AUS, rel), 'utf8');
  const hier = path.dirname(path.join(AUS, rel));
  for (const m of html.matchAll(/href="([^"#][^"]*?)"/g)) {
    const h = m[1];
    if (h.startsWith('http') || h.startsWith('#')) continue;
    const p = h.startsWith('/')
      ? path.join(WURZEL, h.split('#')[0])
      : path.join(hier, h.split('#')[0]);
    if (!fs.existsSync(p)) { console.log('  tot: ' + rel + ' -> ' + h); tot++; }
  }
}
console.log(tot === 0 ? 'Linkpruefung: kein toter Verweis' : `Linkpruefung: ${tot} tote Verweise`);
