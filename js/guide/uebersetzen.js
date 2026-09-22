/* Legt die Uebersetzung ueber den Inhalt des User Guide.
 *
 * Der Guide folgt demselben Prinzip wie der Rest der Site: das Englische ist
 * der Fallback und steht im Dokument, die Uebersetzung wird im Browser
 * darueber gelegt. Auf den handgeschriebenen Seiten macht das js/i18n.js ueber
 * data-i18n; hier greift es eine Ebene tiefer, weil das HTML des Guides nicht
 * geschrieben, sondern aus js/guide/pages.js erzeugt wird. Uebersetzt werden
 * deshalb die Daten, nicht das DOM — dann ziehen die gebackene Seite und jede
 * per Hash-Route nachgezeichnete Unterseite durch denselben Weg.
 *
 * Der Schluessel ist der englische Satz selbst (js/guide/locales.js). Fehlt
 * einer, bleibt der englische stehen — dieselbe Zusage wie beim Inline-Text
 * der uebrigen Seiten.
 *
 * Uebersetzt werden PAGES, EXTERN und CARDS. EXTERN stand lange nicht dabei
 * — die Zeilen der Seitenleiste, die aus dem Guide hinaus auf die uebrige
 * Website zeigen, blieben deshalb in jeder Sprache englisch, waehrend die
 * Guide-Zeilen daneben uebersetzt waren. tools/guide-strings.mjs hat sie von
 * Anfang an mitgezaehlt, also lagen die Uebersetzungen bereit und wurden nur
 * nie eingesetzt.
 *
 * PAGES, EXTERN und CARDS sind mit `const` deklariert und lassen sich nicht
 * neu binden, also wird an Ort und Stelle ersetzt. Damit ein Sprachwechsel nicht
 * auf bereits uebersetztem Text aufsetzt, wird beim ersten Lauf eine
 * englische Kopie beiseitegelegt; jede Umschaltung geht von ihr aus.
 */

/* Die Felder, die Sprache tragen — eins zu eins die Bausteine aus
 * js/guide/pages.js. Diese Liste ist die einzige: tools/guide-strings.mjs
 * liest sie aus dieser Datei, statt eine zweite zu pflegen. Ein Feld, das nur
 * in einer der beiden stuende, bliebe still englisch. */
var GUIDE_TEXTFELDER = [
  'title', 'eyebrow', 'h1', 'lead',   /* Seite   */
  'badge', 'sub',                     /* panel   */
  'label', 'cap',                     /* item, step, split, fork, grid, sect */
  'chip',                             /* die Marke neben einem Etikett       */
  'body', 'alt',                      /* fbox, shot, note */
  'name', 'values', 'dflt', 'what', 'when', 'help',  /* opts */
  'cols'                              /* die Spaltenkoepfe einer opts-Tabelle */
];

/* Zeichenketten ohne Sprache: Ikonen, Routen, Pfade, Knotenkennungen. In
 * PAGES sind `t` und `k` die Art des Bausteins — in CARDS dagegen Titel und
 * Kicker, deshalb werden Karten getrennt gelaufen. */
var GUIDE_STRUKTURFELDER = [
  'icon', 't', 'k', 'src', 'to', 'route', 'parent', 'tone', 'id', 'spec',
  'img', 'href', 'n', 'w', 'h', 'sizes', 'cards'
];

/* Die Textfelder einer Karte aus CARDS. */
var GUIDE_KARTENFELDER = { t: 'title', s: 's', alt: 'alt', k: 'k' };

/* Laeuft den Baum ab und ruft `fass(text, feld)` fuer jede sprachtragende
 * Zeichenkette. Gibt fass etwas zurueck, wird es eingesetzt; gibt es
 * undefined zurueck, bleibt der Wert stehen. Ein Besucher, der nur liest,
 * gibt nie etwas zurueck — so teilen Extraktor und Uebersetzer denselben Weg
 * durch die Daten. */
function guideGehe(wurzel, fass) {
  var TEXT = GUIDE_TEXTFELDER, STRUKT = GUIDE_STRUKTURFELDER;
  function gehe(o, feld) {
    if (o === null || typeof o !== 'object') return;
    if (Array.isArray(o)) {
      for (var i = 0; i < o.length; i++) {
        /* `cards` traegt dreierlei: blosse Kennungen (imgcards(['quick-game',
           …])), Objekte mit label/cap (grid), und Paare [Kennung, Etikett] —
           bei denen nur das zweite Feld Sprache traegt. Ohne diesen Zweig
           blieben die zehn Modus-Etiketten auf der Arena-Seite englisch. */
        if (feld === 'cards' && Array.isArray(o[i]) &&
            o[i].length === 2 && typeof o[i][1] === 'string') {
          var e = fass(o[i][1], 'label');
          if (e !== undefined) o[i][1] = e;
          continue;
        }
        if (typeof o[i] === 'string') {
          if (TEXT.indexOf(feld) >= 0 && o[i].trim()) {
            var n = fass(o[i], feld);
            if (n !== undefined) o[i] = n;
          }
        } else gehe(o[i], feld);
      }
      return;
    }
    for (var k in o) {
      if (!Object.prototype.hasOwnProperty.call(o, k)) continue;
      var v = o[k];
      if (typeof v === 'string') {
        if (STRUKT.indexOf(k) >= 0) continue;
        if (TEXT.indexOf(k) >= 0 && v.trim()) {
          var neu = fass(v, k);
          if (neu !== undefined) o[k] = neu;
        }
      } else gehe(v, k);
    }
  }
  gehe(wurzel, null);
}

/* Karten tragen ihre Sprache in anders benannten Feldern. */
function guideGeheKarten(karten, fass) {
  for (var id in karten) {
    if (!Object.prototype.hasOwnProperty.call(karten, id)) continue;
    for (var f in GUIDE_KARTENFELDER) {
      var v = karten[id][f];
      if (typeof v !== 'string' || !v.trim()) continue;
      var neu = fass(v, GUIDE_KARTENFELDER[f]);
      if (neu !== undefined) karten[id][f] = neu;
    }
  }
}

/* ── Umschalten ──────────────────────────────────────────────────────────── */

/* Das englische Original, beiseitegelegt beim ersten Aufruf. Ohne diese Kopie
   wuerde die zweite Umschaltung auf deutschem Text nachschlagen und nichts
   mehr finden. */
var GUIDE_EN = null;

/* Die aktive Sprache, damit js/guide/render.js die paar Zeichenketten
   nachschlagen kann, die er selbst mitbringt statt aus PAGES zu lesen —
   "Back to" ueber dem Elternknoten und die Zeile der Download-Karte. Sie
   stehen in GUIDE_RENDER_STRINGS und gehen denselben Weg wie der Inhalt. */
var GUIDE_LANG = 'en';

function guideT(en) {
  var wb = (typeof GUIDE_LOCALES !== 'undefined' && GUIDE_LOCALES[GUIDE_LANG]) || null;
  return (wb && wb[en] != null) ? wb[en] : en;
}

function guideSichere() {
  if (GUIDE_EN) return;
  GUIDE_EN = { pages: [], extern: [], cards: [] };
  guideGehe(typeof PAGES !== 'undefined' ? PAGES : {}, function (s) { GUIDE_EN.pages.push(s); });
  guideGehe(typeof EXTERN !== 'undefined' ? EXTERN : {}, function (s) { GUIDE_EN.extern.push(s); });
  guideGeheKarten(typeof CARDS !== 'undefined' ? CARDS : {}, function (s) { GUIDE_EN.cards.push(s); });
}

/* Setzt den Guide auf eine Sprache. 'en' stellt das Original zurueck.
   Liefert die Zahl der Strings, fuer die keine Uebersetzung vorlag — der
   Guide bleibt dort englisch, und die Zahl ist der Beleg dafuer. */
function guideSprache(lang) {
  guideSichere();
  GUIDE_LANG = lang;
  var wb = (typeof GUIDE_LOCALES !== 'undefined' && GUIDE_LOCALES[lang]) || null;
  var i = 0, fehlt = 0;
  var setze = function (quelle) {
    return function () {
      var en = quelle[i++];
      if (!wb) return en;
      var t = wb[en];
      if (t == null) { fehlt++; return en; }
      return t;
    };
  };
  i = 0; guideGehe(typeof PAGES !== 'undefined' ? PAGES : {}, setze(GUIDE_EN.pages));
  i = 0; guideGehe(typeof EXTERN !== 'undefined' ? EXTERN : {}, setze(GUIDE_EN.extern));
  i = 0; guideGeheKarten(typeof CARDS !== 'undefined' ? CARDS : {}, setze(GUIDE_EN.cards));
  return fehlt;
}
