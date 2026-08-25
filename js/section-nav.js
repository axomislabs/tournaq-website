(function () {
  /* ══════════════════════════════════════════════════════════════════════
     Section rail — a drop-in replacement for feature-subnav.js. Same
     #feature-subnav placeholder, same link list, but rendered as the sticky
     left rail the guide already uses, and collapsing into a single drawer
     that carries both navigation levels on a phone.

     Why a rail instead of the box of pills: 18 links wrapping at the top of
     the content is roughly 400px of navigation before the first sentence on
     a phone, and the pill for the page you are on scrolls out of sight the
     moment you start reading. Styles live in css/style.css under .section-nav so
     the guide can drop its private .g-map copy onto them later.
     ══════════════════════════════════════════════════════════════════════ */
  var path = window.location.pathname;
  var inFeaturesDir = path.indexOf('/features/') !== -1;
  var inModes = path.indexOf('/modes/') !== -1;

  // Pages living outside the published tree (local drafts) can pin the link
  // prefix with data-nav-base on <html>; everything else sniffs the path.
  var navBase = document.documentElement.getAttribute('data-nav-base');

  var f, m, overview;
  if (navBase) {
    f = navBase + 'features/';
    m = navBase + 'modes/';
    overview = navBase + 'features.html';
  } else if (inFeaturesDir) {
    f = '';
    m = '../modes/';
    overview = '../features.html';
  } else if (inModes) {
    f = '../features/';
    m = '';
    overview = '../features.html';
  } else {
    f = 'features/';
    m = 'modes/';
    overview = 'features.html';
  }

  /* ── The section tree ───────────────────────────────────────────────────
     Icons follow the guide's own assignments (pages/guide.html) so a mode
     wears the same glyph in both places. Repeats across groups are fine and
     already happen in the guide. */
  var SECTION = {
    head: 'Features',
    lead: null,
    top: [
      { href: overview, icon: 'i-target', label: 'Feature Overview' }
    ],
    groups: [
      {
        label: 'Game &amp; Tournament Modes',
        links: [
          { href: m + 'games-and-tournaments.html', icon: 'i-arena',   label: 'Games &amp; Tournaments Hub' },
          { href: m + 'quick-game.html',            icon: 'i-bolt',    label: 'Quick Game' },
          { href: m + 'social-scramble.html',       icon: 'i-people',  label: 'Social Scrambles' },
          { href: m + 'scramble-king.html',         icon: 'i-crown',   label: 'Scramble Kings' },
          { href: m + 'doghouse.html',              icon: 'i-shield',  label: 'Doghouses' },
          { href: m + 'king-of-the-court.html',     icon: 'i-crown',   label: 'Kings of the Court' },
          { href: m + 'ko-system.html',             icon: 'i-bracket', label: 'Eliminations' },
          { href: m + 'league.html',                icon: 'i-grid',    label: 'Leagues' },
          { href: m + 'group-single-elimination.html', icon: 'i-trophy', label: 'TournaQ Classics' },
          { href: m + 'swiss-system.html',          icon: 'i-swap',    label: 'Swiss Systems' },
          { href: m + 'other-tournament-modes.html', icon: 'i-star',   label: 'Other Modes' }
        ]
      },
      {
        label: 'Platform Features',
        links: [
          { href: f + 'feature-matrix.html',       icon: 'i-grid',   label: 'Platform Features Hub' },
          { href: f + 'scoring.html',              icon: 'i-score',  label: 'Match Controls' },
          { href: f + 'tournament-features.html',  icon: 'i-edit',   label: 'Tournament Management' },
          { href: f + 'live-tournament.html',      icon: 'i-timer',  label: 'Live Tournament' },
          { href: f + 'device-scalability.html',   icon: 'i-device', label: 'Device &amp; Screen' },
          { href: f + 'navigation.html',           icon: 'i-map',    label: 'Navigation' },
          { href: f + 'user-administration.html',  icon: 'i-admin',  label: 'Player &amp; Team Administration' }
        ]
      }
    ]
  };

  /* ── Icon sprite ────────────────────────────────────────────────────────
     Copied from the guide's sprite, minus the symbols this section never
     asks for, plus i-device. Injected only where the page has not already
     inlined one — guide.html carries its own and must not get duplicate ids. */
  var SPRITE = {
    'i-admin':   '<circle cx="12" cy="8" r="3.4"/><path d="M4.5 20c.9-3.6 3.9-5.4 7.5-5.4s6.6 1.8 7.5 5.4"/>',
    'i-arena':   '<ellipse cx="12" cy="8.5" rx="8.5" ry="3.6"/><path d="M3.5 8.5v6c0 2 3.8 3.6 8.5 3.6s8.5-1.6 8.5-3.6v-6"/><path d="M12 12.1v6.1"/>',
    'i-trophy':  '<path d="M7 4h10v5a5 5 0 0 1-10 0V4Z"/><path d="M7 6H4.5v1.5A3.5 3.5 0 0 0 7.6 11M17 6h2.5v1.5A3.5 3.5 0 0 1 16.4 11"/><path d="M12 14v3.5M8.5 20h7"/>',
    'i-bracket': '<rect x="3" y="4" width="6" height="3.4" rx="1.2"/><rect x="3" y="16.6" width="6" height="3.4" rx="1.2"/><rect x="15" y="10.3" width="6" height="3.4" rx="1.2"/><path d="M9 5.7h3v6.3h3M9 18.3h3V12"/>',
    'i-score':   '<rect x="3" y="5" width="18" height="14" rx="2.4"/><path d="M12 5v14M6.2 10.4h2.6M7.5 9.1v2.6M15.2 10.4h2.6"/>',
    'i-bolt':    '<path d="M13.2 2.5 5 13.6h5.6L9.9 21.5 18.5 10h-5.9l.6-7.5Z"/>',
    'i-people':  '<circle cx="8.6" cy="8.4" r="3"/><path d="M2.8 19.4c.7-3.1 3.1-4.7 5.8-4.7s5.1 1.6 5.8 4.7"/><path d="M16.2 6.1a3 3 0 0 1 0 5.9M17.4 14.9c2.1.4 3.5 1.9 4 4.1"/>',
    'i-shield':  '<path d="M12 3 5 5.6v5.7c0 4.2 2.9 7.6 7 9.1 4.1-1.5 7-4.9 7-9.1V5.6L12 3Z"/>',
    'i-grid':    '<rect x="3.4" y="3.4" width="17.2" height="17.2" rx="2"/><path d="M3.4 9.1h17.2M3.4 14.9h17.2M9.1 3.4v17.2M14.9 3.4v17.2"/>',
    'i-edit':    '<path d="M15.6 4.6 19.4 8.4 8.8 19H5v-3.8L15.6 4.6Z"/><path d="M13.8 6.4l3.8 3.8"/>',
    'i-star':    '<path d="m12 3.6 2.6 5.4 5.9.8-4.3 4.1 1.1 5.9L12 17l-5.3 2.8 1.1-5.9-4.3-4.1 5.9-.8L12 3.6Z"/>',
    'i-swap':    '<path d="M4 8.4h13M13.6 5l3.4 3.4-3.4 3.4"/><path d="M20 15.6H7M10.4 12.2 7 15.6l3.4 3.4"/>',
    'i-crown':   '<path d="M3.6 7.4 7 12l5-6.6L17 12l3.4-4.6-1.5 11H5.1L3.6 7.4Z"/><path d="M5.1 19.4h13.8"/>',
    'i-timer':   '<circle cx="12" cy="13.4" r="7.4"/><path d="M12 9.6v3.8l2.6 1.6M9.6 2.6h4.8M19.4 7.4l-1.6-1.6"/>',
    'i-map':     '<path d="M9 4.4 3.6 6.6v13L9 17.4l6 2.2 5.4-2.2v-13L15 6.6 9 4.4Z"/><path d="M9 4.4v13M15 6.6v13"/>',
    'i-target':  '<circle cx="12" cy="12" r="8.4"/><circle cx="12" cy="12" r="4.4"/><circle cx="12" cy="12" r=".9"/>',
    'i-device':  '<rect x="7.4" y="2.6" width="9.2" height="18.8" rx="2.2"/><path d="M10.6 5.4h2.8M12 18.4v.1"/>'
  };

  function injectSprite() {
    var missing = Object.keys(SPRITE).filter(function (id) {
      return !document.getElementById(id);
    });
    if (!missing.length) return;
    var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('width', '0');
    svg.setAttribute('height', '0');
    svg.setAttribute('aria-hidden', 'true');
    svg.setAttribute('focusable', 'false');
    svg.style.position = 'absolute';
    svg.innerHTML = missing.map(function (id) {
      return '<symbol id="' + id + '" viewBox="0 0 24 24">' + SPRITE[id] + '</symbol>';
    }).join('');
    document.body.insertBefore(svg, document.body.firstChild);
  }

  var ic = function (n) {
    return '<svg class="section-nav-ic" aria-hidden="true"><use href="#' + n + '"/></svg>';
  };

  var currentFile = path.split('/').pop();
  var isCurrent = function (href) {
    return href.split('/').pop() === currentFile;
  };

  function linkRow(l) {
    return '<a href="' + l.href + '"' + (isCurrent(l.href) ? ' aria-current="page"' : '') + '>' +
      ic(l.icon) + '<span>' + l.label + '</span></a>';
  }

  function sectionMarkup() {
    var total = SECTION.top.length + SECTION.groups.reduce(function (n, g) {
      return n + g.links.length;
    }, 0);

    return '<p class="section-nav-head">' + SECTION.head + '</p>' +
      '<p class="section-nav-sub">' + total + ' pages</p>' +
      '<nav>' + SECTION.top.map(linkRow).join('') + '</nav>' +
      SECTION.groups.map(function (g) {
        return '<div class="section-nav-group">' + g.label + '</div>' +
          '<nav>' + g.links.map(linkRow).join('') + '</nav>';
      }).join('');
  }

  /* The site links are cloned, not rebuilt: main-nav.js has already resolved
     their hrefs and marked the active one, and the clones keep their
     data-i18n keys so the language switcher retranslates both copies. */
  function siteMarkup() {
    var src = document.querySelector('.nav-links');
    if (!src) return '';
    var wrap = document.createElement('div');
    wrap.className = 'section-nav-site';
    wrap.innerHTML = '<div class="section-nav-group section-nav-group-first">TournaQ</div><nav></nav><div class="section-nav-sep"></div>';
    var nav = wrap.querySelector('nav');
    src.querySelectorAll('a').forEach(function (a) {
      nav.appendChild(a.cloneNode(true));
    });
    return wrap.outerHTML;
  }

  var placeholder = document.getElementById('feature-subnav');
  if (!placeholder) return;
  var main = placeholder.closest('main');
  if (!main) return;

  injectSprite();

  var rail = document.createElement('aside');
  rail.className = 'section-nav';
  rail.id = 'section-nav';
  rail.setAttribute('aria-label', SECTION.head);
  rail.innerHTML = siteMarkup() + sectionMarkup();

  placeholder.remove();
  main.insertBefore(rail, main.firstChild);
  main.classList.add('has-section-nav');
  document.body.classList.add('section-nav-drawer');

  /* ── Drawer ───────────────────────────────────────────────────────────
     The header's burger checkbox stays the single source of truth for "menu
     open", so the burger keeps animating into its X and the two navigations
     can never both be open. Below 900px it drives the rail instead of the
     header's own drop-down list, which css/style.css hides for the page. */
  var mq = window.matchMedia('(max-width: 900px)');
  var toggle = document.getElementById('nav-toggle');
  var scrim = null;

  function openDrawer() {
    rail.classList.add('open');
    if (scrim) return;
    scrim = document.createElement('div');
    scrim.className = 'section-nav-scrim';
    scrim.addEventListener('click', closeDrawer);
    document.body.appendChild(scrim);
  }

  function closeDrawer() {
    rail.classList.remove('open');
    if (toggle) toggle.checked = false;
    if (scrim) { scrim.remove(); scrim = null; }
  }

  if (toggle) {
    toggle.addEventListener('change', function () {
      if (!mq.matches) return;
      if (toggle.checked) openDrawer(); else closeDrawer();
    });
  }

  var onBreakpoint = function (e) { if (!e.matches) closeDrawer(); };
  if (mq.addEventListener) mq.addEventListener('change', onBreakpoint);
  else mq.addListener(onBreakpoint);

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') closeDrawer();
  });

  // Following a link inside the drawer should not leave it hanging open
  // behind the new page on a same-page anchor.
  rail.addEventListener('click', function (e) {
    if (e.target.closest('a')) closeDrawer();
  });
})();
