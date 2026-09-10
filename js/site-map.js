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
      '<p class="g-map-sub">' + navSeitenZahl() + ' pages</p>' +
      '<nav>' + renderNav(AKTIV) + '</nav>';
    zeige();
  }
  zeichne();

  /* ── Die Abschnitte dieser Seite ──────────────────────────────────────
     Ein paar Zeilen der Karte meinen keine andere Seite, sondern eine Stelle
     in dieser: die Abschnitte von Home und Platform. Sie stehen als EXTERN
     mit einem # in der Adresse und haengen unter ihrer Seite.

     Sie navigieren nicht, sie fahren hin. Der Sprung des Browsers setzt die
     Ueberschrift an den oberen Rand, wo der klebende Kopf sie halb verdeckt
     und der Abschnitt ohne Anlauf beginnt; zentriert steht er in der Mitte
     des Bildes, mit dem, was davor kam, noch sichtbar. Deshalb auch beim
     Ankommen von einer anderen Seite: dort hat der Browser schon gesprungen,
     bevor dieses Skript laeuft. */
  var abschnitte = [];
  Object.keys(EXTERN).forEach(function (id) {
    var marke = EXTERN[id].url.split('#')[1];
    var el = marke && document.getElementById(marke);
    if (el) abschnitte.push({ marke: marke, el: el });
  });

  /* Welcher Abschnitt gerade im Bild steht — als Marke, nicht als Element:
     zeichne() baut die Zeilen jedes Mal neu, ein gemerktes <a> waere danach
     ein Fremdkoerper. */
  var HIER = null;

  function zeige() {
    rail.querySelectorAll('nav a').forEach(function (a) {
      var teil = a.href.split('#');
      if (teil.length < 2 || teil[0] !== hierher()) return;
      if (teil[1] === HIER) a.setAttribute('aria-current', 'location');
      else a.removeAttribute('aria-current');
    });
  }

  function hierher() { return location.href.split('#')[0]; }

  function merke(marke) {
    if (marke === HIER) return;
    HIER = marke;
    zeige();
  }

  function zentriere(marke, weich) {
    var el = document.getElementById(marke);
    if (!el) return false;
    /* 'instant' und nicht 'auto': 'auto' heisst laut Norm "nimm, was
       scroll-behavior sagt", und pages/index.html sagt dort smooth. Beim
       Ankommen soll nichts animiert werden — der Browser ist schon
       gesprungen, die Fahrt haette man verpasst. */
    el.scrollIntoView({ block: 'center', behavior: weich ? 'smooth' : 'instant' });
    /* Die Adresse nachfuehren, ohne den Sprung auszuloesen, den location.hash
       ausloesen wuerde. Unter file:// ist der Ursprung null und der Browser
       verweigert das — dann bleibt die Adresse eben stehen, gefahren wird
       trotzdem. Die Seiten sollen sich per Doppelklick oeffnen lassen. */
    try { history.replaceState(null, '', '#' + marke); } catch (e) {}
    merke(marke);
    return true;
  }

  /* Der Abschnitt, dessen Kopf zuletzt an der Bildmitte vorbeigezogen ist.
     Ueber der ersten Ueberschrift — im Hero — leuchtet keine Zeile, denn dort
     ist man auf der Seite und in keinem ihrer Abschnitte. */
  function spaehe() {
    var mitte = window.innerHeight / 2;
    var beste = null, oben = -Infinity;
    abschnitte.forEach(function (a) {
      var t = a.el.getBoundingClientRect().top;
      if (t <= mitte && t > oben) { oben = t; beste = a.marke; }
    });
    merke(beste);
  }

  if (placeholder) placeholder.remove();
  main.insertBefore(rail, main.firstChild);
  main.classList.add('has-section-nav');
  document.body.classList.add('section-nav-drawer');

  /* Erst jetzt spaehen: die Karte steht seit einer Zeile im Raster, und
     damit stehen auch die Abschnitte, deren Lage gemessen wird. */
  if (abschnitte.length) {
    var laeuft = false;
    window.addEventListener('scroll', function () {
      if (laeuft) return;
      laeuft = true;
      requestAnimationFrame(function () { laeuft = false; spaehe(); });
    }, { passive: true });
    window.addEventListener('hashchange', function () {
      zentriere(location.hash.slice(1), true);
    });
    /* Erst wenn die Bilder ihre Hoehe haben, steht der Abschnitt dort, wo er
       stehen bleibt — vorher zentriert man auf eine Seite, die noch waechst. */
    window.addEventListener('load', function () {
      if (location.hash.length > 1) zentriere(location.hash.slice(1), false);
      else spaehe();
    });
    spaehe();
  }

  /* Zwei Klicks fangen dieselbe Zeile ab: das Dreieck klappt sie auf und zu —
     dabei wird nur die Karte neu gezeichnet, damit ein offener Drawer offen
     bleibt —, und die Zeile eines Abschnitts dieser Seite faehrt hin, statt
     den Browser springen zu lassen. Alles andere ist ein gewoehnlicher Link
     und darf durch. */
  rail.addEventListener('click', function (e) {
    var a = e.target.closest('a');
    if (a && !e.target.closest('.g-tw') && a.href.split('#')[0] === hierher()
          && a.href.indexOf('#') > 0) {
      e.preventDefault();
      zentriere(a.href.split('#')[1], true);
      return;
    }
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
