#!/usr/bin/env python3
"""Baut drafts/card-mockup.html - alle Karten live im Browser.

    python3 tools/cards/build-mockup.py
    open drafts/card-mockup.html

Der Sinn: Ausschnitt, Zoom und Scrim einer Karte beurteilen und aendern,
ohne fuer jeden Versuch ein PNG zu rendern. Die Seite zeigt echte
.karte-Boxen, herunterskaliert auf die Groessen, in denen sie im Guide
wirklich stehen.

Die HTML verlinkt card.css, sie bettet sie nicht ein. Am Aussehen schrauben
heisst also: card.css oder cards.json aendern, hier neu laden. Dieses Skript
muss nur laufen, wenn Karten dazukommen oder Texte sich aendern - und
build-cards.py erst, wenn das Ergebnis stimmt.

Vorher standen hier sieben Layoutvarianten zur Auswahl. Entschieden wurde
Variante C, die inzwischen in card.css steht; die Auswahl ist damit erledigt.
"""

import html
import json
import sys
from datetime import datetime
from pathlib import Path

HIER = Path(__file__).resolve().parent
WURZEL = HIER.parent.parent
TEIL = HIER / "assets"
DATEN = HIER / "cards.json"
ZIEL = WURZEL / "drafts" / "card-mockup.html"

CSS = """
:root{--f:0.29;--olive:#556B2F;--olive-dark:#3A3E16;--gold:#F0D47A;--border:#D6E0C2;--radius:14px}
/* ACHTUNG: Diese Stile werden nach card.css geladen. Nackte Element-
   selektoren haben dieselbe Spezifitaet wie die dort - der spaetere gewinnt
   und faerbt die Karten um. Ein blankes h1{} hat hier schon einmal alle
   Kartentitel auf 26px dunkeloliv gesetzt. Alles an eigene Container binden. */
body{
  background:#F9FAF6;color:#1A1A1A;
  font:15px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;
  padding:0 24px 80px;
}
.huelle{max-width:1400px;margin:0 auto}
header{padding:34px 0 22px;border-bottom:1px solid #D6E0C2;margin-bottom:8px}
header h1{font-size:26px;font-weight:800;letter-spacing:-.01em;color:#3A3E16}
.stand{color:#666;font-size:13px;margin-top:5px}
.hinw{
  margin-top:18px;padding:13px 17px;border:1px solid #D6E0C2;
  border-left:3px solid #A97800;border-radius:8px;background:#EEF2E6;
  font-size:13.5px;line-height:1.65;color:#4A4A3E;
}
.hinw b{color:#3A3E16}
.hinw a{color:#556B2F;font-weight:700}
.hinw code{font:600 12.5px ui-monospace,SFMono-Regular,Menlo,monospace;color:#556B2F}

.leiste{
  position:sticky;top:0;z-index:20;background:#F9FAF6;
  padding:14px 0;border-bottom:1px solid #D6E0C2;margin-bottom:26px;
  display:flex;gap:26px;align-items:center;flex-wrap:wrap;
}
.gruppe{display:flex;gap:7px;align-items:center}
.gruppe>span{font-size:11px;font-weight:800;letter-spacing:.09em;
  text-transform:uppercase;color:#8C8C80;margin-right:3px}
button{
  border:1px solid #D6E0C2;border-radius:8px;background:#fff;color:#1A1A1A;
  font:600 13px/1 inherit;padding:9px 14px;cursor:pointer;
}
button:hover{border-color:#556B2F}
button.an{background:#556B2F;border-color:#556B2F;color:#fff}

.variante{margin-bottom:34px;scroll-margin-top:80px}
.kopf{display:flex;gap:14px;align-items:baseline;margin-bottom:4px;flex-wrap:wrap}
.kopf h2{font-size:17px;font-weight:800;color:#3A3E16}
.kopf .klassen{font:600 11.5px ui-monospace,SFMono-Regular,Menlo,monospace;color:#A97800}
.kopf p{font-size:13.5px;color:#666;flex-basis:100%;max-width:74ch;margin-top:2px}

.reihe{display:flex;gap:18px;flex-wrap:wrap;margin-top:14px;align-items:flex-start}
.buehne{
  width:calc(1600px * var(--f));
  height:calc(1000px * var(--f));
  overflow:hidden;flex:none;
  border:1px solid #D6E0C2;border-radius:calc(12px);
  box-shadow:0 1px 4px rgba(0,0,0,.05);
}
.buehne .tq-card{transform:scale(var(--f));transform-origin:0 0;border:none;border-radius:0}
.bu{font-size:11px;color:#8C8C80;margin-top:5px}

.slot{flex:none}
"""

JS = """
function setzeFaktor(f,el){
  document.documentElement.style.setProperty('--f',f);
  document.querySelectorAll('[data-f]').forEach(function(b){b.classList.remove('an')});
  el.classList.add('an');
}
document.querySelectorAll('[data-f]').forEach(function(b){
  b.onclick=function(){setzeFaktor(b.dataset.f,b)};
});
"""


def cqw(px):
    """px aus cards.json in cqw umrechnen. Rendermass war 1600px, ein cqw ist
    ein Prozent der Kartenbreite - also 16px. 108px -> 6.75cqw."""
    return f"{float(str(px).replace('px', '')) / 16:g}cqw"


def textebene(k):
    """Die HTML-Textebene, identisch in Werkbank, Review und Guide."""
    e = html.escape
    stil = []
    if k.get("t-h1"):
        stil.append(f"--tq-t:{cqw(k['t-h1'])}")
    if k.get("t-sub"):
        stil.append(f"--tq-s:{cqw(k['t-sub'])}")
    br = lambda t: "<br>".join(e(z) for z in t.split("\n"))
    inn = f'<span class="tq-t">{br(k["titel"])}</span>'
    if k.get("sub"):
        inn += f'<span class="tq-s">{br(k["sub"])}</span>'
    return ";".join(stil), f'<div class="tq-card-text"><div class="tq-card-body">{inn}</div></div>'


def karte(k, logo, rauschen, quellordner):
    """Live-Bildebenen wie build-cards.py sie rendert, plus die Textebene, die
    auf der Website darueber liegt. Zusammen ergibt das den Endzustand."""
    e = html.escape
    foto, iris = k.get("foto", {}), k.get("iris", {})
    fs = ";".join(f"--foto-{n}:{foto[n]}" for n in ("x", "y", "zoom") if n in foto)
    grund = ('<div class="platz"></div>' if k.get("platzhalter") else
             f'<div class="foto"><img src="{(quellordner / k["bild"]).as_uri()}" '
             f'alt="" style="{fs}"></div>')
    ks = ";".join(f"--iris-{n}:{iris[n]}" for n in ("x", "y", "b", "h") if n in iris)
    tstil, text = textebene(k)
    if tstil:
        ks = ";".join(x for x in (ks, tstil) if x)

    return (
        f'<div class="tq-card" style="width:1600px;{ks}">'
        f'<div class="karte">'
        f'{grund}'
        f'<div class="scrim {k.get("scrim", "unten")}"></div>'
        f'<div class="iris {k.get("iris_stil", "")}"></div>'
        f'<div class="korn"><img src="{rauschen.as_uri()}" alt=""></div>'
        f'<img class="logo" src="{logo.as_uri()}" alt="">'
        f'</div>{text}</div>')


def bauen():
    logo = TEIL / "lockup.png"
    rauschen = TEIL / "korn-1600.png"
    for p in (logo, rauschen):
        if not p.exists():
            sys.exit(f"FEHLER: {p} fehlt. Erst einmal build-cards.py laufen lassen.")

    daten = json.loads(DATEN.read_text(encoding="utf8"))
    quellordner = (WURZEL / daten["quelle"]).resolve()
    karten = daten["karten"]
    fehlend = [k["bild"] for k in karten
               if not k.get("platzhalter") and not (quellordner / k["bild"]).exists()]
    if fehlend:
        sys.exit("FEHLER: Quellbilder fehlen: " + ", ".join(fehlend))

    e = html.escape
    T = ['<!doctype html><html lang="de"><head><meta charset="utf-8">',
         '<meta name="viewport" content="width=device-width,initial-scale=1">',
         '<meta name="robots" content="noindex,nofollow,noarchive">',
         "<title>TournaQ Karten — Werkbank</title>",
         '<link rel="stylesheet" href="../tools/cards/card.css">',
         '<link rel="stylesheet" href="../css/cards.css">',
         f"<style>{CSS}</style></head><body><div class='huelle'>"]

    T.append("<header><h1>Kartenwerkbank</h1>")
    T.append(f"<div class='stand'>{len(karten)} Karten · "
             f"gebaut am {datetime.now():%d.%m.%Y, %H:%M}</div>")
    T.append("<div class='hinw'>Das sind <b>echte Karten im Browser</b>, nicht "
             "gerenderte Bilder — herunterskaliert auf die Groesse, in der sie im "
             "Guide wirklich stehen. <b>460 px</b> ist die Breite bei zwei Karten "
             "nebeneinander, <b>890 px</b> wenn eine Karte allein in der Zeile steht, "
             "<b>1600 px</b> die Ausgabegroesse.<br>"
             "Zum Schrauben: <code>tools/cards/cards.json</code> (Ausschnitt, Zoom, "
             "Scrim, Texte) oder <code>tools/cards/card.css</code> aendern und hier "
             "neu laden. Erst wenn es stimmt, <code>build-cards.py</code> laufen "
             "lassen — dieses Skript nur, wenn Karten dazukommen.<br>"
             "<b>Kommentieren geht hier nicht</b> — dafür ist "
             "<a href='card-review.html'>card-review.html</a> da.</div>")
    T.append("</header>")

    T.append("<div class='leiste'><div class='gruppe'><span>Groesse</span>"
             "<button data-f='0.29' class='an'>460 px</button>"
             "<button data-f='0.556'>890 px</button>"
             "<button data-f='1'>1600 px</button></div></div>")

    T.append("<div class='reihe'>")
    for k in karten:
        T.append(f"<div class='slot zeigen'><div class='buehne'>"
                 + karte(k, logo, rauschen, quellordner)
                 + f"</div><div class='bu'><b>{e(k['slug'])}</b> → {e(k.get('ziel',''))}"
                 f" · scrim={e(k.get('scrim','unten'))}"
                 f" · zoom={e(str(k.get('foto',{}).get('zoom','1.0')))}"
                 + (" · <b>PLATZHALTER</b>" if k.get("platzhalter") else "")
                 + "</div></div>")
    T.append("</div>")

    T.append("</div>")
    T.append(f"<script>{JS}</script></body></html>")

    ZIEL.parent.mkdir(parents=True, exist_ok=True)
    ZIEL.write_text("\n".join(T), encoding="utf8")
    print(f"{ZIEL.relative_to(WURZEL)}")
    print(f"  {len(karten)} Karten, {ZIEL.stat().st_size // 1024} kB")
    print(f"\n  open {ZIEL.relative_to(WURZEL)}")


if __name__ == "__main__":
    bauen()
