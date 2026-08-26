/* Der Renderer des User Guide — nur Zeichenketten, kein DOM.

   Herausgeloest aus pages/guide.html. Jede Funktion hier gibt HTML als Zeichenkette
   zurueck. Das ist die Bedingung dafuer, dass tools/bake-guide.mjs dieselben
   Funktionen unter Node aufrufen kann wie der Browser — sonst gaebe es zwei
   Renderer und damit zwei Wahrheiten.
*/

/* Wo eine Seite liegt, bestimmt ihre Pfade: die Fassung unter pages/ zeigt
   mit ../ auf die Wurzel, eine gebackene Seite in beliebiger Tiefe mit / .
   Und wie eine Zeile im Rail verlinkt, haengt daran, ob ihr Ziel eine eigene
   Datei hat oder eine Hash-Route auf derselben bleibt. Beides setzt der
   Aufrufer, damit Browser und Backskript denselben Renderer teilen. */
let G_BASIS   = '../';
let G_LINK    = id => '#/' + (id === 'home' ? '' : id);
let G_NACHBAR = '';   // Praefix vor den Website-Seiten aus EXTERN

function setzeKontext(o = {}){
  if (o.basis   !== undefined) G_BASIS   = o.basis;
  if (o.link    !== undefined) G_LINK    = o.link;
  if (o.nachbar !== undefined) G_NACHBAR = o.nachbar;
}

/* Wohin eine Zeile des Rails zeigt: ein Guide-Knoten ueber G_LINK — der
   entscheidet, ob es eine eigene Datei oder eine Hash-Route wird —, eine
   Website-Seite ueber ihre eigene Adresse. */
function navZiel(id){
  return EXTERN[id] ? G_NACHBAR + EXTERN[id].url : href(id);
}

/* ══ Rendering ═══════════════════════════════════════════════════════════
   Blocks render as <div>, never <section>: css/style.css puts 56px of margin
   under every <section>, which would tear the stack apart.
   ══════════════════════════════════════════════════════════════════════════ */

/* Draft notes are addressed to whoever is writing the guide, not to whoever
   is reading it, so they stay out of the published page. Flip this to true to
   read them in place while editing. */
const SHOW_DRAFT_NOTES = false;

/* Aus den Mode-Seiten der Website migrierter Text wartet in `inbox` neben
   `blocks` auf seine Durchsicht — hinter dem fertigen Inhalt der Seite, mit
   einem `sect` davor, das seine Quelle nennt. Auf false steht der Guide
   wieder exakt so da, wie er ohne die Migration staende. */
const SHOW_INBOX = true;

/* Wie ein shot-Block sitzt: false stapelt Bild ueber Bildunterschrift,
   true stellt sie nebeneinander wie auf den Modus-Seiten der Website. */
const SHOT_SIDE = false;

const ic = (n, cls='g-ic') => '<svg class="' + cls + '" aria-hidden="true"><use href="#' + n + '"/></svg>';
const href = id => G_LINK(id);

function renderPanelItems(items){
  let out = '';
  items.forEach((it, i) => {
    if (it.k === 'split'){
      out += '<div class="g-split"><div class="g-split-gutter">' +
        '<div class="g-split-stub"></div><div class="g-split-dot"></div><div class="g-split-stub"></div>' +
        '</div><div class="g-split-label">' + it.label + '</div></div>';
      return;
    }
    /* Zwei Straenge nebeneinander. Der Rumpf jedes Arms geht durch dieselbe
       Funktion, damit eine Karte drinnen aussieht wie eine draussen. */
    if (it.k === 'fork'){
      const arm = a => '<div class="g-fork-arm">' +
        '<div class="g-fork-head"><span class="g-fork-dot"></span>' + a.label + '</div>' +
        '<div class="g-fork-body">' + renderPanelItems(a.items) + '</div>' +
      '</div>';
      out += '<div class="g-fork">' + arm(it.a) + arm(it.b) + '</div>';
      return;
    }

    const cardCls = 'g-card' + (it.tone === 'tint' ? ' tint' : '');
    const body = '<span class="g-disc">' + ic(it.icon) + '</span><span class="g-card-txt">' +
      '<span class="g-card-label">' + it.label + (it.chip ? '<span class="g-chip">' + it.chip + '</span>' : '') + '</span>' +
      (it.cap ? '<span class="g-card-cap">' + it.cap + '</span>' : '') + '</span>';

    if (it.k === 'step'){
      const isFirst = i === 0;
      const isLast  = i === items.length - 1;
      out += '<div class="g-rail">' +
        '<div class="g-rail-gutter">' +
          '<div class="g-rail-line' + (isFirst ? ' blank' : '') + '"></div>' +
          '<div class="g-badge">' + it.n + '</div>' +
          '<div class="g-rail-line' + (isLast ? ' blank' : '') + '"></div>' +
        '</div>' +
        '<div class="' + cardCls + '">' + body + '</div>' +
      '</div>';
    } else {
      out += '<div class="' + cardCls + '">' + body + '</div>';
    }
  });
  return out;
}

function renderBlock(b){
  switch(b.t){
    case 'panel':
      return '<div class="g-panel"' + (b.id ? ' id="' + b.id + '"' : '') + '>' +
        '<span class="g-pill">' + b.badge + '</span>' +
        (b.sub ? '<p class="g-panel-sub">' + b.sub + '</p>' : '') +
        /* Ein Panel ohne Eintraege ist die Ueberschrift eines Abschnitts —
           dann faellt der leere Rumpf samt seinem Abstand weg. */
        (b.items && b.items.length
          ? '<div class="g-panel-body">' + renderPanelItems(b.items) + '</div>'
          : '') +
      '</div>';

    case 'fbox':
      return '<div class="g-fbox">' +
        '<div class="g-fbox-head"><span class="g-disc">' + ic(b.icon) + '</span>' +
          '<div><div class="g-fbox-title">' + b.title + '</div>' +
          (b.body ? '<div class="g-fbox-body">' + b.body + '</div>' : '') + '</div></div>' +
        (b.lines && b.lines.length
          ? '<div class="g-fbox-lines">' + b.lines.map(l =>
              '<div class="g-fline">' + ic(l.icon || 'i-check') +
              '<span><b>' + l.title + '</b>' + (l.body ? ' — ' + l.body : '') + '</span></div>').join('') +
            '</div>'
          : '') +
      '</div>';

    /* Screenshot mit Bildunterschrift. Gestapelt oder zweispaltig — das
       entscheidet die Klasse am umgebenden g-stack, nicht der Block, damit
       eine Seite beide Formen nebeneinander zeigen kann. */
    case 'shot': {
      const basis = G_BASIS + 'assets/' + b.src;
      const quer  = b.w > b.h;
      const srcset = b.sizes.map(w => basis + '-' + w + '.webp ' + w + 'w').join(', ');
      return '<figure class="g-shot' + (quer ? ' quer' : '') + '">' +
        '<div class="g-shot-media"><img src="' + basis + '-' + b.sizes[0] + '.webp" ' +
          'srcset="' + srcset + '" ' +
          'sizes="' + (quer ? '(max-width: 760px) 90vw, 420px' : '(max-width: 760px) 62vw, 240px') + '" ' +
          'width="' + b.w + '" height="' + b.h + '" loading="lazy" decoding="async" ' +
          'alt="' + (b.alt || '') + '"></div>' +
        '<figcaption><div class="g-shot-title">' + b.title + '</div>' +
        (b.body ? '<div class="g-shot-body">' + b.body + '</div>' : '') +
        '</figcaption></figure>';
    }

    case 'sect':
      return '<div class="g-sect"><span class="dot">' + ic(b.icon) + '</span><span>' + b.label + '</span></div>';

    case 'note':
      return '<aside class="g-note"><div class="g-note-h">' + ic('i-edit') + b.title + '</div>' +
        '<div class="g-note-b">' + b.body + '</div></aside>';

    case 'grid':
      return '<div class="g-grid">' + b.cards.map(c =>
        '<a class="g-card" href="' + href(c.to) + '">' +
          '<span class="g-disc">' + ic(c.icon) + '</span>' +
          '<span class="g-card-txt"><span class="g-card-label">' + c.label + '</span>' +
          '<span class="g-card-cap">' + c.cap + '</span></span>' +
          '<span class="g-chev">' + ic('i-south') + '</span>' +
        '</a>').join('') + '</div>';

    case 'imgcards':
      /* Der Text liegt als HTML ueber dem Bild, nicht darin — sonst braeuchte
         jede Sprache einen eigenen Bildsatz. Siehe css/cards.css. */
      return '<div class="tq-grid">' + b.cards.map(eintrag => {
        /* Ein Eintrag ist der Kartenname — oder [Kartenname, Etikett], wo ein
           Raster zwei Wettbewerbsfamilien mischt und die Karte allein nicht
           mehr sagt, zu welcher sie gehoert. */
        const slug = Array.isArray(eintrag) ? eintrag[0] : eintrag;
        const tag  = Array.isArray(eintrag) ? eintrag[1] : null;
        const c = CARDS[slug];
        if (!c) return '';
        /* Platzhalter werden hier bewusst mitgezeigt: sie markieren einen
           Modus, dessen Bild noch fehlt. Im Hero bleiben sie aussen vor —
           ein leerer gestrichelter Kasten ueber einer ganzen Seite sagt
           nichts, klein im Raster schon. */
        const p = G_BASIS + 'assets/cards/' + c.img;
        const karte = '<a class="tq-card" href="' + href(c.to) + '"' +
          (c.st ? ' style="' + c.st + '"' : '') + '>' +
          '<img src="' + p + '-480.webp" srcset="' +
            p + '-480.webp 480w, ' + p + '-960.webp 960w, ' + p + '-1600.webp 1600w" ' +
          'sizes="(max-width: 900px) 92vw, 460px" width="1600" height="1000" ' +
          'loading="lazy" decoding="async" alt="">' +
          '<span class="tq-card-text"><span class="tq-card-body">' +
            '<span class="tq-t">' + c.t + '</span>' +
            (c.s ? '<span class="tq-s">' + c.s + '</span>' : '') +
          '</span></span>' +
        '</a>';
        return tag
          ? '<div class="tq-cell"><span class="tq-tag">' + tag + '</span>' +
            karte + '</div>'
          : karte;
      }).join('') + '</div>';

    case 'opts': {
      const cols = b.cols || ['Setting', 'Options', 'Default &amp; range'];
      return '<div class="g-opts">' +
        (b.label ? '<div class="g-opts-head">' + b.label + '</div>' : '') +
        '<div class="g-opts-cols">' +
          cols.map(c => '<span>' + c + '</span>').join('') + '</div>' +
        b.rows.map(r =>
          '<div class="g-opt">' +
            '<div><div class="g-o-name">' + r.name + '</div>' +
              (r.what ? '<div class="g-o-what">' + r.what + '</div>' : '') + '</div>' +
            '<div class="g-o-val"><span class="g-o-k">' + cols[1] + '</span>' + r.values + '</div>' +
            '<div class="g-o-def"><span class="g-o-k">' + cols[2] + '</span>' + r.dflt + '</div>' +
            (r.when ? '<div class="g-o-when">' + ic('i-shield') + '<span>' + r.when + '</span></div>' : '') +
            (r.help ? '<div class="g-o-help">' + ic('i-doc') + '<span>' + r.help + '</span></div>' : '') +
          '</div>').join('') +
      '</div>';
    }

    case 'flow':
      return renderFlow();
  }
  return '';
}

/* The principle map — a spine that forks and merges, drawn in CSS so it
   reflows on a phone the way the Flutter rail does. */
function renderFlow(){
  /* Der Ablauf als kompaktes 3x2-Raster, spaltenweise gelesen:
       Administration    Tournament Hub   Scorecard
       TournaQ Arena     Tournament       Exported Scorecard
     Das macht grid-auto-flow:column — erst die Spalte runter, dann oben in
     der naechsten weiter.

     Was frueher hier stand — die gestrichelte Abkuerzung an Administration
     vorbei, die Gabelung mit "Just a game" und "A session", die
     Verbindungslinien — ist bewusst weg. Quick Game faellt vorerst aus der
     Reihe, solange es dafuer kein Bild gibt.

     Die Texte kommen aus CARDS, also aus cards.json. Frueher standen hier
     eigene Kurzzeilen ("Set it up", "Run it"), die niemand mitpflegt. */
  const SCHRITTE = ['administration', 'arena', 'tournament-hub',
                    'tournament', 'scorecards', 'exported'];

  const sichtbar = SCHRITTE.filter(id => CARD_BY_ZIEL[id] && !CARD_BY_ZIEL[id].ph);

  return '<div class="g-map3">' + sichtbar.map((id, i) => {
    const c = CARD_BY_ZIEL[id];
    const p = G_BASIS + 'assets/cards/' + c.img;
    /* Der Rahmen traegt die Verbindungslinie. Sie kann nicht an der Karte
       selbst haengen — die hat overflow:hidden und wuerde sie abschneiden.
       Gelesen wird spaltenweise: 0,2,4 stehen oben und zeigen nach unten,
       1 und 3 stehen unten und zeigen in die naechste Spalte. Der letzte
       bekommt nichts. Auf dem Handy wird aus beidem ein Pfeil nach unten. */
    const verb = i === sichtbar.length - 1 ? '' : (i % 2 === 0 ? ' g-ab' : ' g-rechts');
    return '<div class="g-step' + verb + '">' +
      (verb ? '<span class="g-verb" aria-hidden="true"></span>' : '') +
      '<a class="tq-card tq-mini" href="' + href(id) + '">' +
      '<img src="' + p + '-480.webp" srcset="' + p + '-480.webp 480w, ' +
        p + '-960.webp 960w" sizes="(max-width: 760px) 92vw, 290px" ' +
      'width="1600" height="1000" loading="lazy" decoding="async" alt="">' +
      '<span class="tq-card-text"><span class="tq-card-body">' +
        '<span class="tq-t">' + c.t + '</span>' +
        /* Die Umbrueche in cards.json sind fuer die grosse Karte gesetzt.
           Hier waeren sie falsch — bei 290px bricht der Satz ohnehin, und
           beides zusammen zerreisst ihn. */
        /* Auf dieser Seite die Kurzfassung: eine Zeile je Karte. Die lange
           Subline aus cards.json gilt ueberall sonst, wo mehr Platz ist. */
        (c.k || c.s
          ? '<span class="tq-s">' + (c.k || c.s.replace(/<br>/g, ' ')) + '</span>'
          : '') +
      '</span></span></a></div>';
  }).join('') + '</div>';
}



function crumbTrail(id){
  const trail = [];
  let cur = id;
  while (cur){ trail.unshift(cur); cur = PAGES[cur].parent; }
  return trail;
}

/* Which subtrees are open. The Arena starts open so the shape of the guide is
   visible on arrival; everything below it stays folded until asked for. The
   branch leading to the current page is always forced open, so navigating can
   never land you on a row you cannot see. */
const NAV_OPEN = new Set(['home', 'arena']);

/* NAV_OPEN merkt sich ueber die Sitzung, welche Zweige offen stehen. Beim
   Backen gilt das nur fuer eine Seite: ohne diesen Schnitt traegt die letzte
   Datei jeden Zweig offen, den irgendeine vorherige geoeffnet hat. */
function zuruecksetzenNav(){
  NAV_OPEN.clear();
  NAV_OPEN.add('home');
  NAV_OPEN.add('arena');
}

/* NAV is authored as a flat list of [id, depth] pairs. Flatten it once, then
   read the tree out of the depth column — a child is simply the next entry
   with a greater depth. */
function navFlat(){
  const flat = [];
  NAV.forEach(sec => sec.ids.forEach((entry, i) => {
    const id = Array.isArray(entry) ? entry[0] : entry;
    const depth = Array.isArray(entry) ? entry[1]
                : (sec.subFrom !== undefined && i >= sec.subFrom ? 1 : 0);
    /* Der dritte Eintrag ist ein eigener Schluessel fuer die Zeile. Steht
       dieselbe Seite zweimal im Baum, klappen die zwei Zweige damit
       unabhaengig auf und zu; ohne ihn ist der Schluessel die Seite. */
    const key = (Array.isArray(entry) && entry[2]) || id;
    flat.push({id, depth, key, group: i === 0 ? sec.group : null});
  }));
  return flat;
}

function renderNav(active){
  const flat = navFlat();

  /* Jedes Vorkommen der aktiven Seite aufdecken, nicht nur das erste: die
     Queue Modes stehen unter beiden Familien, und beide Wege sollen sichtbar
     sein, sobald man auf der Seite steht. */
  flat.forEach((n, at) => {
    if (n.id !== active) return;
    let d = n.depth;
    for (let i = at - 1; i >= 0 && d > 0; i--){
      if (flat[i].depth < d){ NAV_OPEN.add(flat[i].key); d = flat[i].depth; }
    }
  });

  let out = '', foldedAt = null;
  flat.forEach((n, i) => {
    if (foldedAt !== null){
      if (n.depth > foldedAt) return;          // inside a folded subtree
      foldedAt = null;
    }
    const kids = i + 1 < flat.length && flat[i + 1].depth > n.depth;
    const open = NAV_OPEN.has(n.key);
    if (kids && !open) foldedAt = n.depth;

    const p   = PAGES[n.id] || EXTERN[n.id];
    const sub = n.depth ? 'sub' + (n.depth > 1 ? n.depth : '') : '';
    /* Auch eine Website-Zeile kann die aktuelle sein — auf der Seite, die
       sie meint. js/site-map.js reicht sie als active herein. */
    const cur = n.id === active ? ' aria-current="page"' : '';
    const tw  = kids
      ? '<span class="g-tw' + (open ? ' open' : '') + '" data-tw="' + n.key +
        '" role="button" tabindex="0" aria-expanded="' + open +
        '" aria-label="' + (open ? 'Collapse ' : 'Expand ') + p.title + '">' +
        ic('i-south', 'g-twi') + '</span>'
      : '<span class="g-tw empty"></span>';

    if (n.group) out += '<div class="g-group">' + n.group + '</div>';
    out += '<a class="' + sub + '" href="' + navZiel(n.id) + '"' + cur + '>' +
      tw + ic(p.icon) + '<span>' + p.title + '</span></a>';
  });
  return out;
}


/* Eine Unterseite traegt das Bild der naechsten Elternseite, die eine Karte
   hat — klein oben rechts. Das gibt jeder Seite innerhalb eines Modus oder
   eines Bereichs denselben Wiedererkennungswert, ohne den Platz eines Heros
   zu kosten. Gesucht wird die Kette hoch, nicht nur der direkte Elternteil:
   die Scorecard-Unterseiten haengen zwei Ebenen unter ihrem Bild. */
function markeFuer(id){
  let e = PAGES[id] && PAGES[id].parent;
  while (e) {
    if (CARD_BY_ZIEL[e]) return {karte: CARD_BY_ZIEL[e], seite: e};
    e = PAGES[e] && PAGES[e].parent;
  }
  return null;
}


/* ══ Eine ganze Seite ═════════════════════════════════════════════════════
   Baut Titel, Krumenpfad, Seitenleiste und Inhalt einer Seite als
   Zeichenketten. Wer sie wohin schreibt, entscheidet der Aufrufer:
   js/guide/boot.js legt sie ins DOM, tools/bake-guide.mjs in eine Datei.
   ══════════════════════════════════════════════════════════════════════════ */
function renderPage(id){
  const p = PAGES[id];
  if (!p) return null;

  const trail = crumbTrail(id);
  const crumbs =
    '<a href="' + G_NACHBAR + 'index.html">Home</a><span class="sep">/</span>' +
    trail.map((t, i) =>
      i === trail.length - 1
        ? '<span class="now">' + PAGES[t].title + '</span>'
        : '<a href="' + href(t) + '">' + PAGES[t].title + '</a><span class="sep">/</span>'
    ).join('');

  const headline = Array.isArray(p.h1)
    ? p.h1.map((s, i) => i % 2 ? '<span class="brand">' + s + '</span>' : s).join('')
    : p.h1;

  const blocks = (p.blocks || []).concat(SHOW_INBOX ? (p.inbox || []) : []).filter(b =>
    SHOW_DRAFT_NOTES || !(b.t === 'note' && /^Draft note/.test(b.title)));

  /* Hat eine Karte diese Seite als Ziel, steht ihr Bild oben auf der Seite —
     mit demselben Text wie auf der Karte. Kommt aus CARD_BY_ZIEL, deshalb
     gibt es keine zweite Zuordnung zu pflegen. */
  const heroCard = CARD_BY_ZIEL[id];
  const hero = heroCard && !heroCard.ph ? heroCard : null;
  const bild = G_BASIS + 'assets/cards/';
  const heroHtml = hero
    ? '<div class="tq-card tq-hero g-hero"><img src="' + bild + hero.img +
      '-960.webp" srcset="' + bild + hero.img + '-480.webp 480w, ' +
      bild + hero.img + '-960.webp 960w, ' +
      bild + hero.img + '-1600.webp 1600w" ' +
      'sizes="(max-width: 900px) 92vw, 890px" width="1600" height="1000" ' +
      'loading="eager" decoding="async" alt="">' +
      '<div class="tq-card-text"><div class="tq-card-body">' +
        '<span class="tq-t">' + hero.t + '</span>' +
        (hero.s ? '<span class="tq-s">' + hero.s + '</span>' : '') +
      '</div></div></div>'
    : '';

  const marke = hero ? null : markeFuer(id);
  /* Das Referenzbild traegt den Titel seiner Karte, in Gold wie auf der Karte
     selbst — sonst ist es auf einer Unterseite nur ein Stueck Foto. */
  const markeHtml = marke
    ? '<a class="g-marke tq-card" href="' + href(marke.seite) + '" title="' +
      PAGES[marke.seite].title + '">' +
      '<img src="' + bild + marke.karte.img + '-480.webp" ' +
      'width="1600" height="1000" loading="lazy" decoding="async" alt="' +
      PAGES[marke.seite].title + '">' +
      '<span class="tq-card-text"><span class="tq-card-body">' +
        '<span class="tq-t">' + marke.karte.t + '</span>' +
      '</span></span></a>'
    : '';

  /* Die Ueberschrift der Seite ist ein <h2>: das <h1> des Dokuments ist der
     "User Guide"-Hero, und ein Dokument bekommt kein zweites. */
  const body =
    heroHtml +
    '<div class="g-kopf"><div class="g-kopf-txt">' +
      (p.eyebrow ? '<p class="g-eyebrow">' + p.eyebrow + '</p>' : '') +
      '<h2 class="g-h1">' + headline + '</h2>' +
      '<p class="g-lead">' + p.lead + '</p>' +
    '</div>' + markeHtml + '</div>' +
    '<div class="g-stack' + (SHOT_SIDE ? ' shots-side' : '') + '">' + blocks.map(renderBlock).join('') + '</div>' +
    '<a class="g-cta" href="' + G_NACHBAR + 'downloads.html">' +
      '<img class="m" src="' + G_BASIS + 'assets/icon-192.png" width="192" height="192" ' +
      'loading="lazy" decoding="async" alt=""><div>' +
      '<div class="t">TournaQ Volley</div>' +
      '<div class="s">The tournament engine — get the app</div>' +
    '</div><span class="g-chev">' + ic('i-south') + '</span></a>';

  /* Verweise auf andere Guide-Seiten stehen im Inhalt als {{knoten}}: erst
     hier ist bekannt, ob daraus eine Hash-Route oder eine Datei wird. Einmal
     ueber den fertigen Rumpf, damit jeder Baustein sie tragen kann. */
  const rumpf = body.replace(/\{\{([a-z0-9-]+)\}\}/g, (_, k) => href(k));

  return {
    id,
    titel:  p.title + ' – TournaQ Guide',
    lead:   p.lead,
    crumbs,
    body:   rumpf,
    navi:   renderNav(id),
  };
}
