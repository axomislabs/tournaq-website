(function () {
  'use strict';
  /* ══════════════════════════════════════════════════════════════════════
     Feedback zu genau der Stelle, an der man stand.

     Die Karte links ist dieselbe wie im User Guide und auf contact.html —
     derselbe Baum aus js/guide/tree.js, dieselben Zeilen aus css/guide.css.
     Nur das Ziel einer Zeile ist ein anderes: im Guide fuehrt sie zur
     erklaerenden Seite, hier waehlt sie den Punkt aus, zu dem geschrieben
     wird. Deshalb laedt die Seite js/site-map.js nicht und setzt ihren
     eigenen Link-Kontext.

     Gespeichert wird lokal und sonst nirgends. Es gibt keinen Server: die
     App hat keine http-Abhaengigkeit, die Website ist statisch. Eine Notiz
     liegt im localStorage, ihre Bilder in IndexedDB, und beides verlaesst
     das Geraet erst, wenn jemand auf Senden drueckt.
     ══════════════════════════════════════════════════════════════════════ */

  var SP = 'tq-feedback-v1';       /* ein Schluessel, Knoten-Id als Unterschluessel */
  var DB = 'tq-feedback-shots';    /* Bilder in IndexedDB, nicht daneben            */
  var EMPFAENGER = 'team@tournaq.com';

  var ARTEN = ['bug', 'confusing', 'idea', 'praise'];

  /* ── Texte ────────────────────────────────────────────────────────────
     Der Inhalt dieser Seite entsteht erst im Browser, also erreicht ihn das
     data-i18n von js/i18n.js nicht — dessen applyTranslations() laeuft ueber
     das Dokument, lange bevor hier eine Zeile steht. Der User Guide hat
     dasselbe Problem und loest es genauso: eigene Texte, neu gezeichnet auf
     das tq-lang-Ereignis. LOCALES selbst liegt in einer IIFE und ist von
     aussen nicht lesbar. */
  var TEXTE = {
    en: {
      mapHead: 'Where were you?',
      mapSub: 'Pick the spot, then write',
      search: 'Search the app…',
      searchNone: 'Nothing matches that.',
      generalTitle: 'Somewhere else',
      generalLead: 'Something that does not belong to one screen.',
      hereLead: 'Feedback on this part of the app.',
      erkHead: 'This is what it looks like',
      erkZoom: 'Show it bigger',
      erkClose: 'Close',
      kind: 'What kind?',
      kindBug: 'Something broke',
      kindConfusing: 'This confused me',
      kindIdea: 'I have an idea',
      kindPraise: 'This works well',
      what: 'What happened?',
      whatHint: 'What did you do, what did you expect, what did you get?',
      dictate: 'Dictate',
      dictateStop: 'Stop',
      shots: 'Screenshots',
      shotsHint: 'Paste with Ctrl-V, drop a file here, or choose one.',
      shotsPick: 'Choose a file',
      add: 'Add this note',
      added: 'Added ✓',
      needText: 'Write a line first — an empty note says nothing.',
      basketTitle: 'Your notes',
      basketEmpty: 'No notes yet. Pick a spot on the left and write the first one.',
      basketCount: 'note',
      basketCountPl: 'notes',
      remove: 'Remove',
      send: 'Send by email',
      dlJson: 'Download JSON',
      dlZip: 'Download ZIP',
      clear: 'Discard all',
      clearAsk: 'Discard every note?\n\nThis cannot be undone.',
      whoTitle: 'Who are you? (optional)',
      whoName: 'Name',
      whoContact: 'Email or handle',
      whoHint: 'Only needed if you would like an answer.',
      mailNotePlain: 'The email carries the text of your notes. Use ZIP or JSON if you would rather send a file.',
      mailNoteShots: 'Your screenshots go along as a ZIP. If your device cannot hand it to your mail app directly, the ZIP is downloaded and you attach it yourself.',
      sendShots: 'Send with screenshots',
      sendZipMail: 'Download ZIP and open email',
      mailNoteZip: 'This browser cannot hand files to your mail app, so the ZIP is downloaded and you attach it yourself. On a phone it usually attaches directly.',
      zipHint: 'The ZIP with your screenshots has been downloaded.\n\nAttach it to the email that is about to open — an email link cannot carry files by itself.',
      noStore: 'This browser is not letting the page store anything, so notes will be lost on reload. Send or download them before you leave.'
    },
    de: {
      mapHead: 'Wo warst du?',
      mapSub: 'Stelle wählen, dann schreiben',
      search: 'App durchsuchen…',
      searchNone: 'Dazu passt nichts.',
      generalTitle: 'Woanders',
      generalLead: 'Etwas, das zu keinem einzelnen Bildschirm gehört.',
      hereLead: 'Rückmeldung zu diesem Teil der App.',
      erkHead: 'So sieht die Stelle aus',
      erkZoom: 'Größer zeigen',
      erkClose: 'Schließen',
      kind: 'Worum geht es?',
      kindBug: 'Etwas war kaputt',
      kindConfusing: 'Das hat mich verwirrt',
      kindIdea: 'Ich habe eine Idee',
      kindPraise: 'Das läuft gut',
      what: 'Was ist passiert?',
      whatHint: 'Was hast du getan, was hast du erwartet, was kam heraus?',
      dictate: 'Diktieren',
      dictateStop: 'Stopp',
      shots: 'Screenshots',
      shotsHint: 'Mit Strg-V einfügen, eine Datei hierher ziehen oder auswählen.',
      shotsPick: 'Datei wählen',
      add: 'Notiz hinzufügen',
      added: 'Hinzugefügt ✓',
      needText: 'Schreib erst eine Zeile — eine leere Notiz sagt nichts.',
      basketTitle: 'Deine Notizen',
      basketEmpty: 'Noch nichts. Wähle links eine Stelle und schreib die erste.',
      basketCount: 'Notiz',
      basketCountPl: 'Notizen',
      remove: 'Entfernen',
      send: 'Per E-Mail senden',
      dlJson: 'JSON laden',
      dlZip: 'ZIP laden',
      clear: 'Alles verwerfen',
      clearAsk: 'Alle Notizen verwerfen?\n\nDas lässt sich nicht rückgängig machen.',
      whoTitle: 'Wer bist du? (freiwillig)',
      whoName: 'Name',
      whoContact: 'E-Mail oder Handle',
      whoHint: 'Nur nötig, wenn du eine Antwort möchtest.',
      mailNotePlain: 'Die E-Mail trägt den Text deiner Notizen. Für eine Datei nimm ZIP oder JSON.',
      mailNoteShots: 'Deine Screenshots gehen als ZIP mit. Kann dein Gerät es nicht direkt an die Mail-App geben, wird das ZIP geladen und du hängst es selbst an.',
      sendShots: 'Mit Screenshots senden',
      sendZipMail: 'ZIP laden und Mail öffnen',
      mailNoteZip: 'Dieser Browser kann deiner Mail-App keine Dateien übergeben. Das ZIP wird geladen, anhängen musst du es selbst. Auf dem Handy geht es meist direkt.',
      zipHint: 'Das ZIP mit deinen Screenshots wurde geladen.\n\nHäng es an die E-Mail, die gleich aufgeht — ein E-Mail-Link kann selbst keine Dateien tragen.',
      noStore: 'Dieser Browser lässt die Seite nichts speichern — beim Neuladen sind die Notizen weg. Sende oder lade sie vorher herunter.'
    },
    es: {
      mapHead: '¿Dónde estabas?',
      mapSub: 'Elige el punto y escribe',
      search: 'Buscar en la app…',
      searchNone: 'No hay coincidencias.',
      generalTitle: 'En otro sitio',
      generalLead: 'Algo que no pertenece a una sola pantalla.',
      hereLead: 'Comentarios sobre esta parte de la app.',
      erkHead: 'Así se ve este sitio',
      erkZoom: 'Ver más grande',
      erkClose: 'Cerrar',
      kind: '¿De qué se trata?',
      kindBug: 'Algo falló',
      kindConfusing: 'Esto me confundió',
      kindIdea: 'Tengo una idea',
      kindPraise: 'Esto funciona bien',
      what: '¿Qué pasó?',
      whatHint: '¿Qué hiciste, qué esperabas y qué obtuviste?',
      dictate: 'Dictar',
      dictateStop: 'Parar',
      shots: 'Capturas',
      shotsHint: 'Pega con Ctrl-V, suelta un archivo aquí o elige uno.',
      shotsPick: 'Elegir archivo',
      add: 'Añadir esta nota',
      added: 'Añadida ✓',
      needText: 'Escribe una línea primero: una nota vacía no dice nada.',
      basketTitle: 'Tus notas',
      basketEmpty: 'Todavía nada. Elige un punto a la izquierda y escribe la primera.',
      basketCount: 'nota',
      basketCountPl: 'notas',
      remove: 'Quitar',
      send: 'Enviar por correo',
      dlJson: 'Descargar JSON',
      dlZip: 'Descargar ZIP',
      clear: 'Descartar todo',
      clearAsk: '¿Descartar todas las notas?\n\nEsto no se puede deshacer.',
      whoTitle: '¿Quién eres? (opcional)',
      whoName: 'Nombre',
      whoContact: 'Correo o usuario',
      whoHint: 'Solo hace falta si quieres respuesta.',
      mailNotePlain: 'El correo lleva el texto de tus notas. Para enviar un archivo, usa ZIP o JSON.',
      mailNoteShots: 'Tus capturas van en un ZIP. Si tu dispositivo no puede entregarlo directamente a tu aplicación de correo, el ZIP se descarga y lo adjuntas tú.',
      sendShots: 'Enviar con capturas',
      sendZipMail: 'Descargar ZIP y abrir correo',
      mailNoteZip: 'Este navegador no puede entregar archivos a tu aplicación de correo, así que el ZIP se descarga y lo adjuntas tú. En el móvil suele adjuntarse directamente.',
      zipHint: 'El ZIP con tus capturas se ha descargado.\n\nAdjúntalo al correo que está a punto de abrirse: un enlace de correo no puede llevar archivos por sí solo.',
      noStore: 'Este navegador no deja guardar nada, así que las notas se perderán al recargar. Envíalas o descárgalas antes de salir.'
    }
  };

  function sprache() {
    var l = document.documentElement.lang || 'en';
    return TEXTE[l] ? l : 'en';
  }
  function t(k) {
    var s = TEXTE[sprache()];
    return (s && s[k] != null) ? s[k] : TEXTE.en[k];
  }

  /* ── Zustand ──────────────────────────────────────────────────────────
     Jeder Zugriff gekapselt: im privaten Fenster und bei blockierten
     Site-Daten wirft localStorage, statt nur leer zu sein. Die Seite muss
     dann trotzdem benutzbar bleiben — nur eben ohne Gedaechtnis. */
  var daten = { meta: {}, notes: {} };
  var speicherGeht = true;
  try {
    var roh = JSON.parse(localStorage.getItem(SP) || 'null');
    if (roh && typeof roh === 'object') {
      daten.meta = roh.meta || {};
      daten.notes = roh.notes || {};
    }
  } catch (e) { speicherGeht = false; }

  function sichern() {
    try { localStorage.setItem(SP, JSON.stringify(daten)); }
    catch (e) { speicherGeht = false; }
  }

  function jetzt() { return new Date().toISOString(); }
  function heute() { return new Date().toISOString().slice(0, 10); }
  function neueId() {
    return 'n_' + Date.now().toString(36) + '_' + Math.random().toString(36).slice(2, 7);
  }
  function alleNotizen() {
    var aus = [];
    Object.keys(daten.notes).forEach(function (id) {
      (daten.notes[id] || []).forEach(function (n) { aus.push({ node: id, n: n }); });
    });
    return aus.sort(function (a, b) { return a.n.ts < b.n.ts ? -1 : 1; });
  }

  /* ── Bilder: IndexedDB ────────────────────────────────────────────────
     Dasselbe Muster wie im PQ-Protokoll: localStorage waere nach drei
     Handy-Screenshots voll, hier liegen die Blobs und dort nur ihre Ids. */
  var dbP = null;
  function db() {
    if (dbP) return dbP;
    dbP = new Promise(function (ok, weg) {
      var a = indexedDB.open(DB, 1);
      a.onupgradeneeded = function () {
        var d = a.result;
        if (!d.objectStoreNames.contains('shots')) d.createObjectStore('shots', { keyPath: 'id' });
      };
      a.onsuccess = function () { ok(a.result); };
      a.onerror = function () { weg(a.error); };
    });
    return dbP;
  }
  function dbTun(modus, arbeit) {
    return db().then(function (d) {
      return new Promise(function (ok, weg) {
        var tr = d.transaction('shots', modus);
        var s = tr.objectStore('shots');
        var r = arbeit(s);
        tr.oncomplete = function () {
          ok(r && typeof IDBRequest !== 'undefined' && r instanceof IDBRequest ? r.result : undefined);
        };
        tr.onerror = function () { weg(tr.error); };
      });
    });
  }
  function bildSpeichern(blob) {
    var id = 'sh_' + Date.now().toString(36) + '_' + Math.random().toString(36).slice(2, 8);
    return dbTun('readwrite', function (s) {
      s.put({ id: id, blob: blob, ts: jetzt(), type: blob.type || 'image/png' });
    }).then(function () { return id; });
  }
  function bildLesen(id) {
    return dbTun('readonly', function (s) { return s.get(id); });
  }
  function bildLoeschen(id) {
    return dbTun('readwrite', function (s) { s.delete(id); });
  }

  /* ── Der Baum ─────────────────────────────────────────────────────────
     NAV traegt die Zeilen der Karte als flache [id, tiefe]-Liste, und darin
     stehen Website-Seiten und App-Knoten gemischt. Hier zaehlen nur die
     App-Knoten: eine Rueckmeldung gilt einer Stelle in der App, nicht der
     Downloads-Seite. Gefiltert wird ueber PAGES, weil genau das der
     Unterschied zwischen den beiden Sorten ist.

     navFlat() kommt aus js/guide/render.js und traegt die kuratierte
     Reihenfolge samt Tiefen. Die selbst aus `parent` abzuleiten waere ein
     zweiter Baum neben dem gepflegten.

     Die gespiegelten Zeilen fallen mit heraus. Seit die Karte der Website
     diesen Baum ein zweites Mal unter "Share Feedback" fuehrt — als Weg
     hierher —, steht jeder Knoten zweimal in NAV. Hier ist er einmal gemeint:
     das hier *ist* die Feedback-Seite, sie braucht keinen Weg zu sich selbst. */
  function knoten() {
    if (typeof navFlat !== 'function' || typeof PAGES === 'undefined') return [];
    return navFlat().filter(function (n) {
      return !!PAGES[n.id] && !navGespiegelt(n.key);
    });
  }

  /* 'home' heisst im Guide "TournaQ User Guide". Als Ziel einer Rueckmeldung
     waere das irrefuehrend — dort landet, was zu keinem Bildschirm gehoert. */
  function titel(id) {
    if (id === 'home') return t('generalTitle');
    return (PAGES[id] && PAGES[id].title) || id;
  }
  function symbol(id) {
    if (id === 'home') return 'i-map';
    return (PAGES[id] && PAGES[id].icon) || 'i-doc';
  }
  function pfad(id) {
    var kette = [], cur = id;
    while (cur && PAGES[cur]) { kette.unshift(cur); cur = PAGES[cur].parent; }
    return kette;
  }
  function zahlFuer(id) { return (daten.notes[id] || []).length; }

  /* Was unter einer zugeklappten Zeile liegt, zaehlt zu ihr. Sonst ist eine
     Notiz, die drei Ebenen tief haengt, schlicht unsichtbar, bis jemand den
     Zweig aufklappt — und niemand klappt einen Zweig auf, der leer aussieht.

     Gezaehlt wird ueber die Knoten, nicht ueber die Zeilen: 'queue-modes'
     steht zweimal in NAV, einmal unter jeder Familie, und beide Vorkommen
     liegen unter 'arena'. Ueber Zeilen summiert waere es dort doppelt. */
  function summeAb(flach, i) {
    var n = flach[i];
    var ids = {};
    ids[n.id] = 1;
    for (var j = i + 1; j < flach.length && flach[j].depth > n.depth; j++) {
      ids[flach[j].id] = 1;
    }
    return Object.keys(ids).reduce(function (s, id) { return s + zahlFuer(id); }, 0);
  }

  /* ── Suche ────────────────────────────────────────────────────────────── */
  var SUCHE = '';
  function passt(id) {
    if (!SUCHE) return true;
    var q = SUCHE.toLowerCase();
    return pfad(id).some(function (k) {
      return titel(k).toLowerCase().indexOf(q) >= 0;
    });
  }

  /* ── Die Karte ────────────────────────────────────────────────────────
     Eigene Zeichenroutine statt renderNav(): renderNav zeichnet auch die
     site-*-Zeilen und verlinkt ueber navZiel() nach aussen. Die Klassen
     sind dieselben, also sieht die Karte aus wie ueberall sonst.

     Bei aktiver Suche faellt das Zuklappen weg — wer sucht, will Treffer
     sehen und nicht erst Zweige oeffnen. */
  function zeichneRail() {
    var flach = knoten();
    var aus = '';
    var gefaltetAb = null;

    flach.forEach(function (n, i) {
      if (SUCHE) { if (!passt(n.id)) return; }
      else {
        if (gefaltetAb !== null) {
          if (n.depth > gefaltetAb) return;
          gefaltetAb = null;
        }
      }
      var kinder = i + 1 < flach.length && flach[i + 1].depth > n.depth;
      var offen = NAV_OPEN.has(n.key) || !!SUCHE;
      if (!SUCHE && kinder && !offen) gefaltetAb = n.depth;

      var sub = n.depth ? 'sub' + (n.depth > 1 ? n.depth : '') : '';
      var cur = n.id === AKTIV ? ' aria-current="page"' : '';
      var tw = kinder && !SUCHE
        ? '<span class="g-tw' + (offen ? ' open' : '') + '" data-tw="' + n.key +
          '" role="button" tabindex="0" aria-expanded="' + offen + '">' +
          ic('i-south', 'g-twi') + '</span>'
        : '<span class="g-tw empty"></span>';
      /* Zugeklappt steht die Summe des Zweigs, aufgeklappt die eigene Zahl —
         sonst zaehlte der Elternteil neben seinen sichtbaren Kindern ein
         zweites Mal dasselbe. */
      var gefaltet = kinder && !offen;
      var z = gefaltet ? summeAb(flach, i) : zahlFuer(n.id);
      var marke = z
        ? '<span class="fb-count' + (gefaltet ? ' summe' : '') + '">' + z + '</span>'
        : '';

      aus += '<a class="' + sub + '" href="#/' + n.id + '"' + cur + '>' +
        tw + ic(symbol(n.id)) + '<span>' + titel(n.id) + '</span>' + marke + '</a>';
    });

    if (!aus) aus = '<p class="fb-none">' + t('searchNone') + '</p>';
    return aus;
  }

  /* ── Aufbau der Seite ─────────────────────────────────────────────────── */
  var main = document.querySelector('main');
  if (!main) return;
  if (typeof PAGES === 'undefined' || typeof ic !== 'function') return;

  /* Symbole nachliefern, wie js/site-map.js es tut. */
  if (typeof GUIDE_SPRITE === 'string' && !document.getElementById('i-map')) {
    var halter = document.createElement('div');
    halter.innerHTML = GUIDE_SPRITE;
    document.body.insertBefore(halter.firstChild, document.body.firstChild);
  }

  /* Die Zeilen der Karte zeigen auf diese Seite. Ohne das griffe G_LINK und
     jede Zeile fuehrte in den Guide — der Kontext gilt global im Renderer,
     also wird er hier einmal gesetzt und nicht mehr angefasst. */
  if (typeof setzeKontext === 'function') {
    setzeKontext({ basis: '../', nachbar: '', link: function (id) { return '#/' + id; } });
  }

  var AKTIV = 'home';

  var rail = document.createElement('aside');
  rail.className = 'section-nav g-map fb-map';
  rail.id = 'fb-map';
  rail.setAttribute('aria-label', 'App structure');

  var knotenKasten = document.getElementById('fb-node');
  var korbKasten = document.getElementById('fb-basket');

  function zeichneKarte() {
    rail.innerHTML =
      '<p class="g-map-h">' + t('mapHead') + '</p>' +
      '<p class="g-map-sub">' + t('mapSub') + '</p>' +
      '<input type="search" class="fb-search" id="fb-search" placeholder="' +
        t('search') + '" value="' + SUCHE.replace(/"/g, '&quot;') + '" ' +
        'aria-label="' + t('search') + '">' +
      '<nav>' + zeichneRail() + '</nav>';
  }

  /* ── Erkennungsbilder ─────────────────────────────────────────────────
     Eine Stelle in der App traegt hier ihren Namen, und ein Name ist wenig,
     wenn man drei Wochen spaeter aufschreiben will, wo etwas schieflief. Die
     Aufnahmen daneben sind dieselben, die der User Guide unter seinen
     Bildunterschriften zeigt und pages/index.html in seinen Abschnitten —
     wiedererkannt wird an ihnen, nicht an "Running a Royal Shuffle".

     js/guide/shots.js haelt sie, gebacken aus derselben Quelle wie der Guide.
     Fehlt die Datei, faellt der Streifen weg und die Seite arbeitet wie
     vorher: Bilder sind hier eine Hilfe, keine Bedingung.

     'home' hat keine und bekommt keine — dort landet, was zu keinem
     Bildschirm gehoert, und ein Bild daneben behauptete das Gegenteil. */
  function erkBilder(id) {
    if (typeof GUIDE_SHOT === 'undefined' || !GUIDE_SHOT) return [];
    return GUIDE_SHOT[id] || [];
  }

  /* Die Beschreibung einer Aufnahme in der Sprache der Seite. js/guide/shots.js
     traegt sie in allen dreien, weil die Feedback-Seite js/guide/locales.js
     nicht laedt — dort stehen die Uebersetzungen des Guides, 750 KB fuer eine
     Handvoll Saetze. Fehlt eine, bleibt der englische Satz stehen. */
  function beschreibung(sh) {
    return sh[sprache()] || sh.alt || '';
  }

  function esc(x) {
    return String(x == null ? '' : x)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;')
      .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  /* Dasselbe srcset wie im Guide: `src` ohne Groessensuffix, `sizes` die
     Breiten, die auf der Platte liegen. In der Kachel steckt die kleinste,
     im grossen Bild entscheidet der Browser.

     `alt` steht als Argument, weil die Kachel keines traegt: dort ist das
     Bild der Inhalt eines Knopfes, und dessen aria-label beschreibt beides
     zugleich — was zu sehen ist und was ein Klick tut. Zwei Beschreibungen
     uebereinander liest eine Sprachausgabe entweder doppelt oder gar nicht. */
  function bildTag(sh, gross, alt) {
    var basis = '../assets/' + sh.src;
    var srcset = sh.sizes.map(function (w) {
      return basis + '-' + w + '.webp ' + w + 'w';
    }).join(', ');
    return '<img src="' + basis + '-' + sh.sizes[0] + '.webp" srcset="' + srcset + '" ' +
      'sizes="' + (gross ? '(max-width: 560px) 84vw, 380px'
                          : '(max-width: 760px) 88px, 116px') + '" ' +
      'width="' + sh.w + '" height="' + sh.h + '" ' +
      'loading="' + (gross ? 'eager' : 'lazy') + '" decoding="async" ' +
      'alt="' + esc(alt == null ? beschreibung(sh) : alt) + '">';
  }

  function zeichneErk(id) {
    var alle = erkBilder(id);
    if (!alle.length) return '';
    return '<div class="fb-erk">' +
      '<p class="fb-erk-h">' + t('erkHead') + '</p>' +
      '<div class="fb-erk-reihe">' +
        alle.map(function (sh, i) {
          return '<button type="button" class="fb-erk-kachel" data-erk="' + i + '" ' +
            'title="' + esc(t('erkZoom')) + '" ' +
            'aria-label="' + esc(beschreibung(sh) + ' — ' + t('erkZoom')) + '">' +
            bildTag(sh, false, '') + '</button>';
        }).join('') +
      '</div></div>';
  }

  /* Die Kachel ist gut hundert Pixel breit — genug, um einen Schirm
     wiederzuerkennen, zu wenig, um etwas darauf zu lesen. Ein Klick legt die
     Aufnahme gross darueber; die langen "_full"-Aufnahmen laufen darin nicht
     ins Briefmarkenformat, sondern bleiben lesbar breit und werden
     gescrollt. */
  var LICHT = null;
  var LICHT_HER = null;          /* die Kachel, von der aus geoeffnet wurde */
  function schliesseLicht() {
    if (!LICHT) return;
    LICHT.remove();
    LICHT = null;
    /* Zurueck auf die Kachel: wer mit der Tastatur hierher kam, stuende
       sonst nach dem Schliessen wieder ganz oben am Seitenanfang. */
    if (LICHT_HER && document.contains(LICHT_HER)) LICHT_HER.focus();
    LICHT_HER = null;
  }
  function zeigeGross(sh, her) {
    if (!sh) return;
    schliesseLicht();
    LICHT_HER = her || null;
    LICHT = document.createElement('div');
    LICHT.className = 'fb-licht';
    LICHT.innerHTML =
      '<div class="fb-licht-rahmen" role="dialog" aria-modal="true" aria-label="' +
        esc(beschreibung(sh)) + '">' + bildTag(sh, true) +
        '<button type="button" class="fb-licht-x" aria-label="' + esc(t('erkClose')) +
          '" title="' + esc(t('erkClose')) + '">\u00d7</button>' +
      '</div>';
    LICHT.addEventListener('click', schliesseLicht);
    document.body.appendChild(LICHT);
    var x = LICHT.querySelector('.fb-licht-x');
    if (x) x.focus();
  }

  /* ── Das Formular zum aktiven Knoten ──────────────────────────────────── */
  var ENTWURF = { kind: '', text: '', shots: [] };

  function zeichneKnoten() {
    var kette = pfad(AKTIV);
    var krumen = kette.map(function (k, i) {
      return i === kette.length - 1
        ? '<span class="now">' + titel(k) + '</span>'
        : '<a href="#/' + k + '">' + titel(k) + '</a><span class="sep">/</span>';
    }).join('');

    var chips = ARTEN.map(function (a) {
      var label = t('kind' + a.charAt(0).toUpperCase() + a.slice(1));
      return '<button type="button" class="fb-chip' +
        (ENTWURF.kind === a ? ' on' : '') + '" data-kind="' + a + '" ' +
        'aria-pressed="' + (ENTWURF.kind === a ? 'true' : 'false') + '">' + label + '</button>';
    }).join('');

    knotenKasten.innerHTML =
      '<section class="card fb-node">' +
        '<div class="fb-crumbs">' + krumen + '</div>' +
        '<h2 class="fb-node-h">' + ic(symbol(AKTIV), 'g-ic fb-node-ic') +
          '<span>' + titel(AKTIV) + '</span></h2>' +
        '<p class="fb-lead">' + (AKTIV === 'home' ? t('generalLead') : t('hereLead')) + '</p>' +

        zeichneErk(AKTIV) +

        '<div class="fb-field"><label class="fb-label">' + t('kind') + '</label>' +
          '<div class="fb-chips">' + chips + '</div></div>' +

        '<div class="fb-field">' +
          '<label class="fb-label" for="fb-text">' + t('what') + '</label>' +
          '<div class="fb-textwrap">' +
            '<textarea id="fb-text" class="fb-text" rows="5" placeholder="' +
              t('whatHint') + '">' + ENTWURF.text.replace(/</g, '&lt;') + '</textarea>' +
            '<button type="button" class="fb-mic" id="fb-mic" aria-label="' +
              t('dictate') + '" title="' + t('dictate') + '">🎤</button>' +
          '</div></div>' +

        '<div class="fb-field">' +
          '<label class="fb-label">' + t('shots') + '</label>' +
          '<div class="fb-drop" id="fb-drop" tabindex="0">' +
            '<p class="fb-drop-hint">' + t('shotsHint') + '</p>' +
            '<div class="fb-shots" id="fb-shots"></div>' +
            '<button type="button" class="button ghost fb-pick" id="fb-pick">' +
              t('shotsPick') + '</button>' +
          '</div></div>' +

        '<div class="card-actions">' +
          '<button type="button" class="button" id="fb-add">' + t('add') + '</button>' +
        '</div>' +
      '</section>';

    zeichneEntwurfBilder();
  }

  function zeichneEntwurfBilder() {
    var kasten = document.getElementById('fb-shots');
    if (!kasten) return;
    kasten.innerHTML = '';
    ENTWURF.shots.forEach(function (sid) {
      var kachel = document.createElement('span');
      kachel.className = 'fb-shot';
      kasten.appendChild(kachel);
      bildLesen(sid).then(function (r) {
        if (!r || !r.blob) { kachel.classList.add('fehlt'); return; }
        var img = document.createElement('img');
        img.src = URL.createObjectURL(r.blob);
        img.alt = '';
        kachel.appendChild(img);
        var weg = document.createElement('button');
        weg.type = 'button';
        weg.className = 'fb-shot-x';
        weg.textContent = '×';
        weg.setAttribute('aria-label', t('remove'));
        weg.addEventListener('click', function () {
          ENTWURF.shots = ENTWURF.shots.filter(function (x) { return x !== sid; });
          bildLoeschen(sid);
          zeichneEntwurfBilder();
        });
        kachel.appendChild(weg);
      }).catch(function () { kachel.classList.add('fehlt'); });
    });
  }

  /* ── Der Korb ─────────────────────────────────────────────────────────── */
  function zeichneKorb() {
    var alle = alleNotizen();
    var kopf = '<h2>' + t('basketTitle') +
      (alle.length ? ' <span class="fb-total">' + alle.length + ' ' +
        (alle.length === 1 ? t('basketCount') : t('basketCountPl')) + '</span>' : '') +
      '</h2>';

    if (!alle.length) {
      korbKasten.innerHTML = kopf + '<p class="fb-empty">' + t('basketEmpty') + '</p>' + werBinIch();
      verdrahteWer();
      return;
    }

    var liste = alle.map(function (e) {
      var kindLabel = e.n.kind
        ? t('kind' + e.n.kind.charAt(0).toUpperCase() + e.n.kind.slice(1))
        : '';
      return '<li class="fb-item" data-node="' + e.node + '" data-id="' + e.n.id + '">' +
        '<div class="fb-item-head">' +
          '<a class="fb-item-where" href="#/' + e.node + '">' +
            ic(symbol(e.node), 'g-ic') + titel(e.node) + '</a>' +
          (kindLabel ? '<span class="fb-item-kind k-' + e.n.kind + '">' + kindLabel + '</span>' : '') +
          '<button type="button" class="fb-item-x" aria-label="' + t('remove') + '">×</button>' +
        '</div>' +
        '<p class="fb-item-text"></p>' +
        ((e.n.shots || []).length
          ? '<p class="fb-item-shots">' + (e.n.shots.length) + ' ×</p>' : '') +
      '</li>';
    }).join('');

    korbKasten.innerHTML = kopf +
      '<ul class="fb-list">' + liste + '</ul>' +
      werBinIch() +
      '<p class="fb-mailnote">' + t(!zahlBilder() ? 'mailNotePlain'
            : kannTeilen() ? 'mailNoteShots' : 'mailNoteZip') + '</p>' +
      '<div class="card-actions fb-actions">' +
        '<button type="button" class="button" id="fb-send">' +
          t(!zahlBilder() ? 'send'
            : kannTeilen() ? 'sendShots' : 'sendZipMail') + '</button>' +
        '<button type="button" class="button ghost" id="fb-zip">' + t('dlZip') + '</button>' +
        '<button type="button" class="button ghost" id="fb-json">' + t('dlJson') + '</button>' +
        '<button type="button" class="button ghost fb-danger" id="fb-clear">' + t('clear') + '</button>' +
      '</div>';

    /* Der Text als textContent, nicht als HTML: er kommt von der Tastatur und
       darf die Seite nicht mitgestalten. */
    alle.forEach(function (e) {
      var li = korbKasten.querySelector('[data-id="' + e.n.id + '"] .fb-item-text');
      if (li) li.textContent = e.n.text;
    });

    verdrahteWer();
    korbKasten.querySelectorAll('.fb-item-x').forEach(function (b) {
      b.addEventListener('click', function () {
        var li = b.closest('.fb-item');
        loesche(li.dataset.node, li.dataset.id);
      });
    });
    document.getElementById('fb-send').addEventListener('click', sende);
    document.getElementById('fb-zip').addEventListener('click', function () {
      alsZip().catch(function (err) { alert('ZIP failed: ' + err); });
    });
    document.getElementById('fb-json').addEventListener('click', function () {
      lade(new Blob([JSON.stringify(daten, null, 2)], { type: 'application/json' }),
           'tournaq-feedback-' + heute() + '.json');
    });
    bereiteZipVor();
    document.getElementById('fb-clear').addEventListener('click', function () {
      if (!confirm(t('clearAsk'))) return;
      alleNotizen().forEach(function (e) {
        (e.n.shots || []).forEach(bildLoeschen);
      });
      daten.notes = {};
      sichern();
      zeichneAlles();
    });
  }

  function werBinIch() {
    var m = daten.meta || {};
    return '<div class="fb-who">' +
      '<label class="fb-label">' + t('whoTitle') + '</label>' +
      '<div class="fb-who-row">' +
        '<input type="text" id="fb-who-name" placeholder="' + t('whoName') +
          '" value="' + (m.name || '').replace(/"/g, '&quot;') + '">' +
        '<input type="text" id="fb-who-contact" placeholder="' + t('whoContact') +
          '" value="' + (m.contact || '').replace(/"/g, '&quot;') + '">' +
      '</div>' +
      '<p class="fb-hint">' + t('whoHint') + '</p>' +
    '</div>';
  }
  function verdrahteWer() {
    ['name', 'contact'].forEach(function (feld) {
      var el = document.getElementById('fb-who-' + feld);
      if (!el) return;
      el.addEventListener('input', function () {
        daten.meta[feld] = el.value;
        sichern();
      });
    });
  }

  function loesche(node, id) {
    var liste = daten.notes[node] || [];
    var weg = liste.filter(function (n) { return n.id === id; })[0];
    if (weg) (weg.shots || []).forEach(bildLoeschen);
    daten.notes[node] = liste.filter(function (n) { return n.id !== id; });
    if (!daten.notes[node].length) delete daten.notes[node];
    sichern();
    zeichneAlles();
  }

  /* ── Export ───────────────────────────────────────────────────────────── */
  function lade(blob, name) {
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = name;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(function () { URL.revokeObjectURL(a.href); }, 1000);
  }

  function alsText() {
    var m = daten.meta || {};
    var aus = ['TournaQ feedback — ' + heute()];
    if (m.name || m.contact) aus.push('From: ' + [m.name, m.contact].filter(Boolean).join(' · '));
    aus.push('');
    alleNotizen().forEach(function (e, i) {
      aus.push((i + 1) + '. ' + pfad(e.node).map(titel).join(' › '));
      if (e.n.kind) aus.push('   [' + e.n.kind + ']');
      aus.push('   ' + e.n.text.replace(/\n/g, '\n   '));
      if ((e.n.shots || []).length) aus.push('   (' + e.n.shots.length + ' screenshot(s) — in the ZIP)');
      aus.push('');
    });
    return aus.join('\n');
  }

  /* ZIP ohne Kompression (Methode 0), von Hand geschrieben — dieselbe Routine
     wie im PQ-Protokoll. Eine Bibliothek waere ein CDN-Abruf, und die Seite
     soll auch ohne Netz und von file:// aus funktionieren. */
  var CRC = (function () {
    var tab = new Uint32Array(256);
    for (var n = 0; n < 256; n++) {
      var c = n;
      for (var k = 0; k < 8; k++) c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
      tab[n] = c >>> 0;
    }
    return tab;
  })();
  function crc32(u8) {
    var c = 0xFFFFFFFF;
    for (var i = 0; i < u8.length; i++) c = CRC[(c ^ u8[i]) & 0xFF] ^ (c >>> 8);
    return (c ^ 0xFFFFFFFF) >>> 0;
  }
  function zip(dateien) {
    var teile = [], zentral = [], versatz = 0;
    var enc = new TextEncoder();
    function u32(v) { return [v & 255, (v >>> 8) & 255, (v >>> 16) & 255, (v >>> 24) & 255]; }
    function u16(v) { return [v & 255, (v >>> 8) & 255]; }
    var d = new Date();
    var dosZeit = (d.getHours() << 11) | (d.getMinutes() << 5) | (d.getSeconds() >> 1);
    var dosDatum = ((d.getFullYear() - 1980) << 9) | ((d.getMonth() + 1) << 5) | d.getDate();
    var fahne = 0x0800;                     /* Bit 11: der Name ist UTF-8 */

    dateien.forEach(function (f) {
      var name = enc.encode(f.name);
      var pruef = crc32(f.data);
      var kopf = [].concat([0x50, 0x4B, 0x03, 0x04], u16(20), u16(fahne), u16(0),
                           u16(dosZeit), u16(dosDatum),
                           u32(pruef), u32(f.data.length), u32(f.data.length),
                           u16(name.length), u16(0));
      teile.push(new Uint8Array(kopf), name, f.data);
      zentral.push({ name: name, crc: pruef, len: f.data.length, off: versatz });
      versatz += kopf.length + name.length + f.data.length;
    });

    var zStart = versatz, zLen = 0;
    zentral.forEach(function (z) {
      var kopf = [].concat([0x50, 0x4B, 0x01, 0x02], u16(20), u16(20), u16(fahne),
                           u16(0), u16(dosZeit), u16(dosDatum),
                           u32(z.crc), u32(z.len), u32(z.len), u16(z.name.length),
                           u16(0), u16(0), u16(0), u16(0), u32(0), u32(z.off));
      teile.push(new Uint8Array(kopf), z.name);
      zLen += kopf.length + z.name.length;
    });
    teile.push(new Uint8Array([].concat([0x50, 0x4B, 0x05, 0x06], u16(0), u16(0),
                                        u16(zentral.length), u16(zentral.length),
                                        u32(zLen), u32(zStart), u16(0))));
    return new Blob(teile, { type: 'application/zip' });
  }

  /* Ein Lesevorgang, der nicht antwortet, darf den Versand nicht aufhalten.
     IndexedDB kann blockieren — ein anderer Tab haelt eine Transaktion, die
     Site-Daten sind halb geloescht, das private Fenster gibt keinen Speicher
     her. Ohne Frist haengt Promise.all ewig, der Knopf tut nichts, und
     niemand erfaehrt warum. Lieber ein ZIP ohne ein Bild als keines. */
  function mitFrist(p, ms) {
    return new Promise(function (ok) {
      var fertig = false;
      var uhr = setTimeout(function () {
        if (!fertig) { fertig = true; ok(null); }
      }, ms);
      p.then(
        function (v) { if (!fertig) { fertig = true; clearTimeout(uhr); ok(v); } },
        function () { if (!fertig) { fertig = true; clearTimeout(uhr); ok(null); } }
      );
    });
  }

  function baueZip() {
    var enc = new TextEncoder();
    var fehlend = 0;
    var dateien = [
      { name: 'feedback.txt', data: enc.encode(alsText()) },
      { name: 'feedback.json', data: enc.encode(JSON.stringify(daten, null, 2)) }
    ];
    var warten = [];
    alleNotizen().forEach(function (e) {
      (e.n.shots || []).forEach(function (sid, i) {
        warten.push(mitFrist(bildLesen(sid), 5000).then(function (r) {
          if (!r || !r.blob) { fehlend++; return; }
          return r.blob.arrayBuffer().then(function (buf) {
            var endung = (r.type || 'image/png').split('/')[1].split('+')[0];
            dateien.push({
              name: 'screenshots/' + e.node.replace(/[^\w.-]/g, '_') + '__' +
                    e.n.id + '_' + (i + 1) + '.' + endung,
              data: new Uint8Array(buf)
            });
          });
        }));
      });
    });
    return Promise.all(warten).then(function () {
      /* Ein stilles Loch im Archiv waere schlimmer als ein benanntes: der
         Text nennt drei Screenshots, im ZIP liegen zwei, und der Empfaenger
         sucht den dritten. */
      if (fehlend) {
        dateien[0] = {
          name: 'feedback.txt',
          data: enc.encode(alsText() + '\n[' + fehlend +
            ' screenshot(s) could not be read from this browser and are missing here.]\n')
        };
      }
      return zip(dateien);
    });
  }

  function zipName() { return 'tournaq-feedback-' + heute() + '.zip'; }

  function alsZip() {
    return baueZip().then(function (blob) { lade(blob, zipName()); });
  }

  /* ── Versand ──────────────────────────────────────────────────────────
     Eine mailto-Adresse kann keine Datei tragen. Das ist keine Luecke dieser
     Seite, sondern in RFC 6068 so festgelegt und von jedem Browser
     blockiert — sonst koennte eine Seite ungefragt Dateien verschicken.

     Wer Screenshots gesammelt hat, braucht deshalb einen anderen Weg. Die
     Web Share API hat ihn: sie reicht echte Dateien an die App weiter, die
     der Nutzer waehlt, und auf dem Telefon ist das genau die Mail-App. Wo
     es sie nicht gibt, bleibt der ehrliche zweite Weg — das ZIP liegt im
     Download-Ordner, die Mail steht offen, anhaengen muss man selbst. */

  /* Ob dieser Browser ueberhaupt Dateien weiterreichen kann. Gefragt wird mit
     einer Probe-Datei, nicht nur nach navigator.share: Chrome am Schreibtisch
     hat share(), lehnt aber files ab, und ein Knopf, der "mit Screenshots
     senden" verspricht und dann nur etwas herunterlaedt, ist eine Luege.

     Das Ergebnis haengt am Browser, nicht am Zustand der Seite, also wird es
     einmal ermittelt und behalten. */
  var TEILEN = null;
  function kannTeilen() {
    if (TEILEN !== null) return TEILEN;
    TEILEN = false;
    try {
      if (navigator.canShare && typeof File === 'function') {
        var probe = new File([new Blob([new Uint8Array([80, 75])], { type: 'application/zip' })],
                             'probe.zip', { type: 'application/zip' });
        TEILEN = !!navigator.canShare({ files: [probe] });
      }
    } catch (e) { TEILEN = false; }
    return TEILEN;
  }

  function zahlBilder() {
    return alleNotizen().reduce(function (n, e) { return n + (e.n.shots || []).length; }, 0);
  }

  /* Das ZIP wird im Voraus gebaut. navigator.share() verlangt eine frische
     Nutzergeste, und die ist abgelaufen, bis IndexedDB gelesen und das
     Archiv geschrieben ist — auf iOS zuverlaessig. Liegt es beim Klick
     bereit, ist der Aufruf synchron und die Geste gilt noch. */
  var ZIP_BEREIT = null;

  function zipMarke() {
    return alleNotizen().map(function (e) {
      return e.n.id + ':' + (e.n.shots || []).length;
    }).join('|');
  }

  function bereiteZipVor() {
    var marke = zipMarke();
    if (ZIP_BEREIT && ZIP_BEREIT.marke === marke) return;
    ZIP_BEREIT = null;
    if (!zahlBilder()) return;
    baueZip().then(function (blob) {
      ZIP_BEREIT = { blob: blob, marke: marke };
    }).catch(function () { /* dann eben beim Klick */ });
  }

  function oeffneMail(betreff, koerper) {
    location.href = 'mailto:' + EMPFAENGER +
      '?subject=' + encodeURIComponent(betreff) +
      '&body=' + encodeURIComponent(koerper);
  }

  function zipUndMail(betreff, koerper) {
    var weiter = function (blob) {
      if (blob) lade(blob, zipName());
      /* Der Hinweis haelt kurz an, bevor der Mail-Client aufgeht: danach
         liegt das Fenster der Seite im Hintergrund und niemand liest ihn. */
      alert(t('zipHint'));
      oeffneMail(betreff, koerper);
    };
    if (ZIP_BEREIT && ZIP_BEREIT.marke === zipMarke()) { weiter(ZIP_BEREIT.blob); return; }
    baueZip().then(weiter).catch(function () { weiter(null); });
  }

  function sende() {
    var koerper = alsText();
    if (koerper.length > 1800) koerper = koerper.slice(0, 1800) + '\n\n[truncated — full set in the ZIP]';
    var betreff = 'TournaQ feedback — ' + heute();

    if (!zahlBilder()) { oeffneMail(betreff, koerper); return; }

    var datei = null;
    if (ZIP_BEREIT && ZIP_BEREIT.marke === zipMarke() && typeof File === 'function') {
      try {
        datei = new File([ZIP_BEREIT.blob], zipName(), { type: 'application/zip' });
      } catch (e) { datei = null; }
    }

    if (datei && kannTeilen() && navigator.canShare({ files: [datei] })) {
      navigator.share({ files: [datei], title: betreff, text: koerper })
        .catch(function (e) {
          /* Abgebrochen ist kein Fehler — dann wollte jemand nicht senden,
             und ein Download hinterher waere eine Zumutung. */
          if (e && e.name === 'AbortError') return;
          zipUndMail(betreff, koerper);
        });
      return;
    }
    zipUndMail(betreff, koerper);
  }

  /* ── Die Titel der Knoten ─────────────────────────────────────────────
     PAGES traegt sein Englisch; der Guide legt die Uebersetzung mit
     js/guide/uebersetzen.js darueber, geschluesselt nach dem englischen Satz
     selbst. Dasselbe hier — sonst stuende die Karte englisch in einer
     spanischen Seite.

     Nachgeladen statt eingebunden: js/guide/locales.js ist 772 kB, und das
     ist auf einer Rueckmeldeseite, die jemand am Spielfeldrand oeffnet, kein
     Beiwerk. Wer auf Englisch liest, laedt es nie. Gezeichnet wird sofort,
     die Uebersetzung kommt nach und zeichnet noch einmal — eine leere Seite,
     bis 772 kB da sind, waere der schlechtere Tausch. */
  var UE = { da: false, laeuft: false };

  function ladeSkript(src) {
    return new Promise(function (ok, weg) {
      var s = document.createElement('script');
      s.src = src;
      s.onload = ok;
      s.onerror = weg;
      document.head.appendChild(s);
    });
  }

  function sorgeFuerSprache() {
    var lang = sprache();
    if (UE.da) {
      if (typeof guideSprache === 'function') guideSprache(lang);
      zeichneAlles();
      return;
    }
    /* Englisch ist der Zustand, in dem PAGES ohnehin steht. */
    if (lang === 'en' || UE.laeuft) return;
    UE.laeuft = true;
    Promise.all([
      ladeSkript('../js/guide/locales.js'),
      ladeSkript('../js/guide/uebersetzen.js')
    ]).then(function () {
      UE.da = true;
      UE.laeuft = false;
      if (typeof guideSprache === 'function') guideSprache(sprache());
      zeichneAlles();
    }).catch(function () {
      /* Ohne Woerterbuch bleibt die Karte englisch. Das ist dieselbe Zusage,
         die der Guide fuer eine fehlende Uebersetzung gibt. */
      UE.laeuft = false;
    });
  }

  /* ── Verdrahtung ──────────────────────────────────────────────────────── */
  function zeichneAlles() {
    zeichneKarte();
    zeichneKnoten();
    zeichneKorb();
  }

  /* Die Karte faengt zwei Klicks ab: das Dreieck klappt einen Zweig auf und
     zu, ohne zu navigieren. Alles andere ist ein gewoehnlicher Hash-Link und
     darf durch — hashchange zeichnet dann neu. */
  rail.addEventListener('click', function (e) {
    var tw = e.target.closest('.g-tw');
    if (tw && tw.dataset.tw) {
      e.preventDefault();
      NAV_OPEN.has(tw.dataset.tw) ? NAV_OPEN.delete(tw.dataset.tw)
                                  : NAV_OPEN.add(tw.dataset.tw);
      zeichneKarte();
      return;
    }
    if (e.target.closest('a')) schliesse();
  });
  rail.addEventListener('keydown', function (e) {
    var tw = e.target.closest('.g-tw');
    if (tw && tw.dataset.tw && (e.key === 'Enter' || e.key === ' ')) {
      e.preventDefault();
      tw.click();
    }
  });
  rail.addEventListener('input', function (e) {
    if (e.target.id !== 'fb-search') return;
    SUCHE = e.target.value.trim();
    var stand = e.target.selectionStart;
    zeichneKarte();
    var neu = document.getElementById('fb-search');
    if (neu) { neu.focus(); try { neu.setSelectionRange(stand, stand); } catch (err) {} }
  });

  /* Das Formular wird bei jedem Zeichnen neu gebaut, also haengen die
     Handler am Kasten darum und nicht an den Feldern selbst. */
  knotenKasten.addEventListener('click', function (e) {
    var chip = e.target.closest('.fb-chip');
    if (chip) {
      ENTWURF.kind = ENTWURF.kind === chip.dataset.kind ? '' : chip.dataset.kind;
      zeichneKnoten();
      return;
    }
    var kachel = e.target.closest('.fb-erk-kachel');
    if (kachel) { zeigeGross(erkBilder(AKTIV)[Number(kachel.dataset.erk)], kachel); return; }
    if (e.target.id === 'fb-add') { fuegeHinzu(); return; }
    if (e.target.id === 'fb-pick') { waehleDatei(); return; }
    if (e.target.id === 'fb-mic') { diktiere(e.target); return; }
  });
  knotenKasten.addEventListener('input', function (e) {
    if (e.target.id === 'fb-text') ENTWURF.text = e.target.value;
  });

  function fuegeHinzu() {
    var text = (ENTWURF.text || '').trim();
    if (!text) { alert(t('needText')); return; }
    if (!daten.notes[AKTIV]) daten.notes[AKTIV] = [];
    daten.notes[AKTIV].push({
      id: neueId(), kind: ENTWURF.kind, text: text,
      shots: ENTWURF.shots.slice(), ts: jetzt(),
      lang: sprache()
    });
    sichern();
    ENTWURF = { kind: '', text: '', shots: [] };
    zeichneAlles();
    var knopf = document.getElementById('fb-add');
    if (knopf) {
      var alt = knopf.textContent;
      knopf.textContent = t('added');
      setTimeout(function () { knopf.textContent = alt; }, 1400);
    }
  }

  /* ── Bilder aufnehmen ─────────────────────────────────────────────────── */
  function nimmDatei(datei) {
    if (!datei || datei.type.indexOf('image/') !== 0) return;
    bildSpeichern(datei).then(function (id) {
      ENTWURF.shots.push(id);
      zeichneEntwurfBilder();
    }).catch(function () {});
  }
  function waehleDatei() {
    var f = document.createElement('input');
    f.type = 'file';
    f.accept = 'image/*';
    f.multiple = true;
    f.addEventListener('change', function () {
      Array.prototype.forEach.call(f.files, nimmDatei);
    });
    f.click();
  }
  document.addEventListener('paste', function (e) {
    var items = (e.clipboardData || {}).items || [];
    Array.prototype.forEach.call(items, function (it) {
      if (it.type && it.type.indexOf('image/') === 0) nimmDatei(it.getAsFile());
    });
  });
  knotenKasten.addEventListener('dragover', function (e) {
    if (!e.target.closest('#fb-drop')) return;
    e.preventDefault();
    e.target.closest('#fb-drop').classList.add('drueber');
  });
  knotenKasten.addEventListener('dragleave', function (e) {
    var d = e.target.closest('#fb-drop');
    if (d) d.classList.remove('drueber');
  });
  knotenKasten.addEventListener('drop', function (e) {
    var d = e.target.closest('#fb-drop');
    if (!d) return;
    e.preventDefault();
    d.classList.remove('drueber');
    Array.prototype.forEach.call(e.dataTransfer.files, nimmDatei);
  });

  /* ── Diktat ───────────────────────────────────────────────────────────
     Web Speech API. Braucht einen sicheren Kontext — unter file:// gibt es
     sie nicht, und das ist hier kein Randfall, sondern der Normalfall beim
     lokalen Ausprobieren. Dann sagt der Knopf, was stattdessen geht. */
  var erkennung = null;
  function diktiere(knopf) {
    var SR = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SR || !window.isSecureContext) {
      alert('Dictation needs a secure context (https), which this page does not have.\n\n' +
            'Use the system dictation instead — on macOS press Fn twice with the cursor in the field.');
      return;
    }
    if (erkennung) { erkennung.stop(); return; }
    var feld = document.getElementById('fb-text');
    erkennung = new SR();
    erkennung.lang = { de: 'de-DE', es: 'es-ES', en: 'en-US' }[sprache()] || 'en-US';
    erkennung.interimResults = false;
    erkennung.continuous = true;
    knopf.classList.add('an');
    knopf.title = t('dictateStop');
    erkennung.addEventListener('result', function (ev) {
      var stueck = '';
      for (var i = ev.resultIndex; i < ev.results.length; i++) stueck += ev.results[i][0].transcript;
      feld.value = (feld.value ? feld.value.replace(/\s*$/, '') + ' ' : '') + stueck.trim();
      ENTWURF.text = feld.value;
    });
    erkennung.addEventListener('end', function () {
      erkennung = null;
      knopf.classList.remove('an');
      knopf.title = t('dictate');
    });
    erkennung.addEventListener('error', function (ev) {
      if (ev.error !== 'aborted' && ev.error !== 'no-speech') alert('Dictation stopped: ' + ev.error);
    });
    try { erkennung.start(); }
    catch (err) { erkennung = null; alert('Dictation could not start: ' + err.message); }
  }

  /* ── Router ───────────────────────────────────────────────────────────
     Dieselben Adressen wie im Guide: #/<knoten>. Ein Link aus der App landet
     damit genau auf dem Punkt, von dem aus er geoeffnet wurde. Ein
     unbekannter Knoten faellt auf 'home' zurueck, statt eine leere Seite zu
     zeigen — eine geaenderte Guide-Struktur darf einen Link nicht toeten. */
  function ausHash() {
    var h = (location.hash || '').replace(/^#\/?/, '');
    return (h && PAGES[h]) ? h : 'home';
  }
  function gehe() {
    var neu = ausHash();
    if (neu === AKTIV) return;
    /* Steht noch eine Aufnahme gross offen, gehoert sie zur alten Stelle —
       ueber der neuen waere sie schlicht das falsche Bild. Der Zurueck-Knopf
       kommt hier an, ohne dass jemand auf den Hintergrund geklickt hat. */
    schliesseLicht();
    AKTIV = neu;
    ENTWURF = { kind: '', text: '', shots: [] };
    /* Den Zweig aufdecken, in dem der Knoten steht — sonst zeigt die Karte
       eine Auswahl, die man nicht sieht. */
    pfad(AKTIV).forEach(function (k) { NAV_OPEN.add(k); });
    zeichneAlles();
  }
  window.addEventListener('hashchange', gehe);

  /* ── Drawer unter 900px ───────────────────────────────────────────────
     Dieselbe Mechanik wie js/site-map.js: die Burger-Checkbox im Kopf bleibt
     die einzige Wahrheit ueber "Menue offen", damit nie zwei Navigationen
     zugleich offen stehen. */
  var mq = window.matchMedia('(max-width: 900px)');
  var toggle = document.getElementById('nav-toggle');
  var scrim = null;
  function oeffne() {
    rail.classList.add('open');
    if (scrim) return;
    scrim = document.createElement('div');
    scrim.className = 'g-scrim';
    scrim.addEventListener('click', schliesse);
    document.body.appendChild(scrim);
  }
  function schliesse() {
    rail.classList.remove('open');
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
    if (e.key !== 'Escape') return;
    /* Liegt ein Bild gross ueber der Seite, gilt Escape ihm und nicht der
       Karte darunter: geschlossen wird, was oben liegt. */
    if (LICHT) { schliesseLicht(); return; }
    schliesse();
  });

  /* ── Start ────────────────────────────────────────────────────────────── */
  main.insertBefore(rail, main.firstChild);
  main.classList.add('has-section-nav');
  document.body.classList.add('section-nav-drawer');

  AKTIV = ausHash();
  pfad(AKTIV).forEach(function (k) { NAV_OPEN.add(k); });
  zeichneAlles();
  sorgeFuerSprache();

  if (!speicherGeht) {
    var warnung = document.createElement('p');
    warnung.className = 'fb-warn';
    warnung.textContent = t('noStore');
    main.insertBefore(warnung, knotenKasten);
  }

  /* Der Inhalt hier steht nicht als data-i18n im Dokument, also muss er beim
     Sprachwechsel selbst neu gezeichnet werden — genau wie im User Guide. */
  document.addEventListener('tq-lang', function () {
    zeichneAlles();
    sorgeFuerSprache();
  });
})();
