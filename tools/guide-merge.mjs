/* Traegt uebersetzte Stapel in js/guide/locales.js ein.
 *
 *     node tools/guide-merge.mjs stapel.json
 *
 * Die Stapeldatei ist {"de": {"<englischer Satz>": "<Uebersetzung>", …},
 * "es": {…}} — dieselbe Form wie der Speicher selbst. Bestehende Eintraege
 * werden ueberschrieben, fehlende bleiben fehlen.
 *
 * Die Datei wird jedes Mal neu geschrieben, in der Reihenfolge, in der die
 * Strings im Guide vorkommen (guide-strings.mjs). Damit ist ein Diff zwischen
 * zwei Laeufen lesbar und nicht von einer Hash-Reihenfolge durcheinander
 * gewuerfelt. Eintraege, deren englische Fassung es nicht mehr gibt, wandern
 * ans Ende unter WAISEN — sie sind der Beleg dafuer, dass jemand den
 * englischen Satz geaendert hat, und genau die Stelle, die nachgezogen
 * gehoert.
 */
import fs from 'node:fs';
import path from 'node:path';
import { eindeutig, locales } from './guide-strings.mjs';

const WURZEL = path.dirname(new URL('.', import.meta.url).pathname.replace(/\/$/, ''));
const ZIEL = path.join(WURZEL, 'js/guide/locales.js');
const SPRACHEN = ['de', 'es'];

const stapelPfad = process.argv[2];
if (!stapelPfad) { console.error('Aufruf: node tools/guide-merge.mjs <stapel.json>'); process.exit(2); }

const alt = locales();
const neu = JSON.parse(fs.readFileSync(stapelPfad, 'utf8'));

const speicher = {};
for (const s of SPRACHEN) speicher[s] = Object.assign({}, alt[s] || {}, neu[s] || {});

const reihenfolge = eindeutig().map(e => e.en);
const bekannt = new Set(reihenfolge);
const js = s => JSON.stringify(s);

let text = `/* Der User Guide in Deutsch und Spanisch.
 *
 * Der Schluessel ist der englische Satz selbst. Der Guide ist die einzige
 * Ecke der Site, deren HTML erzeugt wird — auf den handgeschriebenen Seiten
 * tippt ein Mensch data-i18n="index.teams.league.text", hier waeren es ueber
 * viertausend Strings in einem generierten Baum, und ein Schluessel nach
 * Position verschoebe sich still, sobald jemand einen Block einschiebt.
 *
 * So gilt die Regel der Site — geaendertes Englisch bekommt einen neuen
 * Schluessel, damit DE/ES nicht die alte Aussage weiterlesen — hier per
 * Konstruktion: aendert sich der englische Satz in js/guide/pages.js, greift
 * die Uebersetzung nicht mehr, die Seite faellt auf Englisch zurueck, und
 * "node tools/guide-strings.mjs stat" zeigt den Fehlbetrag.
 *
 * Terminologie folgt der App, nicht dem Marketing: die Begriffe stammen aus
 * tournaq/lib/l10n/app_de.arb und app_es.arb, kuratiert in
 * tools/guide-glossary.json. Wer die App auf Deutsch bedient, muss im Guide
 * die Woerter wiederfinden, die auf dem Bildschirm stehen.
 *
 * Nicht von Hand sortieren — tools/guide-merge.mjs schreibt die Datei.
 */
var GUIDE_LOCALES = {
`;

for (const s of SPRACHEN) {
  text += `  ${s}: {\n`;
  for (const en of reihenfolge) {
    if (speicher[s][en] != null) text += `    ${js(en)}: ${js(speicher[s][en])},\n`;
  }
  const waisen = Object.keys(speicher[s]).filter(k => !bekannt.has(k));
  if (waisen.length) {
    text += `\n    /* WAISEN — das englische Original gibt es so nicht mehr.\n`;
    text += `       Entweder der Satz wurde umformuliert (dann hier loeschen und neu\n`;
    text += `       uebersetzen) oder die Seite ist weg (dann hier loeschen). */\n`;
    for (const en of waisen) text += `    ${js(en)}: ${js(speicher[s][en])},\n`;
  }
  text += `  },\n`;
}
text += `};\n`;

fs.writeFileSync(ZIEL, text);

for (const s of SPRACHEN) {
  const da = reihenfolge.filter(en => speicher[s][en] != null).length;
  const waisen = Object.keys(speicher[s]).filter(k => !bekannt.has(k)).length;
  console.log('%s  %d/%d uebersetzt%s', s, da, reihenfolge.length,
              waisen ? `, ${waisen} Waisen` : '');
}
