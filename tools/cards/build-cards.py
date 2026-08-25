#!/usr/bin/env python3
"""Baut aus den Referenzbildern die fertigen Guide-Bildkarten.

    python3 tools/cards/build-cards.py                    # alle Karten
    python3 tools/cards/build-cards.py --only social-scramble
    python3 tools/cards/build-cards.py --nur-html         # nur die HTML, kein Render

Weg eines Bildes:

    ../TournaQ Bilder/<datei>.png          Quelle, ausserhalb des Repos
      -> tools/cards/build/<slug>.html     eine Seite, verlinkt auf card.css
      -> tools/cards/build/<slug>.png      Chrome headless, exakt 1600x1000
      -> assets/cards/<slug>-{480,960,1600}.webp

Die Texte stehen in cards.json, nicht in der HTML. Das ist der Unterschied zur
Vorlage in "CHOK DEE Kampagne": dort steht der Text inline in jeder Slide, und
damit gibt es keinen Rueckweg aus dem Review.
"""

import base64
import html
import json
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HIER = Path(__file__).resolve().parent
WURZEL = HIER.parent.parent
BUILD = HIER / "build"
TEIL = HIER / "assets"
ZIEL = WURZEL / "assets" / "cards"
DATEN = HIER / "cards.json"
CSS = HIER / "card.css"

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

BREITE, HOEHE = 1600, 1000
DERIVATE = [480, 960, 1600]
WEBP_Q = 82

# Quelle des Logos. Die Datei hat echtes Alpha; brand/tournaq-logo-land-450.webp
# taugt nicht, die hat einen weissen Hintergrund und ein cremeweisses "T".
LOGO_QUELLE = WURZEL / "assets" / "tournaq_logo_transparent_land.png"
LOGO_ALPHA = 8      # darunter ist nur noch Streulicht des Glows
LOGO_BREITE = 900


# ── Bausteine, die nur einmal entstehen ──────────────────────────────────

def lockup():
    """Logo auf seine Bounding-Box beschneiden. Gemessen: bei Schwelle 8 bleibt
    die Box ueber alle Schwellwerte bis 250 stabil, es faellt also nur Halo weg."""
    ziel = TEIL / "lockup.png"
    if ziel.exists():
        return ziel
    if not LOGO_QUELLE.exists():
        sys.exit(f"FEHLER: Logo-Quelle fehlt: {LOGO_QUELLE}")

    im = Image.open(LOGO_QUELLE).convert("RGBA")
    a = np.asarray(im)[:, :, 3]
    ys, xs = np.where(a > LOGO_ALPHA)
    if not len(xs):
        sys.exit("FEHLER: Logo-Quelle hat keine sichtbaren Pixel.")
    kasten = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
    im = im.crop(kasten)
    h = round(im.height * LOGO_BREITE / im.width)
    im.resize((LOGO_BREITE, h), Image.LANCZOS).save(ziel)
    print(f"  erzeugt: assets/lockup.png  ({LOGO_BREITE}x{h}, aus {kasten})")
    return ziel


def korn():
    """Rauschen in Kartengroesse. Wird als overlay bei 10% gelegt und haelt die
    Verlaeufe von Streifenbildung frei."""
    ziel = TEIL / f"korn-{BREITE}.png"
    if ziel.exists():
        return ziel
    rng = np.random.default_rng(7)   # fest, damit ein Neubau nichts veraendert
    a = rng.normal(128, 26, (HOEHE, BREITE, 3)).clip(0, 255).astype("uint8")
    Image.fromarray(a).save(ziel)
    print(f"  erzeugt: assets/korn-{BREITE}.png")
    return ziel


# ── Eine Karte ───────────────────────────────────────────────────────────

def text(s):
    """Zeilenumbrueche aus cards.json werden zu <br>, alles andere escaped."""
    return "<br>".join(html.escape(t) for t in str(s).split("\n"))


def seite(k, quelle, logo, rauschen):
    """quelle ist None, wenn die Karte ein Platzhalter ist."""
    foto = k.get("foto", {})
    iris = k.get("iris", {})
    stil = ";".join(f"--iris-{n}:{iris[n]}" for n in ("x", "y", "b", "h") if n in iris)
    fotostil = ";".join(
        f"--foto-{n}:{foto[n]}" for n in ("x", "y", "zoom") if n in foto)

    grund = ('<div class="platz"></div>' if quelle is None else
             f'<div class="foto"><img src="{quelle.as_uri()}" alt="" '
             f'style="{fotostil}"></div>')

    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<link rel="stylesheet" href="../card.css"></head>
<body>
<div class="karte" style="{stil}">
  {grund}
  <div class="scrim {k.get('scrim', 'unten')}"></div>
  <div class="iris {k.get('iris_stil', '')}"></div>
  <div class="korn"><img src="{rauschen.as_uri()}" alt=""></div>
  <img class="logo" src="{logo.as_uri()}" alt="">
</div></body></html>
"""


def rendern(html_datei, png, platzhalter=False):
    subprocess.run(
        [CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
         "--force-device-scale-factor=1", f"--window-size={BREITE},{HOEHE}",
         f"--screenshot={png}", html_datei.as_uri()],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)

    if not png.exists():
        sys.exit(f"FEHLER: Chrome hat kein PNG geschrieben fuer {png.stem}.")

    with Image.open(png) as im:
        if im.size != (BREITE, HOEHE):
            sys.exit(f"FEHLER: {png.name} ist {im.size[0]}x{im.size[1]}, "
                     f"erwartet {BREITE}x{HOEHE}.")
        streuung = float(np.asarray(im.convert("L")).std())

    # Eine Karte, die durchgehend gleich hell ist, hat kein Foto oder kein CSS
    # geladen. Chrome meldet so etwas nicht - es rendert still eine leere Seite.
    if streuung < 12 and not platzhalter:
        sys.exit(f"FEHLER: {png.name} ist praktisch einfarbig (Streuung "
                 f"{streuung:.1f}). Foto oder card.css wurden nicht geladen.\n"
                 f"       Pruefen: open {html_datei}")


def derivate(png, slug):
    with Image.open(png) as im:
        im = im.convert("RGB")
        for b in DERIVATE:
            h = round(im.height * b / im.width)
            aus = ZIEL / f"{slug}-{b}.webp"
            (im if b == im.width else im.resize((b, h), Image.LANCZOS)).save(
                aus, "WEBP", quality=WEBP_Q, method=6)
            print(f"    assets/cards/{aus.name}  ({b}x{h}, "
                  f"{aus.stat().st_size // 1024} kB)")


def pruefe(karten):
    """Zwei Karten, die dasselbe sagen oder aufs selbe zeigen, sind ein Fehler
    in cards.json - keiner, den man am fertigen Bild sehen soll.

    Genau das ist passiert: DogHouse.png und Royal Shuffle.png wurden beide
    der Guide-Seite m-doghouse zugeordnet, und der Kartentitel kam aus dem
    Titel dieser Seite. Damit trugen zwei verschiedene Motive denselben Namen,
    und gemerkt habe ich es erst am Kontaktbogen. Der Titel muss zum Bild
    passen, nicht zum Linkziel."""
    schlecht = []
    for feld, wie in (("ziel", "zeigen auf dasselbe Ziel"),
                      ("titel", "tragen denselben Titel")):
        gesehen = {}
        for k in karten:
            gesehen.setdefault(k.get(feld), []).append(k["slug"])
        for wert, slugs in gesehen.items():
            if wert and len(slugs) > 1:
                schlecht.append(f"  {', '.join(slugs)} {wie}: {wert!r}")
    if schlecht:
        sys.exit("FEHLER in cards.json:\n" + "\n".join(schlecht)
                 + "\n\nZwei Karten duerfen weder denselben Titel tragen noch "
                   "auf dieselbe\nSeite zeigen. Entweder eine Karte entfernen "
                   "oder Titel und Ziel trennen.")


# ── Ablauf ───────────────────────────────────────────────────────────────

def main():
    argv = sys.argv[1:]
    nur_html = "--nur-html" in argv
    if nur_html:
        argv.remove("--nur-html")
    nur = None
    if "--only" in argv:
        i = argv.index("--only")
        if i + 1 >= len(argv):
            sys.exit("FEHLER: --only braucht einen Slug.")
        nur = argv[i + 1]

    if not CSS.exists() or ".karte" not in CSS.read_text(encoding="utf8"):
        sys.exit(f"FEHLER: {CSS} fehlt oder enthaelt keine .karte-Regel.")
    if not nur_html and not Path(CHROME).exists():
        sys.exit(f"FEHLER: Google Chrome nicht gefunden unter {CHROME}")

    daten = json.loads(DATEN.read_text(encoding="utf8"))
    pruefe(daten["karten"])
    quellordner = (WURZEL / daten["quelle"]).resolve()
    karten = [k for k in daten["karten"] if not nur or k["slug"] == nur]
    if not karten:
        sys.exit(f"FEHLER: kein Eintrag mit slug {nur!r} in cards.json.")

    for p in (BUILD, TEIL, ZIEL):
        p.mkdir(parents=True, exist_ok=True)

    logo = lockup()
    rauschen = korn()

    for k in karten:
        if k.get("platzhalter"):
            quelle = None
        else:
            quelle = quellordner / k["bild"]
            if not quelle.exists():
                sys.exit(f"FEHLER: Quellbild fehlt: {quelle}")

        print(k["slug"])
        h = BUILD / f"{k['slug']}.html"
        h.write_text(seite(k, quelle, logo, rauschen), encoding="utf8")
        if nur_html:
            print(f"    {h.relative_to(WURZEL)}")
            continue

        png = BUILD / f"{k['slug']}.png"
        rendern(h, png, bool(k.get('platzhalter')))
        print(f"    build/{png.name}  ({BREITE}x{HOEHE})")
        derivate(png, k["slug"])

    if not nur_html:
        print(f"\n{len(karten)} Karte(n) fertig. Weiter mit:"
              f"\n  python3 tools/cards/build-card-review.py")


if __name__ == "__main__":
    main()
