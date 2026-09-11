#!/usr/bin/env python3
"""Bake the install QR codes for the beta section on the downloads page.

Both test programmes are a two-step install, and both steps are a link that
only helps on a phone — while the person reading the page is usually sitting
at a laptop. A QR code per step is the bridge, so the four codes here are
exactly the four buttons in pages/downloads.html.

The codes are committed as SVG rather than fetched from a QR service at page
load: the destinations change about once a year, an external image request on
every visit is a tracker we would have to declare, and a service that goes
away would silently break the only install route the app currently has.

    python3 -m pip install segno
    python3 tools/bake-qr.py

Rebuild whenever a destination below changes, and re-check the printed URL
against the href in pages/downloads.html — a QR code that points at the wrong
page is indistinguishable from a correct one until somebody scans it.
"""
import os
import sys

try:
    import segno
except ImportError:
    sys.exit("segno is missing — python3 -m pip install segno")

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, "assets", "qr")

# Der dunkle Ton ist das Olive der Marke, nicht Schwarz — bei dieser Helligkeit
# (Luminanz ~0.04) scannt es wie Schwarz, sieht aber nicht nach Fremdkoerper aus.
DARK = "#3A3E16"
LIGHT = "#ffffff"

# Fehlerkorrektur M und Ruhezone 4 sind die Vorgabe der Norm. Beides bewusst
# nicht gesenkt: die SVGs sind auch die Vorlage fuer gedruckte Aushaenge, und
# dort ist der Rand das, was zuerst fehlt.
TARGETS = {
    "ios-testflight": "https://apps.apple.com/app/testflight/id899247664",
    "ios-app": "https://testflight.apple.com/join/uFzz7vd9",
    "android-group": "https://groups.google.com/g/tournaq-testing",
    "android-app": "https://play.google.com/store/apps/details?id=com.martinadam.tournaq",
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, url in TARGETS.items():
        qr = segno.make(url, error="m", mode="byte")
        path = os.path.join(OUT, name + ".svg")
        # omitsize: nur eine viewBox, keine Pixelmasse — die Groesse gehoert
        # ins CSS, damit derselbe Code auf der Karte und im Ausdruck passt.
        qr.save(path, kind="svg", dark=DARK, light=LIGHT, border=4,
                omitsize=True, xmldecl=False, svgns=True, nl=False)
        print("%-16s v%-3s %s" % (name + ".svg", qr.version, url))


if __name__ == "__main__":
    main()
