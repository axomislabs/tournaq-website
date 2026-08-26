(function () {
  /* ══════════════════════════════════════════════════════════════════════
     Die Karte auf jeder Seite ausserhalb des Guides.

     Es ist dieselbe Karte: derselbe Baum aus js/guide/tree.js, gezeichnet
     von derselben renderNav aus js/guide/render.js, die auch der Guide
     benutzt. Loest js/feature-subnav.js und js/section-nav.js ab, die je
     einen eigenen Ausschnitt mit eigenem Renderer trugen.

     Das Aussehen kommt aus zwei Richtungen und das ist Absicht: der Kasten,
     seine Position im Raster und der Drawer aus .section-nav in
     css/style.css, die Zeilen darin aus .g-map in css/guide.css. Beide
     Regelsaetze setzen dieselben Werte fuer den Kasten, deshalb vertragen
     sich die zwei Klassen an einem Element.
     ══════════════════════════════════════════════════════════════════════ */
  var placeholder = document.getElementById('site-map')
                 || document.getElementById('feature-subnav');
  var main = placeholder ? placeholder.closest('main') : document.querySelector('main');
  if (!main) return;
  if (typeof renderNav !== 'function' || typeof NAV === 'undefined') return;

  /* Wie weit die Seite von pages/ entfernt liegt. Dieselbe Mechanik wie in
     js/main-nav.js: erst ein gesetzter Wert, sonst der Pfad. */
  var pfad = window.location.pathname;
  var basis = document.documentElement.getAttribute('data-map-base');
  if (basis === null) {
    basis = /\/(features|modes)\//.test(pfad) ? '../'
          : /\/pages\//.test(pfad) ? ''
          : 'pages/';
  }

  /* Guide-Knoten zeigen auf ihre gebackene Datei — die Zuordnung kommt aus
     tree.js, erzeugt vom selben Backskript, das die Dateien schreibt. Wer
     keine eigene Datei hat, haengt als Hash an der seines Vorfahren. Der
     Rueckfall auf die Hash-Fassung greift nur, wenn tree.js aelter ist als
     der Guide. */
  setzeKontext({
    nachbar: basis,
    link: function (id) {
      var ziel = typeof GUIDE_DATEI === 'object' && GUIDE_DATEI[id];
      return basis + (ziel || 'guide.html#/' + (id === 'home' ? '' : id));
    }
  });

  /* Welche Zeile die aktuelle Seite ist: die EXTERN-Adresse, die auf den
     Pfad passt. Ein data-map-active auf <html> geht vor — nicht das
     data-nav-active daneben: das benennt die Zeile der oberen Reihe, und die
     ist auf einer Unterseite gerade nicht dieselbe. Die Rechtsseiten sind der
     Fall: oben leuchtet "Legal", in der Karte ihr eigener Eintrag.

     Verglichen werden die letzten zwei Stuecke des Pfades. Ein fuehrendes
     ../ in der Adresse faellt vorher weg — es sagt nur, wo die Datei relativ
     zu pages/ liegt, und nicht, wie die Seite heisst. */
  function aktiv() {
    var wunsch = document.documentElement.getAttribute('data-map-active');
    var datei = (wunsch || pfad).split('/').slice(-2).join('/');
    var blatt = datei.split('/').pop();
    var treffer = null;
    Object.keys(EXTERN).forEach(function (id) {
      var url = EXTERN[id].url.replace(/^(\.\.\/)+/, '');
      if (datei === url || blatt === url) treffer = id;
      else if (url.indexOf('/') < 0 && pfad.split('/').pop() === url) treffer = treffer || id;
    });
    return treffer;
  }

  /* Symbole nachliefern, wo die Seite keines eingebettet hat. */
  if (typeof GUIDE_SPRITE === 'string' && !document.getElementById('i-map')) {
    var halter = document.createElement('div');
    halter.innerHTML = GUIDE_SPRITE;
    document.body.insertBefore(halter.firstChild, document.body.firstChild);
  }

  var AKTIV = aktiv();

  var rail = document.createElement('aside');
  rail.className = 'section-nav g-map';
  rail.id = 'site-map-rail';
  rail.setAttribute('aria-label', 'Site map');
  function zeichne() {
    rail.innerHTML =
      '<p class="g-map-h">TournaQ</p>' +
      '<p class="g-map-sub">' +
        (Object.keys(PAGES).length + Object.keys(EXTERN).length) + ' pages</p>' +
      '<nav>' + renderNav(AKTIV) + '</nav>';
  }
  zeichne();

  if (placeholder) placeholder.remove();
  main.insertBefore(rail, main.firstChild);
  main.classList.add('has-section-nav');
  document.body.classList.add('section-nav-drawer');

  /* Auf- und Zuklappen: nur die Karte neu zeichnen, damit ein offener
     Drawer offen bleibt. */
  rail.addEventListener('click', function (e) {
    var tw = e.target.closest('.g-tw');
    if (!tw) return;
    e.preventDefault();
    NAV_OPEN.has(tw.dataset.tw) ? NAV_OPEN.delete(tw.dataset.tw)
                                : NAV_OPEN.add(tw.dataset.tw);
    zeichne();
  });

  /* ── Drawer ───────────────────────────────────────────────────────────
     Die Burger-Checkbox im Kopf bleibt die einzige Wahrheit ueber "Menue
     offen", damit sie weiter zum X wird und nie zwei Navigationen zugleich
     offen stehen. Unterhalb von 900px steuert sie die Karte statt der
     Klappliste im Kopf, die css/style.css dort ausblendet. */
  var mq = window.matchMedia('(max-width: 900px)');
  var toggle = document.getElementById('nav-toggle');
  var scrim = null;
  var knopf = null;

  if (!toggle) {
    knopf = document.createElement('button');
    knopf.className = 'g-menu';
    knopf.type = 'button';
    knopf.setAttribute('aria-label', 'Open site map');
    knopf.setAttribute('aria-expanded', 'false');
    knopf.innerHTML = '<svg class="g-ic" aria-hidden="true">' +
                      '<use href="#i-menu"/></svg>Map';
    knopf.addEventListener('click', function () {
      if (rail.classList.contains('open')) schliesse(); else oeffne();
    });
    rail.insertAdjacentElement('afterend', knopf);
  }

  function oeffne() {
    rail.classList.add('open');
    if (knopf) knopf.setAttribute('aria-expanded', 'true');
    if (scrim) return;
    scrim = document.createElement('div');
    scrim.className = 'g-scrim';
    scrim.addEventListener('click', schliesse);
    document.body.appendChild(scrim);
  }

  function schliesse() {
    rail.classList.remove('open');
    if (knopf) knopf.setAttribute('aria-expanded', 'false');
    if (toggle) toggle.checked = false;
    if (scrim) { scrim.remove(); scrim = null; }
  }

  if (toggle) {
    toggle.addEventListener('change', function () {
      if (!mq.matches) return;
      if (toggle.checked) oeffne(); else schliesse();
    });
  }

  var amRand = function (e) { if (!e.matches) schliesse(); };
  if (mq.addEventListener) mq.addEventListener('change', amRand);
  else mq.addListener(amRand);

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') schliesse();
  });

  rail.addEventListener('click', function (e) {
    if (e.target.closest('a')) schliesse();
  });
})();
