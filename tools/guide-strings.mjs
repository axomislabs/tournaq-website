/* Liest die uebersetzbaren Zeichenketten des User Guide aus js/guide/pages.js.
 *
 *     node tools/guide-strings.mjs list      # alle eindeutigen Strings als JSON
 *     node tools/guide-strings.mjs stat      # nur die Zahlen
 *     node tools/guide-strings.mjs todo de   # was in js/guide/locales.js fehlt
 *
 * Warum ueberhaupt ein Extraktor: der Guide ist die einzige Ecke der Site,
 * deren HTML *erzeugt* wird. Auf den handgeschriebenen Seiten tippt ein Mensch
 * data-i18n="index.teams.league.text" — hier waeren es ueber viertausend
 * Strings in einem generierten Baum, und ein Schluessel nach Position
 * (blocks.3.items.2.cap) verschoebe sich still, sobald jemand einen Block
 * einschiebt. Genau der Fehler, gegen den tools/check-i18n.py gebaut wurde.
 *
 * Deshalb ist der Schluessel hier der englische Satz selbst. Damit gilt die
 * Regel "geaendertes Englisch = neuer Schluessel" nicht mehr per Disziplin,
 * sondern per Konstruktion: aendert sich der Satz, greift die Uebersetzung
 * nicht mehr, es faellt auf Englisch zurueck, und `stat` zeigt den Fehlbetrag.
 *
 * Der Weg durch die Daten kommt aus js/guide/uebersetzen.js — derselbe, den
 * der Browser geht. Zwei Listen von Textfeldern haetten bedeutet, dass ein
 * Feld in der einen fehlt und der Guide dort still englisch bleibt.
 */
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const WURZEL = path.dirname(fileURLToPath(new URL('.', import.meta.url)).replace(/\/$/, ''));
/* fileURLToPath statt .pathname: eine file:-URL ist prozentkodiert, und ein
   Leerzeichen im Projektpfad kam hier als %20 an — 'Project%20TournaQ' gibt es
   auf keiner Platte, also scheiterte jeder Lauf mit ENOENT. */

/* Die sechs Felder der opts-Tabellen. Sie kommen nirgends sonst vor, also
 * genuegt der Feldname, um einen String als App-Oberflaeche zu erkennen —
 * und die ist aus tournaq/lib/l10n/ zu holen, nicht zu erfinden. */
const OPTS_FELDER = new Set(['name', 'values', 'dflt', 'what', 'when', 'help']);

function ktx() {
  const c = vm.createContext({ console });
  /* render.js kommt mit, weil er zwei Zeichenketten selbst mitbringt
     (GUIDE_RENDER_STRINGS) — ohne ihn blieben die in jeder Sprache englisch. */
  for (const f of ['js/guide/pages.js', 'js/guide/uebersetzen.js', 'js/guide/render.js'])
    vm.runInContext(fs.readFileSync(path.join(WURZEL, f), 'utf8'), c, { filename: f });
  return c;
}

/* Alle Vorkommen, in genau der Reihenfolge, in der guideSprache() sie im
 * Browser ersetzt. Die Reihenfolge ist nicht Kosmetik: dort wird der Reihe
 * nach aus der englischen Kopie gelesen, also muss sie hier dieselbe sein. */
export function vorkommen() {
  const c = ktx();
  const treffer = [];
  c.__sammle = (s, feld, knoten) => {
    treffer.push({ en: s, feld, knoten, opts: OPTS_FELDER.has(feld) });
  };
  vm.runInContext(`
    for (const id of Object.keys(PAGES))
      guideGehe(PAGES[id], (s, f) => { __sammle(s, f, id); });
    guideGeheKarten(CARDS, (s, f) => { __sammle(s, f, 'cards'); });
  `, c);
  for (const [id, e] of Object.entries(vm.runInContext('EXTERN', c) || {}))
    for (const f of ['title', 'label'])
      if (typeof e[f] === 'string' && e[f].trim())
        treffer.push({ en: e[f], feld: f, knoten: 'extern:' + id, opts: false });
  for (const s of vm.runInContext('typeof GUIDE_RENDER_STRINGS !== "undefined" ? GUIDE_RENDER_STRINGS : []', c))
    treffer.push({ en: s, feld: 'label', knoten: 'render', opts: false });
  return treffer;
}

/* Eindeutig, in Reihenfolge des ersten Auftretens. Derselbe Satz auf drei
 * Modusseiten wird einmal uebersetzt — das halbiert die Arbeit fast und haelt
 * die Seiten gleichlautend. */
export function eindeutig() {
  const map = new Map();
  for (const t of vorkommen()) {
    const e = map.get(t.en);
    if (e) { e.n++; e.felder.add(t.feld); e.knoten.add(t.knoten); e.opts ||= t.opts; }
    else map.set(t.en, { en: t.en, n: 1, felder: new Set([t.feld]),
                         knoten: new Set([t.knoten]), opts: t.opts });
  }
  return [...map.values()].map(e => ({
    en: e.en, n: e.n, opts: e.opts,
    felder: [...e.felder], knoten: [...e.knoten].slice(0, 4),
  }));
}

export function locales() {
  const p = path.join(WURZEL, 'js/guide/locales.js');
  if (!fs.existsSync(p)) return {};
  const c = vm.createContext({});
  vm.runInContext(fs.readFileSync(p, 'utf8'), c, { filename: 'js/guide/locales.js' });
  return vm.runInContext('GUIDE_LOCALES', c) || {};
}

/* ── CLI ───────────────────────────────────────────────────────────────────
 * Nur wenn diese Datei selbst aufgerufen wird: tools/guide-merge.mjs
 * importiert sie, und ohne diese Schranke liefe die Argumentpruefung dort mit
 * den Argumenten des Aufrufers. */
const direkt = process.argv[1] &&
  new URL('file://' + process.argv[1]).pathname === new URL(import.meta.url).pathname;
const [, , befehl, arg] = process.argv;
const woerter = s => s.split(/\s+/).filter(Boolean).length;

if (!direkt) {
  /* als Bibliothek geladen — nichts tun */
} else if (befehl === 'list') {
  process.stdout.write(JSON.stringify(eindeutig(), null, 1));
} else if (befehl === 'stat') {
  const alle = vorkommen(), uniq = eindeutig();
  const summe = a => a.reduce((s, e) => s + woerter(e.en), 0);
  console.log('Vorkommen   %d Strings, %d Woerter', alle.length, summe(alle));
  console.log('eindeutig   %d Strings, %d Woerter', uniq.length, summe(uniq));
  console.log('  davon opts-Tabellen (App-UI): %d', uniq.filter(e => e.opts).length);
  console.log('  davon alt-Texte:              %d', uniq.filter(e => e.felder.includes('alt')).length);
  const L = locales();
  for (const s of ['de', 'es']) {
    const fehlt = uniq.filter(e => !(L[s] || {})[e.en]);
    console.log('%s           %d/%d uebersetzt, %d offen (%d Woerter)',
                s, uniq.length - fehlt.length, uniq.length, fehlt.length, summe(fehlt));
  }
} else if (befehl === 'todo') {
  const L = locales()[arg] || {};
  process.stdout.write(JSON.stringify(eindeutig().filter(e => !L[e.en]), null, 1));
} else {
  console.error('Aufruf: node tools/guide-strings.mjs list|stat|todo <de|es>');
  process.exit(2);
}
