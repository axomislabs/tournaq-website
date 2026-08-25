#!/usr/bin/env python3
"""Spielt die CSV aus dem Karten-Review zurueck in cards.json.

    python3 tools/cards/apply-card-review.py                 # neueste CSV aus ~/Downloads
    python3 tools/cards/apply-card-review.py <datei.csv>
    python3 tools/cards/apply-card-review.py --dry-run
    python3 tools/cards/apply-card-review.py --bauen   # und gleich neu rendern

Uebernommen werden nur die Textfelder Titel, Sub und Kurz - und auch die
nur, wenn die Karte in der CSV steht und das Feld gefuellt ist. Status und
Kommentar werden nicht angewendet, sondern am Ende ausgegeben: was jemand
"ueberarbeiten" nennt, braucht eine Entscheidung und keinen Textersatz.

Wie tools/apply-review.py haelt das Skript vorher an, wenn etwas nicht passt,
statt halb zu schreiben.
"""

import csv
import json
import subprocess
import sys
from pathlib import Path

HIER = Path(__file__).resolve().parent
DATEN = HIER / "cards.json"
DOWNLOADS = Path.home() / "Downloads"

FELDER = [("Titel", "titel"), ("Sub", "sub"), ("Kurz", "kurz")]


def neueste_csv():
    treffer = sorted(DOWNLOADS.glob("tournaq-karten-*.csv"),
                     key=lambda p: p.stat().st_mtime, reverse=True)
    if not treffer:
        sys.exit(f"Keine tournaq-karten-*.csv in {DOWNLOADS}.\n"
                 "Im Review unten auf 'CSV laden' klicken, oder Pfad angeben.")
    return treffer[0]


def main():
    argv = sys.argv[1:]
    trocken = "--dry-run" in argv
    if trocken:
        argv.remove("--dry-run")
    bauen = "--bauen" in argv
    if bauen:
        argv.remove("--bauen")
    if bauen and trocken:
        sys.exit("--bauen und --dry-run schliessen sich aus.")
    quelle = Path(argv[0]).expanduser() if argv else neueste_csv()
    if not quelle.exists():
        sys.exit(f"Nicht gefunden: {quelle}")
    print(f"CSV: {quelle}")

    daten = json.loads(DATEN.read_text(encoding="utf8"))
    nach_slug = {k["slug"]: k for k in daten["karten"]}

    # utf-8-sig frisst das BOM, das die Seite fuer Excel schreibt.
    with quelle.open(encoding="utf-8-sig", newline="") as f:
        zeilen = list(csv.DictReader(f, delimiter=";"))

    fehlt = sorted({r["Slug"] for r in zeilen if r.get("Slug") not in nach_slug})
    if fehlt:
        sys.exit("ABBRUCH: Slugs aus der CSV stehen nicht in cards.json: "
                 + ", ".join(fehlt))

    aenderungen, notizen = [], []
    for r in zeilen:
        k = nach_slug[r["Slug"]]
        for spalte, feld in FELDER:
            neu = (r.get(spalte) or "").strip()
            if neu and neu != k.get(feld, ""):
                aenderungen.append((r["Slug"], feld, k.get(feld, ""), neu))
                if not trocken:
                    k[feld] = neu
        # alt traegt genau die Worte, die im Bild stehen. Wandert der Text,
        # muss es mitwandern, sonst liest ein Screenreader etwas anderes vor,
        # als auf der Karte steht.
        if not trocken:
            k["alt"] = f'{k["titel"]} — ' + k["sub"].replace("\n", " ")

        if r.get("Status") or r.get("Kommentar"):
            notizen.append((r["Slug"], r.get("Status", ""), r.get("Kommentar", "")))

    for slug, feld, alt, neu in aenderungen:
        print(f"  {slug}/{feld}")
        print(f"    alt: {alt!r}")
        print(f"    neu: {neu!r}")

    if not aenderungen:
        print("  keine Textaenderungen")
    elif trocken:
        print(f"\n--dry-run: {len(aenderungen)} Aenderung(en), nichts geschrieben.")
    else:
        DATEN.write_text(json.dumps(daten, indent=2, ensure_ascii=False) + "\n",
                         encoding="utf8")
        print(f"\n{len(aenderungen)} Aenderung(en) in cards.json geschrieben.")
        betroffen = sorted({s for s, *_ in aenderungen})
        # Seit die Texte als HTML ueber dem Bild liegen, aendert eine
        # Textkorrektur die PNGs nicht mehr - build-cards.py muss also gar
        # nicht laufen. Gebacken werden muss dafuer der Guide.
        folge = ["bake-guide-cards.py", "build-card-review.py", "build-mockup.py"]
        if bauen:
            for skript in folge:
                print()
                subprocess.run([sys.executable, str(HIER / skript)], check=True)
        else:
            print("Weiter mit:")
            for skript in folge:
                print(f"  python3 tools/cards/{skript}")
            print("  (build-cards.py nur bei Ausschnitt, Zoom oder Scrim —"
                  " Texte stecken nicht mehr im Bild)")

    if notizen:
        print(f"\n{len(notizen)} Karte(n) mit Status oder Kommentar "
              "- die brauchen eine Entscheidung, nicht nur einen Textersatz:")
        for slug, status, kommentar in notizen:
            kopf = f"  {slug}" + (f"  [{status}]" if status else "")
            print(kopf)
            if kommentar:
                for zeile in kommentar.splitlines():
                    print(f"      {zeile}")


if __name__ == "__main__":
    main()
