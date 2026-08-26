/* Der Browser-Teil des User Guide — alles, was das DOM anfasst.

   Herausgeloest aus pages/guide.html. Die Seite selbst wird von
   js/guide/render.js gebaut; hier wird sie nur eingehaengt, verdrahtet und
   auf Hash-Wechsel neu gezeichnet.
*/

/* Toggling redraws only the sidebar: it must not run render(), which would
   close the mobile drawer the user is still navigating in. */
function toggleNav(id){
  NAV_OPEN.has(id) ? NAV_OPEN.delete(id) : NAV_OPEN.add(id);
  document.getElementById('g-mapnav').innerHTML = renderNav(NAV_ACTIVE);
}

/* Eine gebackene Seite sagt selbst, auf welchem Knoten sie steht — sonst
   staende die Seitenleiste beim ersten Klick auf der falschen Zeile. */
let NAV_ACTIVE = window.__guideNode || 'home';

/* Alte Hash-Routen aus der Zeit vor den Modusnamen. Beide Knoten heissen im
   Guide laengst Royal Shuffles und Royal Rotations, ihre Kennungen hiessen es
   nicht — und ein Link auf #/m-kotc waere stumm auf der Startseite gelandet.
   Statt dessen einmal auf die heutige Adresse umgeschrieben, damit auch die
   Zeile im Browser stimmt. Kann weg, sobald draussen niemand mehr so verweist. */
const ALT_ID = {'m-kotc':'m-royal-shuffle', 'm-scramble-king':'m-royal-rotation'};
const heute = raw => {
  const m = raw.match(/^(m-kotc|m-scramble-king)(-hub|-run|-score)?$/);
  return m && ALT_ID[m[1]] + (m[2] || '');
};

function render(){
  const raw = location.hash.replace(/^#\/?/, '');
  const neu = heute(raw);
  if (neu && PAGES[neu]) return location.replace(href(neu));
  const id = PAGES[raw] ? raw : 'home';

  NAV_ACTIVE = id;
  const seite = renderPage(id);

  document.getElementById('g-mapnav').innerHTML = seite.navi;
  document.getElementById('g-crumbs').innerHTML = seite.crumbs;
  document.getElementById('g-body').innerHTML   = seite.body;
  document.title = seite.titel;

  closeMap();
  if (window.__guideReady) {
    document.getElementById('g-body').focus({preventScroll:true});
    window.scrollTo(0, 0);
  }
}

/* ── Mobile map drawer ── */
const mapEl = document.getElementById('g-map');
const btn = document.getElementById('g-menu');
let scrim = null;

function closeMap(){
  mapEl.classList.remove('open');
  btn.setAttribute('aria-expanded','false');
  if (scrim){ scrim.remove(); scrim = null; }
}

btn.addEventListener('click', () => {
  const open = mapEl.classList.toggle('open');
  btn.setAttribute('aria-expanded', String(open));
  if (open){
    scrim = document.createElement('div');
    scrim.className = 'g-scrim';
    scrim.addEventListener('click', closeMap);
    document.body.appendChild(scrim);
  } else closeMap();
});

document.addEventListener('keydown', e => { if (e.key === 'Escape') closeMap(); });
document.getElementById('g-mapnav').addEventListener('click', e => {
  const tw = e.target.closest('.g-tw[data-tw]');
  if (!tw) return;
  e.preventDefault();
  e.stopPropagation();
  toggleNav(tw.dataset.tw);
});

document.getElementById('g-mapnav').addEventListener('keydown', e => {
  if (e.key !== 'Enter' && e.key !== ' ') return;
  const tw = e.target.closest('.g-tw[data-tw]');
  if (!tw) return;
  e.preventDefault();
  toggleNav(tw.dataset.tw);
});

/* Verweise aus der Einleitung auf einen Block derselben Seite. Der Hash
   gehoert dem Router, also darf ein Ankerklick ihn nicht anfassen: hier
   abgefangen, das Ziel zentriert und kurz hervorgehoben. */
document.getElementById('g-body').addEventListener('click', e => {
  const a = e.target.closest('a[data-jump]');
  if (!a) return;
  const ziel = document.getElementById(a.dataset.jump);
  if (!ziel) return;
  e.preventDefault();
  ziel.scrollIntoView({behavior:'smooth', block:'center'});
  ziel.classList.remove('g-flash');
  void ziel.offsetWidth;            /* Neustart der Animation erzwingen */
  ziel.classList.add('g-flash');
});

window.addEventListener('hashchange', render);

/* i18n.js is deferred, and it sets document.title from data-i18n-title and
   unhides the body. Rendering on DOMContentLoaded puts this after it, so the
   per-page title sticks and the guide is never painted into a hidden body. */
document.addEventListener('DOMContentLoaded', () => {
  /* Pfade und Linkform setzt die Seite selbst: die Fassung unter pages/ laesst
     die Vorgaben stehen, eine gebackene Seite reicht ihren Kontext herein. */
  if (window.__guideKontext) setzeKontext(window.__guideKontext);

  /* Counted, not typed: the label read "23 pages" long after the guide had
     grown past it. */
  document.querySelector('.g-map-sub').textContent =
    Object.keys(PAGES).length + Object.keys(EXTERN).length + ' pages';

  /* Eine gebackene Seite bringt ihren Inhalt fertig mit — neu gezeichnet wird
     nur, wenn eine Hash-Route auf einen Unterknoten zeigt. Ohne diese Bremse
     wuerde das erste Bild sofort durch ein identisches ersetzt, und wer ohne
     JavaScript liest, saehe den Unterschied nicht, wohl aber jeder andere. */
  if (!window.__guideBaked || location.hash) render();
  window.__guideReady = true;
});
