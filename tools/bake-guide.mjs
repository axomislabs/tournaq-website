/* Backt die oberen Knoten des User Guide in echte Dateien mit echten Adressen.
 *
 *     node tools/bake-guide.mjs [--out v2]
 *
 * Warum: der Guide ist eine Datei mit Hash-Routen, und fuer Suchmaschinen
 * damit *eine* Seite mit *einem* Titel. Diese 23 Knoten tragen das Gewicht —
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

const WURZEL = path.dirname(new URL('.', import.meta.url).pathname.replace(/\/$/, ''));
const arg = process.argv.indexOf('--out');
const AUS = path.join(WURZEL, arg > 0 ? process.argv[arg + 1] : 'v2');

/* Die Knoten mit eigener Datei. Bewusst eine Liste und keine abgeleitete
 * Regel: welche Seite ihre eigene Adresse verdient, ist eine redaktionelle
 * Entscheidung, keine Eigenschaft der Daten. */
const EIGENE_SEITE = [
  'home', 'administration', 'arena', 'quick-game',
  'brackets', 'm-league', 'm-elimination', 'm-classic', 'm-swiss',
  'scrambles', 'm-social-scramble',
  'queue-modes', 'm-scramble-king', 'm-kotc', 'm-doghouse', 'm-royal-duo',
  'tournament-hub', 'tournament', 'scorecards',
  'sc-classic', 'sc-scramble', 'sc-queue', 'exported',
];

/* Waehrend des Umbaus liegt v2 neben der laufenden Website. Geteiltes —
 * Bilder, Stile, Skripte — bleibt an seinem Platz und wird wurzelrelativ
 * angesprochen; das loest vor und nach dem Befoerdern gleich auf. Links
 * zwischen Guide-Seiten sind dagegen relativ, damit sie den Umzug des ganzen
 * Baums ueberstehen. */
const BASIS = '/';
const NACHBAR = '/pages/';         // index.html, downloads.html der alten Seite

/* ── Renderer laden ────────────────────────────────────────────────────── */
const ktx = vm.createContext({ console });
for (const f of ['js/guide/pages.js', 'js/guide/render.js']) {
  vm.runInContext(fs.readFileSync(path.join(WURZEL, f), 'utf8'), ktx, { filename: f });
}
const PAGES = vm.runInContext('PAGES', ktx);
const EXTERN = vm.runInContext('EXTERN', ktx);

/* Das Sprite steht in pages/guide.html. Von dort gelesen statt kopiert: eine
 * zweite Fassung wuerde auseinanderlaufen, sobald ein Symbol dazukommt.
 * Beim Befoerdern zieht es mit in den v2-Baum. */
const schale = fs.readFileSync(path.join(WURZEL, 'pages/guide.html'), 'utf8');
const spriteVon = schale.indexOf('<svg width="0" height="0"');
const SPRITE = schale.slice(spriteVon, schale.indexOf('</svg>', spriteVon) + 6);
if (spriteVon < 0) throw new Error('Kein Sprite in pages/guide.html gefunden');

/* ── Adressen ──────────────────────────────────────────────────────────── */
const datei = id => {
  const r = PAGES[id].route.replace(/^\//, '');       // "guide/modes/league"
  return r === 'guide' ? 'guide/index.html' : r + '.html';
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
  const tief = path.dirname(datei(id)).split('/').length;
  return `<!DOCTYPE html>
<!--
  Erzeugt von tools/bake-guide.mjs aus js/guide/pages.js — nicht von Hand
  aendern, der naechste Lauf ueberschreibt diese Datei. Inhalt bearbeiten:
  js/guide/pages.js, dann "node tools/bake-guide.mjs".
-->
<html lang="en" data-nav-base="${NACHBAR}" data-nav-active="guide.html">

<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${esc(s.titel)}</title>
  <meta name="description" content="${esc(description(s.lead))}">
  <!-- v2 wird neben der laufenden Website ausgeliefert. Bis zum Befoerdern
       darf sie nicht in den Index, sonst steht der halbfertige Baum als
       Doppelgaenger der echten Seiten da. Beim Befoerdern faellt die Zeile
       weg und ein canonical tritt an ihre Stelle. -->
  <meta name="robots" content="noindex">
  <link rel="icon" href="${BASIS}favicon.ico" sizes="any">
  <link rel="icon" type="image/png" sizes="32x32" href="${BASIS}assets/favicon-32.png">
  <link rel="icon" type="image/png" sizes="16x16" href="${BASIS}assets/favicon-16.png">
  <link rel="apple-touch-icon" href="${BASIS}apple-touch-icon.png">
  <link rel="manifest" href="${BASIS}site.webmanifest">
  <meta name="theme-color" content="#3A3E16">
  <link rel="stylesheet" href="${BASIS}css/style.css">
  <link rel="stylesheet" href="${BASIS}css/cards.css">
  <link rel="stylesheet" href="${BASIS}css/guide.css">
  <script src="${BASIS}js/main-nav.js" defer></script>
  <script src="${BASIS}js/i18n.js" defer></script>
</head>

<body>

${SPRITE}

  <header>
    <nav class="nav">
      <a class="logo" href="${NACHBAR}index.html">
        <img src="${BASIS}assets/brand/tournaq-logo-land-450.webp" alt="TournaQ" width="225" height="150" loading="eager" decoding="async">
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
        <p class="g-map-sub">${Object.keys(PAGES).length + Object.keys(EXTERN).length} pages</p>
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
      <a href="${NACHBAR}index.html" data-i18n="footer.home">Home</a> &nbsp;·&nbsp;
      <a href="${NACHBAR}legal.html" data-i18n="footer.legalHub">Legal Hub</a> &nbsp;·&nbsp;
      <a href="${NACHBAR}contact.html" data-i18n="footer.contact">Contact</a>
    </p>
  </footer>

<!-- Der Inhalt oben steht fertig im Dokument. Diese Angaben sagen dem Guide,
     wo er liegt und wie er verlinkt, damit ein Sprung auf einen Unterknoten
     dieselben Adressen erzeugt wie das Backskript. -->
<script>
window.__guideBaked = true;
window.__guideNode  = ${JSON.stringify(id)};
window.__guideKontext = {
  basis: ${JSON.stringify(BASIS)},
  nachbar: ${JSON.stringify(NACHBAR)},
  datei: ${JSON.stringify(Object.fromEntries(EIGENE_SEITE.map(z => [z, link(z)])))},
  link: function (id) {
    return this.datei[id] || '#/' + (id === 'home' ? '' : id);
  }
};
window.__guideKontext.link = window.__guideKontext.link.bind(window.__guideKontext);
</script>
<script src="${BASIS}js/guide/pages.js" defer></script>
<script src="${BASIS}js/guide/render.js" defer></script>
<script src="${BASIS}js/guide/boot.js" defer></script>

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
    `setzeKontext({basis: ${JSON.stringify(BASIS)},` +
    ` nachbar: ${JSON.stringify(NACHBAR)},` +
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
`;
fs.writeFileSync(path.join(WURZEL, 'js/guide/tree.js'), baum);

/* Das Sprite, damit die Karte auch auf Seiten Symbole hat, die keines
 * eingebettet haben. Aus derselben Quelle wie oben — eine zweite Fassung
 * wuerde auseinanderlaufen, sobald ein Symbol dazukommt. */
fs.writeFileSync(path.join(WURZEL, 'js/guide/sprite.js'),
  '/* Erzeugt von tools/bake-guide.mjs aus pages/guide.html — nicht von Hand. */\n' +
  'const GUIDE_SPRITE = ' + JSON.stringify(SPRITE) + ';\n');
console.log(`js/guide/tree.js: ${Object.keys(stumpf).length} Knoten, ${Math.round(baum.length / 1024)} KB`);

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
