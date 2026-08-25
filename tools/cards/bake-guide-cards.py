#!/usr/bin/env python3
"""Backt die Kartendaten aus cards.json in pages/guide.html.

    python3 tools/cards/bake-guide-cards.py [--dry-run]

Der Guide ist eine einzelne, selbsttragende Datei ohne Build-Schritt - er kann
cards.json zur Laufzeit nicht lesen. Statt die Texte dort von Hand zu pflegen
und damit doppelt zu halten, schreibt dieses Skript einen Block zwischen zwei
Markern neu. cards.json bleibt die eine Quelle; nach jeder Textaenderung hier
einmal drueberlaufen lassen.

Dasselbe Muster wie tools/bake-feature-matrix.py.
"""

import json
import re
import sys
from pathlib import Path

HIER = Path(__file__).resolve().parent
WURZEL = HIER.parent.parent
DATEN = HIER / "cards.json"
GUIDE = WURZEL / "pages" / "guide.html"

START = "/* ══ CARDS — gebacken aus tools/cards/cards.json, nicht von Hand ══ */"
ENDE = "/* ══ Ende CARDS ══ */"


def cqw(px):
    """px aus cards.json in cqw. Rendermass war 1600px, ein cqw sind 16px."""
    return f"{float(str(px).replace('px', '')) / 16:g}cqw"


def js_str(t):
    return "'" + t.replace("\\", "\\\\").replace("'", "\\'") + "'"


def zeile(k):
    felder = [
        f"img:{js_str(k['slug'])}",
        f"to:{js_str(k['ziel'])}",
        f"t:{js_str(k['titel'].replace(chr(10), '<br>'))}",
        f"s:{js_str(k.get('sub', '').replace(chr(10), '<br>'))}",
        f"alt:{js_str(k.get('alt', k['titel']))}",
    ]
    if k.get("kurz"):
        # Einzeiler fuer das Prinzip-Raster. Ueberall sonst gilt die lange
        # Subline; dort ist Platz fuer zwei bis vier Zeilen.
        felder.append(f"k:{js_str(k['kurz'])}")
    felder += [
    ]
    if k.get("platzhalter"):
        # Als Platzhalter markieren. Der Guide ueberspringt solche Karten -
        # ein gestrichelter Rahmen als Hero auf einer echten Seite waere
        # schlimmer als gar kein Hero.
        felder.append("ph:1")
    stil = []
    if k.get("t-h1"):
        stil.append(f"--tq-t:{cqw(k['t-h1'])}")
    if k.get("t-sub"):
        stil.append(f"--tq-s:{cqw(k['t-sub'])}")
    if stil:
        felder.append(f"st:{js_str(';'.join(stil))}")
    return f"  {js_str(k['slug'])}: {{" + ", ".join(felder) + "},"


def main():
    trocken = "--dry-run" in sys.argv
    karten = json.loads(DATEN.read_text(encoding="utf8"))["karten"]
    block = "\n".join([START, "const CARDS = {"]
                      + [zeile(k) for k in karten]
                      + ["};",
                         "/* Zielseite -> Karte, fuer das Hero-Bild oben auf der Seite. */",
                         "const CARD_BY_ZIEL = {};",
                         "Object.keys(CARDS).forEach(s => CARD_BY_ZIEL[CARDS[s].to] = CARDS[s]);",
                         ENDE])

    html = GUIDE.read_text(encoding="utf8")

    # Zeigt eine Karte auf eine Seite, die es nicht mehr gibt, fuehrt sie ins
    # Leere - der Guide faellt bei so einem Hash stillschweigend auf die
    # Startseite zurueck, ohne dass jemand es merkt. Beim Umbau der
    # Seitenstruktur ist genau das die Gefahr.
    blk = html[html.index("const PAGES = {"):html.index("const NAV")]
    seiten = set(re.findall(r"^'?([a-z0-9-]+)'?:\s*\{", blk, re.M))
    tot = sorted({k["ziel"] for k in karten if k["ziel"] not in seiten})
    if tot:
        sys.exit("FEHLER: Karten zeigen auf Seiten, die es in guide.html nicht "
                 "gibt:\n  " + "\n  ".join(tot))

    if START not in html:
        sys.exit(f"FEHLER: Marker fehlt in {GUIDE}.\n"
                 f"       Erwartet wird ein Block zwischen\n"
                 f"         {START}\n       und\n         {ENDE}")
    neu = re.sub(re.escape(START) + r".*?" + re.escape(ENDE), lambda m: block,
                 html, flags=re.S)
    if neu == html:
        print("unveraendert")
        return
    if trocken:
        print(f"--dry-run: {len(karten)} Karten wuerden geschrieben.")
        return
    GUIDE.write_text(neu, encoding="utf8")
    print(f"pages/guide.html: {len(karten)} Karten gebacken")


if __name__ == "__main__":
    main()
