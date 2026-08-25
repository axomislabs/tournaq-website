#!/usr/bin/env python3
"""Baut drafts/card-review.html - eine einzige Datei zum Durchgehen der Karten.

    python3 tools/cards/build-card-review.py
    open drafts/card-review.html

Alles steckt in der Datei: Bilder als base64, CSS und JS inline. Kein Server,
kein Netz - Doppelklick aus dem Finder genuegt. Kommentare liegen im
localStorage des Browsers und ueberleben einen Neubau der Datei, weil der
Schluessel der Slug ist und nicht die Position im Stapel.

Rueckweg: CSV laden, in die Zwischenablage kopieren oder per Mail schicken.
Die CSV ist der vollstaendige Weg - sie laesst sich mit apply-card-review.py
zurueck in cards.json spielen.
"""

import base64
import html
import io
import json
import sys
from datetime import datetime
from pathlib import Path

from PIL import Image

HIER = Path(__file__).resolve().parent
WURZEL = HIER.parent.parent
BUILD = HIER / "build"
DATEN = HIER / "cards.json"
ZIEL = WURZEL / "drafts" / "card-review.html"

VORSCHAU_BREITE = 720
QUALITAET = 78
EMPFAENGER = "martin@axomislabs.com"
FORM_ENDPOINT = ""      # leer = alles bleibt auf dem Geraet

STATUS = [("ok", "OK"), ("nachbessern", "Überarbeiten"), ("weg", "Verwerfen")]


def datauri(pfad, breite=VORSCHAU_BREITE):
    with Image.open(pfad) as im:
        im = im.convert("RGB")
        h = round(im.height * breite / im.width)
        im = im.resize((breite, h), Image.LANCZOS)
        puffer = io.BytesIO()
        im.save(puffer, "JPEG", quality=QUALITAET, optimize=True)
    return "data:image/jpeg;base64," + base64.b64encode(puffer.getvalue()).decode()


CSS = """
:root{
  --olive:#556B2F; --gold:#F0D47A; --gold-dark:#A97800;
  --bg:#14160E; --flaeche:#1D2015; --linie:#333726;
  --text:#E8EEDC; --grau:#9AA189; --rot:#E0616B;
  --olive-dark:#3A3E16; --border:#333726; --radius:12px;
}
*{margin:0;padding:0;box-sizing:border-box}
html{scroll-behavior:smooth;scroll-padding-top:20px}
body{
  background:var(--bg);color:var(--text);
  font:15px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;
  padding:0 20px 120px;
}
.huelle{max-width:1180px;margin:0 auto}

header{padding:38px 0 26px;border-bottom:1px solid var(--linie);margin-bottom:30px}
h1{font-size:27px;font-weight:800;letter-spacing:-.01em}
.stand{color:var(--grau);font-size:13px;margin-top:6px}
.hinw{
  margin-top:20px;padding:14px 18px;border:1px solid var(--linie);
  border-left:3px solid var(--gold-dark);border-radius:8px;
  background:var(--flaeche);font-size:13.5px;line-height:1.65;color:var(--grau);
}
.hinw b{color:var(--text);font-weight:650}

.karte{
  border:1px solid var(--linie);border-radius:12px;background:var(--flaeche);
  padding:18px;margin-bottom:20px;
  display:grid;grid-template-columns:minmax(0,560px) minmax(0,1fr);gap:22px;
  align-items:start;
}
.karte.ist-ok{border-left:3px solid #4E8F5C}
.karte.ist-nachbessern{border-left:3px solid var(--gold-dark)}
.karte.ist-weg{border-left:3px solid #6B3238;opacity:.72}

.bild{position:relative}
.bild .tq-card{border-color:var(--linie);cursor:zoom-in}
.bild .tq-card img{border-radius:0}
.slug{
  font:600 11px/1 ui-monospace,SFMono-Regular,Menlo,monospace;
  letter-spacing:.06em;color:var(--grau);margin-top:9px;
}
.slug .ziel{color:var(--gold-dark)}

.felder{display:flex;flex-direction:column;gap:13px;min-width:0}
label{display:block;font-size:11px;font-weight:700;letter-spacing:.09em;
  text-transform:uppercase;color:var(--grau);margin-bottom:5px}
input,textarea{
  width:100%;background:#12140D;color:var(--text);
  border:1px solid var(--linie);border-radius:7px;padding:9px 11px;
  font:inherit;font-size:14px;resize:vertical;
}
input:focus,textarea:focus{outline:none;border-color:var(--olive)}
input.geaendert,textarea.geaendert{border-left:3px solid var(--gold)}
textarea{min-height:76px}

.kom-zeile{position:relative}
.kom-zeile textarea{padding-right:56px}
.mic{
  position:absolute;right:9px;bottom:9px;
  width:38px;height:38px;border-radius:9px;
  border:1px solid var(--linie);background:#12140D;color:var(--text);
  font-size:17px;line-height:1;cursor:pointer;
}
.mic:hover{border-color:var(--olive)}
.mic.laeuft{background:#3E1519;border-color:var(--rot);animation:puls 1.1s infinite}
@keyframes puls{50%{opacity:.55}}

.merk{
  margin-top:2px;padding:10px 13px;border-radius:7px;
  border:1px solid #4A3A12;background:#26200E;
  font-size:12.5px;line-height:1.55;color:var(--gold);
}
.merk b{font-weight:700}

.pillen{display:flex;gap:8px;flex-wrap:wrap}
.pille{
  border:1px solid var(--linie);border-radius:999px;background:transparent;
  color:var(--grau);font:600 12px/1 inherit;letter-spacing:.05em;
  padding:9px 16px;cursor:pointer;
}
.pille:hover{border-color:var(--olive);color:var(--text)}
.pille.an[data-s="ok"]{background:#16301C;border-color:#4E8F5C;color:#8FD3A0}
.pille.an[data-s="nachbessern"]{background:#2C2510;border-color:var(--gold-dark);color:var(--gold)}
.pille.an[data-s="weg"]{background:#2E1417;border-color:#6B3238;color:var(--rot)}

footer{
  position:fixed;left:0;right:0;bottom:0;z-index:50;
  background:#1B1E13;border-top:1px solid var(--linie);
  padding:12px 20px;display:flex;align-items:center;gap:10px;
  box-shadow:0 -6px 24px rgba(0,0,0,.4);
}
.f-zahl{flex:1;font-size:13px;color:var(--grau)}
.f-zahl b{color:var(--text)}
footer button{
  border:1px solid var(--linie);border-radius:8px;background:transparent;
  color:var(--text);font:600 13px/1 inherit;padding:11px 16px;cursor:pointer;
}
footer button:hover{border-color:var(--olive)}
footer button.haupt{background:var(--olive);border-color:var(--olive);color:#fff}
footer button.still{color:var(--grau)}
footer button.still:hover{border-color:#6B3238;color:var(--rot)}

#lupe{
  position:fixed;inset:0;z-index:100;display:none;
  background:#000000ee;padding:24px;cursor:zoom-out;
  align-items:center;justify-content:center;
}
#lupe.auf{display:flex}
#lupe img{max-width:100%;max-height:100%;object-fit:contain}

@media (max-width:900px){
  .karte{grid-template-columns:1fr}
  footer button .lang{display:none}
}
@media (min-width:901px){
  footer button .kurz{display:none}
}
"""

JS = """
var SP='tq-card-review-v1';
var daten={};
try{daten=JSON.parse(localStorage.getItem(SP)||'{}')||{}}catch(e){daten={}}

function zustand(slug){
  if(!daten[slug])daten[slug]={};
  return daten[slug];
}
function sichern(){
  try{localStorage.setItem(SP,JSON.stringify(daten))}catch(e){}
  zaehlen();
}
function zaehlen(){
  var n=0;
  GESAMT.forEach(function(k){
    var s=daten[k.slug];
    if(s&&(s.status||s.kommentar||s.titel!=null||s.sub!=null||s.kurz!=null))n++;
  });
  document.getElementById('fzahl').innerHTML=
    '<b>'+n+'</b> von '+GESAMT.length+' Karten bearbeitet';
}

/* Textfelder: nur speichern, was vom Original abweicht. Ein unveraendertes
   Feld gehoert nicht in die CSV, sonst ertrinkt die Aenderung im Rauschen. */
document.addEventListener('input',function(e){
  var el=e.target;
  if(!el.dataset.feld)return;
  var s=zustand(el.dataset.slug);
  var neu=el.value;
  if(neu===el.dataset.orig){delete s[el.dataset.feld];el.classList.remove('geaendert')}
  else{s[el.dataset.feld]=neu;el.classList.add('geaendert')}
  if(!Object.keys(s).length)delete daten[el.dataset.slug];
  sichern();
});

document.addEventListener('click',function(e){
  var p=e.target.closest('.pille');
  if(p){
    var slug=p.dataset.slug,wert=p.dataset.s;
    var s=zustand(slug);
    if(s.status===wert)delete s.status; else s.status=wert;
    if(!Object.keys(s).length)delete daten[slug];
    malen(slug);
    sichern();
    return;
  }
  if(e.target.matches('.bild .tq-card img')){
    var l=document.getElementById('lupe');
    l.querySelector('img').src=e.target.dataset.gross||e.target.src;
    l.classList.add('auf');
    return;
  }
  if(e.target.closest('#lupe'))document.getElementById('lupe').classList.remove('auf');
});
document.addEventListener('keydown',function(e){
  if(e.key==='Escape')document.getElementById('lupe').classList.remove('auf');
});

function malen(slug){
  var s=daten[slug]||{};
  var box=document.getElementById('k-'+slug);
  box.className='karte'+(s.status?' ist-'+s.status:'');
  box.querySelectorAll('.pille').forEach(function(p){
    p.classList.toggle('an',p.dataset.s===s.status);
  });
}

/* ---------- Zusammenstellen ---------- */
function zeilen(){
  var out=[];
  GESAMT.forEach(function(k){
    var s=daten[k.slug];
    if(!s)return;
    if(!s.status&&!s.kommentar&&s.titel==null&&s.sub==null&&s.kurz==null)return;
    out.push({
      slug:k.slug,
      status:s.status||'',
      titel:s.titel!=null?s.titel:'',
      sub:s.sub!=null?s.sub:'',
      kurz:s.kurz!=null?s.kurz:'',
      kommentar:s.kommentar||''
    });
  });
  return out;
}
function heute(){return new Date().toISOString().slice(0,10)}

function alsText(){
  var z=zeilen();
  if(!z.length)return '';
  var out='FEEDBACK TOURNAQ KARTEN - '+heute()+'\\n';
  z.forEach(function(r){
    out+='\\n'+r.slug+(r.status?'  ['+r.status.toUpperCase()+']':'')+'\\n';
    if(r.titel)out+='  Titel neu: '+r.titel+'\\n';
    if(r.sub)  out+='  Sub neu:   '+r.sub.replace(/\\n/g,' / ')+'\\n';
    if(r.kurz) out+='  Kurz neu:  '+r.kurz+'\\n';
    if(r.kommentar)out+='  '+r.kommentar.replace(/\\n/g,'\\n  ')+'\\n';
  });
  return out;
}

function csvFeld(s){return '"'+String(s==null?'':s).replace(/"/g,'""')+'"'}

document.getElementById('csv').onclick=function(){
  var z=zeilen();
  if(!z.length){alert('Noch nichts bewertet oder kommentiert.');return}
  var stempel=new Date().toISOString().slice(0,16).replace('T',' ');
  var kopf=['Slug','Status','Titel','Sub','Kurz','Kommentar','Zeitstempel'];
  var csv='\\uFEFF'+[kopf.join(';')].concat(z.map(function(r){
    return [r.slug,r.status,r.titel,r.sub,r.kurz,r.kommentar,stempel]
      .map(csvFeld).join(';');
  })).join('\\r\\n');
  var a=document.createElement('a');
  a.href=URL.createObjectURL(new Blob([csv],{type:'text/csv;charset=utf-8'}));
  a.download='tournaq-karten-'+heute()+'.csv';
  a.click();
  setTimeout(function(){URL.revokeObjectURL(a.href)},1000);
  if(ENDPOINT)senden(z);
};

document.getElementById('kopieren').onclick=function(){
  var t=alsText();
  if(!t){alert('Noch nichts bewertet oder kommentiert.');return}
  /* navigator.clipboard gibt es unter file:// nicht - das ist hier der
     Normalfall, nicht der Randfall. Der prompt() ist der eigentliche Weg. */
  if(navigator.clipboard&&window.isSecureContext){
    navigator.clipboard.writeText(t).then(function(){
      alert('Feedback in der Zwischenablage.');
    },function(){prompt('Kopieren mit Cmd+C:',t)});
  }else{
    prompt('Kopieren mit Cmd+C:',t);
  }
};

document.getElementById('mail').onclick=function(){
  var t=alsText();
  if(!t){alert('Noch nichts bewertet oder kommentiert.');return}
  /* Bei 1800 Zeichen gekuerzt: encodeURIComponent blaeht Umbrueche und
     Umlaute auf das Drei- bis Sechsfache, und mailto: hat je nach Client
     eine harte Grenze. Der vollstaendige Stand steht in der CSV. */
  var kurz=t.length>1800?t.slice(0,1800)+'\\n\\n[gekuerzt - vollstaendig in der CSV]':t;
  location.href='mailto:'+EMPFAENGER
    +'?subject='+encodeURIComponent('Feedback TournaQ Karten - '+heute())
    +'&body='+encodeURIComponent(kurz);
};

document.getElementById('reset').onclick=function(){
  if(!confirm('Alle Bewertungen und Kommentare loeschen? Das laesst sich nicht rueckgaengig machen.'))return;
  daten={};
  try{localStorage.removeItem(SP)}catch(e){}
  document.querySelectorAll('[data-feld]').forEach(function(el){
    el.value=el.dataset.orig;
    el.classList.remove('geaendert');
  });
  GESAMT.forEach(function(k){malen(k.slug)});
  zaehlen();
};

function senden(z){
  fetch(ENDPOINT,{method:'POST',headers:{'Content-Type':'application/json'},
    body:JSON.stringify({datum:heute(),karten:z})}).catch(function(){});
}

/* ---------- Diktat ----------
   webkitSpeechRecognition braucht einen sicheren Kontext UND Netz. Per
   Doppelklick aus dem Finder ist die Seite file:// und damit unsicher - dann
   gibt es keinen stillen Fehlschlag, sondern den Hinweis auf die zwei Wege,
   die wirklich funktionieren. */
var Erk = window.SpeechRecognition || window.webkitSpeechRecognition;
var laeuft = null;

function diktatMoeglich(){ return !!Erk && window.isSecureContext; }

document.addEventListener('click', function(e){
  var m = e.target.closest('.mic');
  if(!m) return;
  var ta = m.parentElement.querySelector('textarea');

  if(!diktatMoeglich()){
    alert('Diktat über die Seite geht hier nicht.\\n\\n'
      + 'Der Browser gibt das Mikrofon nur über eine sichere Verbindung frei, '
      + 'und eine per Doppelklick geöffnete Datei ist keine.\\n\\n'
      + 'Zwei Wege, die funktionieren:\\n\\n'
      + '1. macOS-Diktat — ins Kommentarfeld klicken und die Diktat-Taste drücken '
      + '(je nach Einstellung zweimal Fn oder zweimal Control). Das läuft in jedem '
      + 'Textfeld und braucht diese Seite gar nicht.\\n\\n'
      + '2. Seite über localhost öffnen — im Projektordner\\n'
      + '   python3 -m http.server 8000\\n'
      + '   dann http://localhost:8000/drafts/card-review.html\\n'
      + '   Dort ist auch der Mikrofonknopf hier aktiv.');
    ta.focus();
    return;
  }

  if(laeuft){                       // laufendes Diktat beenden
    laeuft.stop();
    return;
  }

  var r = new Erk();
  r.lang = 'de-DE';
  r.continuous = true;
  r.interimResults = false;
  r.onresult = function(ev){
    var neu = '';
    for(var i=ev.resultIndex; i<ev.results.length; i++){
      if(ev.results[i].isFinal) neu += ev.results[i][0].transcript;
    }
    if(!neu.trim()) return;
    ta.value = (ta.value.trim() ? ta.value.replace(/\\s+$/,'') + ' ' : '') + neu.trim();
    /* Von Hand ausloesen, sonst laeuft die Speicherung nicht mit. */
    ta.dispatchEvent(new Event('input', {bubbles:true}));
  };
  r.onerror = function(ev){
    m.classList.remove('laeuft'); laeuft = null;
    if(ev.error === 'not-allowed')
      alert('Der Browser hat das Mikrofon nicht freigegeben. In den Seiteneinstellungen erlauben.');
    else if(ev.error !== 'aborted' && ev.error !== 'no-speech')
      alert('Diktat abgebrochen: ' + ev.error);
  };
  r.onend = function(){ m.classList.remove('laeuft'); laeuft = null; };

  try{
    r.start();
    laeuft = r;
    m.classList.add('laeuft');
    ta.focus();
  }catch(err){
    alert('Diktat liess sich nicht starten: ' + err.message);
  }
});

/* ---------- Gespeicherten Stand zurueckschreiben ---------- */
document.querySelectorAll('[data-feld]').forEach(function(el){
  var s=daten[el.dataset.slug];
  if(s&&s[el.dataset.feld]!=null){
    el.value=s[el.dataset.feld];
    el.classList.add('geaendert');
  }
});
GESAMT.forEach(function(k){malen(k.slug)});
zaehlen();
"""


def cqw(px):
    """px aus cards.json in cqw. Rendermass 1600px, ein cqw sind 16px."""
    return f"{float(str(px).replace('px', '')) / 16:g}cqw"


def textebene(k):
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
    return (";".join(stil),
            f'<div class="tq-card-text"><div class="tq-card-body">{inn}</div></div>')


def bauen():
    if not DATEN.exists():
        sys.exit(f"FEHLER: {DATEN} fehlt.")
    daten = json.loads(DATEN.read_text(encoding="utf8"))
    karten = daten["karten"]

    fehlend = [k["slug"] for k in karten if not (BUILD / f"{k['slug']}.png").exists()]
    if fehlend:
        sys.exit("FEHLER: noch nicht gerendert: " + ", ".join(fehlend)
                 + "\n       Erst: python3 tools/cards/build-cards.py")

    e = html.escape
    T = []
    T.append('<!doctype html><html lang="de"><head><meta charset="utf-8">')
    T.append('<meta name="viewport" content="width=device-width,initial-scale=1">')
    T.append('<meta name="robots" content="noindex,nofollow,noarchive">')
    T.append("<title>TournaQ Karten — Review</title>")
    karten_css = (WURZEL / "css" / "cards.css").read_text(encoding="utf8")
    T.append(f"<style>{karten_css}\n{CSS}</style></head><body><div class='huelle'>")

    T.append("<header><h1>TournaQ Karten — Review</h1>")
    T.append(f"<div class='stand'>{len(karten)} Karte(n) · 1600×1000 · "
             f"gebaut am {datetime.now():%d.%m.%Y, %H:%M}</div>")
    T.append("<div class='hinw'>Pro Karte einen <b>Status</b> setzen und bei Bedarf "
             "kommentieren. Die Textfelder sind mit dem vorbelegt, was gerade im Bild "
             "steht — was du darin änderst, wird als Änderungswunsch mitgeschickt und "
             "lässt sich mit <b>apply-card-review.py</b> direkt zurück in cards.json "
             "spielen. Alles bleibt im Browser, bis du unten exportierst."
             "<br><b>Diktieren:</b> das Mikrofon am Kommentarfeld braucht eine sichere "
             "Verbindung — per Doppelklick geöffnet geht es nicht. Entweder das "
             "<b>macOS-Diktat</b> benutzen (ins Feld klicken, Diktat-Taste drücken), oder "
             "die Seite über <code>python3 -m http.server 8000</code> unter "
             "<code>http://localhost:8000/drafts/card-review.html</code> öffnen — dort "
             "ist der Knopf aktiv.<br>"
             "<b>Ausschnitt oder Bildwirkung ändern?</b> Das geht schneller in der "
             "<a href='card-mockup.html'>Werkbank</a> — dort ohne Render-Durchlauf.</div>")
    T.append("</header>")

    for k in karten:
        slug = k["slug"]
        uri = datauri(BUILD / f"{slug}.png")
        T.append(f"<div class='karte' id='k-{e(slug)}'>")
        tstil, text = textebene(k)
        T.append(f"<div class='bild'><div class='tq-card' style='{tstil}'>"
                 f"<img src='{uri}' alt='{e(k['titel'])}'>{text}</div>"
                 f"<div class='slug'>{e(slug)}"
                 + (f" <span class='ziel'>→ {e(k['ziel'])}</span>" if k.get("ziel") else "")
                 + "</div></div>")

        T.append("<div class='felder'>")
        T.append("<div class='pillen'>" + "".join(
            f"<button class='pille' data-slug='{e(slug)}' data-s='{s}'>{e(lab)}</button>"
            for s, lab in STATUS) + "</div>")

        for feld, lab, mehrzeilig in (("titel", "Titel", False),
                                      ("sub", "Subline", True),
                                      ("kurz", "Kurzfassung · Prinzip-Seite", False)):
            wert = k.get(feld, "")
            gem = (f"<textarea data-slug='{e(slug)}' data-feld='{feld}' "
                   f"data-orig='{e(wert)}' style='min-height:64px'>{e(wert)}</textarea>"
                   if mehrzeilig else
                   f"<input data-slug='{e(slug)}' data-feld='{feld}' "
                   f"data-orig='{e(wert)}' value='{e(wert)}'>")
            T.append(f"<div><label>{lab}</label>{gem}</div>")

        T.append(f"<div><label>Kommentar</label><div class='kom-zeile'>"
                 f"<textarea data-slug='{e(slug)}' data-feld='kommentar' data-orig='' "
                 f"placeholder='Was stört, was fehlt, was soll anders?'></textarea>"
                 f"<button class='mic' title='Diktieren'>&#127908;</button>"
                 f"</div></div>")
        if k.get("hinweis"):
            T.append(f"<div class='merk'><b>Offene Frage:</b> {e(k['hinweis'])}</div>")
        T.append("</div></div>")

    T.append("</div>")
    T.append("<footer><span class='f-zahl' id='fzahl'>Noch nichts bearbeitet</span>"
             "<button id='reset' class='still'><span class='lang'>Zurücksetzen</span>"
             "<span class='kurz'>&#128465;</span></button>"
             "<button id='kopieren'><span class='lang'>Als Text kopieren</span>"
             "<span class='kurz'>&#128203;</span></button>"
             "<button id='csv'><span class='lang'>CSV laden</span>"
             "<span class='kurz'>&#11015;</span></button>"
             "<button id='mail' class='haupt'><span class='lang'>Per E-Mail senden</span>"
             "<span class='kurz'>&#9993;</span></button></footer>")
    T.append("<div id='lupe'><img alt=''></div>")

    # json.dumps statt repr: repr bricht bei Apostroph und Umlaut.
    gesamt = [{"slug": k["slug"]} for k in karten]
    T.append("<script>"
             f"const EMPFAENGER={json.dumps(EMPFAENGER)};"
             f"const ENDPOINT={json.dumps(FORM_ENDPOINT)};"
             f"const GESAMT={json.dumps(gesamt)};"
             f"{JS}</script>")
    T.append("</body></html>")

    ZIEL.parent.mkdir(parents=True, exist_ok=True)
    ZIEL.write_text("\n".join(T), encoding="utf8")
    mb = ZIEL.stat().st_size / 1048576
    print(f"{ZIEL.relative_to(WURZEL)}")
    print(f"  {len(karten)} Karte(n), {mb:.1f} MB")
    if mb > 15:
        print("  WARNUNG: ueber 15 MB. VORSCHAU_BREITE im Skript verkleinern.")
    print(f"  Rueckweg: CSV, Zwischenablage, Mail an {EMPFAENGER}")
    print(f"\n  open {ZIEL.relative_to(WURZEL)}")


if __name__ == "__main__":
    bauen()
