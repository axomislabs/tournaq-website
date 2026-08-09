#!/usr/bin/env python3
"""Build review copies of the guide pages — the real page, plus comment bubbles.

Reviewing copy out of context does not work: a heading reads fine in a list and
badly above the screenshot it belongs to. So this rebuilds each page exactly as
it ships, then tags every string with the spec path that produced it and layers
a review overlay on top. You read the page as a visitor would, and click the
bubble beside anything you want to change.

    python3 tools/build-review.py        # -> drafts/review/
    open drafts/review/index.html

Edit in place or leave a comment, then Export CSV and run

    python3 tools/apply-review.py

which writes the edits back into tools/specs/*.json, rebuilds the affected
pages, and prints the comments for a decision. Comments carry across pages —
state is shared, so you can review several and export once at the end.

Lives in drafts/ (git-ignored): a working tool, not a page of the site.
"""
import glob
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib
_sec = importlib.import_module('build-guide-section')
_page = importlib.import_module('build-guide-page')

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(REPO, 'drafts/review')
STORAGE_KEY = 'tq-copy-review-v2'


def build_page(spec_path):
    """One review copy: the real page plus data-review tags and the overlay."""
    spec = json.load(open(spec_path, encoding='utf-8'))
    slug = spec['slug']

    # drafts/review/x.html sits at the same depth as pages/modes/x.html, so
    # every ../../ asset path resolves identically and the page looks the same.
    original_out = spec['out']
    spec['out'] = 'drafts/review/%s.html' % slug
    _sec.REVIEW = True
    try:
        _page.build_from_spec(spec)
    finally:
        _sec.REVIEW = False

    path = os.path.join(REPO, spec['out'])
    html = open(path, encoding='utf-8').read()

    # nav scripts sniff location.pathname to guess their link prefix; from
    # drafts/ that guess is wrong, and data-nav-base is what they honour instead
    html = html.replace('<html lang="en" data-i18n-base="../../"',
                        '<html lang="en" data-nav-base="../../pages/" data-i18n-base="../../"')
    html = html.replace('<title>', '<title>Review · ', 1)

    # Strip the i18n hooks. Two reasons: applyTranslations sets textContent,
    # which would wipe the review button appended inside those elements, and a
    # reviewer on a Spanish browser would otherwise be shown Spanish for the
    # handful of translated strings while reviewing English source copy.
    html = re.sub(r'\s+data-i18n(?:-html|-alt|-title)?="[^"]*"', '', html)

    overlay = OVERLAY.replace('__KEY__', STORAGE_KEY).replace('__SLUG__', slug) \
                     .replace('__LIVE__', '../../' + original_out)
    html = html.replace('</body>', overlay + '\n</body>')
    open(path, 'w', encoding='utf-8').write(html)

    return slug, spec['title'], html.count('data-review=')


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    pages = []
    for spec_path in sorted(glob.glob(os.path.join(REPO, 'tools/specs/*.json'))):
        pages.append(build_page(spec_path))

    links = '\n'.join(
        '      <a class="rv-page" href="%s.html"><span>%s</span><em>%d strings</em></a>'
        % (slug, title, n) for slug, title, n in pages)
    index = INDEX.replace('__LINKS__', links) \
                 .replace('__KEY__', STORAGE_KEY) \
                 .replace('__TOTAL__', str(sum(n for _, _, n in pages))) \
                 .replace('__PAGES__', str(len(pages)))
    open(os.path.join(OUT_DIR, 'index.html'), 'w', encoding='utf-8').write(index)

    print('output : %s' % os.path.relpath(OUT_DIR, REPO))
    print('pages  : %d, %d reviewable strings' % (len(pages), sum(n for _, _, n in pages)))
    for slug, _, n in pages:
        print('         %-28s %3d' % (slug, n))
    print('open   : drafts/review/index.html')


# ── The overlay, injected into every review page ────────────────────────────
OVERLAY = r'''
<style>
  /* Review overlay — not part of the site. */
  [data-review] { position: relative; }
  [data-review]:hover { outline: 1px dashed rgba(169,120,0,0.5); outline-offset: 3px; }
  .rv-dot {
    position: absolute; top: -9px; right: -9px; z-index: 30;
    width: 22px; height: 22px; border-radius: 999px; border: 0; cursor: pointer;
    background: #fff; box-shadow: 0 1px 5px rgba(0,0,0,0.25);
    font-size: 12px; line-height: 22px; text-align: center; padding: 0;
    opacity: 0; transition: opacity 0.12s;
  }
  [data-review]:hover > .rv-dot, .rv-dot.has, .rv-dot.open { opacity: 1; }
  .rv-dot.has { background: #F0D47A; }
  .rv-dot.has.wrong { background: #c0392b; color: #fff; }
  .rv-dot.has.cut { background: #7f8c8d; color: #fff; }
  img[data-review] + .rv-dot { top: 4px; right: 4px; }
  .rv-marked { background: rgba(240,212,122,0.28); border-radius: 4px; }
  .rv-marked-wrong { background: rgba(192,57,43,0.14); border-radius: 4px; }

  .rv-pop {
    position: absolute; z-index: 40; width: 320px; right: -6px; top: 20px;
    background: #fff; border: 1px solid #D6E0C2; border-radius: 12px;
    box-shadow: 0 12px 34px rgba(0,0,0,0.22); padding: 12px; text-align: left;
    font: 13px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    color: #1A1A1A;
  }
  .rv-pop .rv-path {
    font: 10px ui-monospace, Menlo, monospace; color: #aaa;
    word-break: break-all; margin-bottom: 6px;
  }
  .rv-pop textarea {
    font: inherit; width: 100%; border: 1px solid #D6E0C2; border-radius: 6px;
    padding: 6px 8px; resize: vertical; background: #FCFDF9;
  }
  .rv-pop textarea.rv-text { min-height: 66px; margin-bottom: 6px; }
  .rv-pop textarea.rv-comment { min-height: 50px; }
  .rv-pop textarea:focus { outline: none; border-color: #A97800; background: #FFFDF2; }
  .rv-pop label { display: block; font-size: 10px; font-weight: 700; text-transform: uppercase;
                  letter-spacing: 0.5px; color: #556B2F; margin: 6px 0 3px; }
  .rv-flags { display: flex; gap: 5px; flex-wrap: wrap; margin-top: 8px; }
  .rv-flags button {
    font: inherit; font-size: 11px; font-weight: 700; padding: 3px 9px; cursor: pointer;
    border-radius: 999px; border: 1px solid #D6E0C2; background: #fff; color: #666;
  }
  .rv-flags button.on { background: #556B2F; border-color: #556B2F; color: #fff; }
  .rv-flags button.on[data-flag="wrong"] { background: #c0392b; border-color: #c0392b; }
  .rv-flags button.on[data-flag="cut"] { background: #7f8c8d; border-color: #7f8c8d; }
  .rv-pop .rv-done { margin-top: 9px; display: flex; gap: 6px; }
  .rv-pop .rv-done button {
    font: inherit; font-size: 12px; font-weight: 700; padding: 5px 12px; cursor: pointer;
    border-radius: 999px; border: 0; background: #3A3E16; color: #fff;
  }
  .rv-pop .rv-done .rv-clear { background: #eee; color: #666; }

  #rv-bar {
    position: fixed; left: 0; right: 0; bottom: 0; z-index: 60;
    background: #3A3E16; color: #fff; padding: 9px 18px;
    display: flex; gap: 12px; align-items: center; flex-wrap: wrap;
    font: 13px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  }
  #rv-bar b { color: #F0D47A; }
  #rv-bar .rv-sp { flex: 1; }
  #rv-bar a, #rv-bar button {
    font: inherit; font-weight: 700; font-size: 12px; padding: 6px 13px; cursor: pointer;
    border-radius: 999px; border: 0; text-decoration: none;
    background: rgba(255,255,255,0.16); color: #fff;
  }
  #rv-bar button.rv-primary { background: #F0D47A; color: #3A3E16; }
  body { padding-bottom: 54px; }
  @media print { .rv-dot, #rv-bar, .rv-pop { display: none !important; } }
</style>
<script>
document.addEventListener('DOMContentLoaded', function () {
  var KEY = '__KEY__', SLUG = '__SLUG__';
  var state = {};
  try { state = JSON.parse(localStorage.getItem(KEY)) || {}; } catch (e) {}
  function save() { try { localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) {} }

  var FLAGS = [['reword', 'Reword'], ['wrong', 'Wrong'], ['cut', 'Cut']];
  var open = null;

  function value(el) {
    var attr = el.getAttribute('data-review-attr');
    return attr ? el.getAttribute(attr) : el.textContent.trim();
  }
  function setValue(el, v) {
    var attr = el.getAttribute('data-review-attr');
    if (attr) el.setAttribute(attr, v); else el.textContent = v;
  }
  function touched(s) { return !!(s && (s.edited != null || s.comment || s.flag)); }

  function paint(el, dot, s) {
    var has = touched(s);
    dot.className = 'rv-dot' + (has ? ' has' : '') + (s && s.flag ? ' ' + s.flag : '');
    dot.textContent = s && s.comment ? '💬' : (has ? '✎' : '✎');
    var host = el.getAttribute('data-review-attr') ? el.parentNode : el;
    host.classList.toggle('rv-marked', has && s.flag !== 'wrong');
    host.classList.toggle('rv-marked-wrong', has && s.flag === 'wrong');
    count();
  }

  function close() {
    if (!open) return;
    open.pop.remove();
    open.dot.classList.remove('open');
    open = null;
  }

  function popover(el, dot, id, original) {
    close();
    var s = state[id] || {};
    var pop = document.createElement('div');
    pop.className = 'rv-pop';
    pop.addEventListener('click', function (e) { e.stopPropagation(); });

    var path = document.createElement('div');
    path.className = 'rv-path';
    path.textContent = SLUG + ' · ' + id.split('|')[1];
    pop.appendChild(path);

    var lt = document.createElement('label'); lt.textContent = 'Text'; pop.appendChild(lt);
    var ta = document.createElement('textarea');
    ta.className = 'rv-text';
    ta.value = s.edited != null ? s.edited : original;
    pop.appendChild(ta);

    var lc = document.createElement('label'); lc.textContent = 'Comment'; pop.appendChild(lc);
    var ca = document.createElement('textarea');
    ca.className = 'rv-comment';
    ca.placeholder = 'What is wrong with it, or what you want instead…';
    ca.value = s.comment || '';
    pop.appendChild(ca);

    var flags = document.createElement('div');
    flags.className = 'rv-flags';
    FLAGS.forEach(function (f) {
      var b = document.createElement('button');
      b.textContent = f[1];
      b.dataset.flag = f[0];
      if (s.flag === f[0]) b.classList.add('on');
      b.addEventListener('click', function () {
        s.flag = s.flag === f[0] ? undefined : f[0];
        flags.querySelectorAll('button').forEach(function (x) {
          x.classList.toggle('on', x.dataset.flag === s.flag);
        });
      });
      flags.appendChild(b);
    });
    pop.appendChild(flags);

    var done = document.createElement('div');
    done.className = 'rv-done';
    var ok = document.createElement('button');
    ok.textContent = 'Save';
    ok.addEventListener('click', function () {
      var next = { orig: original, field: el.tagName.toLowerCase() };
      if (ta.value.trim() && ta.value.trim() !== original) next.edited = ta.value.trim();
      if (ca.value.trim()) next.comment = ca.value.trim();
      if (s.flag) next.flag = s.flag;
      if (next.edited || next.comment || next.flag) state[id] = next; else delete state[id];
      save();
      setValue(el, next.edited != null ? next.edited : original);
      paint(el, dot, state[id]);
      close();
    });
    var clear = document.createElement('button');
    clear.className = 'rv-clear';
    clear.textContent = 'Clear';
    clear.addEventListener('click', function () {
      delete state[id];
      save();
      setValue(el, original);
      paint(el, dot, null);
      close();
    });
    done.appendChild(ok);
    done.appendChild(clear);
    pop.appendChild(done);

    (el.getAttribute('data-review-attr') ? el.parentNode : el).appendChild(pop);
    dot.classList.add('open');
    open = { pop: pop, dot: dot };
    ta.focus();
  }

  var dots = [];
  function count() {
    var n = Object.keys(state).length;
    var mine = Object.keys(state).filter(function (k) { return k.indexOf(SLUG + '|') === 0; }).length;
    var out = document.getElementById('rv-count');
    if (out) out.innerHTML = '<b>' + mine + '</b> on this page · <b>' + n + '</b> in total';
  }

  document.querySelectorAll('[data-review]').forEach(function (el) {
    var id = SLUG + '|' + el.getAttribute('data-review');
    var original = value(el);
    var s = state[id];
    // a saved edit shows in place, so the page reads as it would after applying
    if (s && s.edited != null) setValue(el, s.edited);

    var dot = document.createElement('button');
    dot.className = 'rv-dot';
    dot.title = 'Comment on this';
    dot.addEventListener('click', function (e) {
      e.preventDefault();
      e.stopPropagation();
      if (open && open.dot === dot) { close(); return; }
      popover(el, dot, id, s && s.orig ? s.orig : original);
    });
    var host = el.getAttribute('data-review-attr') ? el.parentNode : el;
    if (getComputedStyle(host).position === 'static') host.style.position = 'relative';
    host.appendChild(dot);
    paint(el, dot, s);
    dots.push(dot);
  });

  document.addEventListener('click', close);
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') close(); });

  var bar = document.createElement('div');
  bar.id = 'rv-bar';
  bar.innerHTML =
    '<a href="index.html">← All pages</a>' +
    '<span id="rv-count"></span>' +
    '<span class="rv-sp"></span>' +
    '<a href="__LIVE__" target="_blank" rel="noopener">Open the real page</a>' +
    '<button id="rv-csv" class="rv-primary">Export CSV</button>';
  bar.addEventListener('click', function (e) { e.stopPropagation(); });
  document.body.appendChild(bar);
  count();

  function cell(v) {
    v = v == null ? '' : String(v);
    return /[",\n]/.test(v) ? '"' + v.replace(/"/g, '""') + '"' : v;
  }
  document.getElementById('rv-csv').addEventListener('click', function () {
    var head = ['Page', 'Path', 'Field', 'Screenshot', 'Original', 'Edited', 'Flag', 'Comment'];
    var lines = [head.map(cell).join(',')];
    Object.keys(state).sort().forEach(function (k) {
      var s = state[k], parts = k.split('|');
      lines.push([parts[0], parts[1], s.field || '', '', s.orig || '',
                  s.edited || '', s.flag || '', s.comment || ''].map(cell).join(','));
    });
    if (lines.length === 1) { alert('Nothing edited or commented yet.'); return; }
    var d = new Date(), p = function (n) { return (n < 10 ? '0' : '') + n; };
    var name = 'copy-review-' + d.getFullYear() + '-' + p(d.getMonth() + 1) + '-' + p(d.getDate()) + '.csv';
    var blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8' });
    var url = URL.createObjectURL(blob);
    var a = document.createElement('a');
    a.href = url; a.download = name;
    document.body.appendChild(a); a.click(); document.body.removeChild(a);
    setTimeout(function () { URL.revokeObjectURL(url); }, 1000);
  });

  // i18n.js is what makes the body visible; with its hooks stripped it still
  // runs, but belt and braces in case that ever changes.
  document.body.style.visibility = 'visible';
});
</script>'''


INDEX = r'''<!DOCTYPE html>
<!-- Copy review index — generated by tools/build-review.py. Not part of the site. -->
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Copy review – TournaQ</title>
  <link rel="icon" href="../../favicon.ico" sizes="any">
  <style>
    :root { --olive:#556B2F; --olive-dark:#3A3E16; --gold:#F0D47A; --border:#D6E0C2;
            --bg:#F9FAF6; --muted:#666; }
    * { box-sizing:border-box; margin:0; padding:0; }
    body { font-family:-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
           background:var(--bg); color:#1A1A1A; line-height:1.55; }
    header { background:var(--olive-dark); color:#fff; padding:26px 22px; }
    header h1 { color:var(--gold); font-size:22px; margin-bottom:6px; }
    header p { font-size:14px; opacity:0.85; max-width:70ch; }
    main { max-width:900px; margin:0 auto; padding:26px 22px 60px; }
    .rv-page { display:flex; align-items:baseline; gap:10px; text-decoration:none;
               background:#fff; border:1px solid var(--border); border-radius:12px;
               padding:13px 16px; margin-bottom:8px; color:var(--olive-dark); }
    .rv-page:hover { border-color:var(--olive); box-shadow:0 2px 8px rgba(0,0,0,0.06); }
    .rv-page span { font-weight:700; font-size:15px; flex:1; }
    .rv-page em { font-style:normal; font-size:12px; color:var(--muted); }
    .how { background:#fff; border:1px solid var(--border); border-radius:12px;
           padding:18px 20px; margin-bottom:22px; }
    .how h2 { font-size:15px; color:var(--olive); margin-bottom:8px; }
    .how ol { padding-left:20px; font-size:14px; color:var(--muted); }
    .how li { margin-bottom:5px; }
    .how code { font-family:ui-monospace, Menlo, monospace; font-size:13px;
                background:#EEF2E6; padding:1px 5px; border-radius:4px; }
    .bar { display:flex; gap:10px; align-items:center; margin-bottom:18px; flex-wrap:wrap; }
    .bar button { font:inherit; font-size:13px; font-weight:700; padding:7px 14px;
                  border-radius:999px; border:0; cursor:pointer; background:var(--gold); }
    .bar button.ghost { background:#e6e9df; color:#555; }
    .bar .n { font-size:13px; color:var(--muted); }
  </style>
</head>

<body>
  <header>
    <h1>Copy review</h1>
    <p>Each page below is the real thing — same layout, same screenshots — with a bubble beside
       every string that came from a spec. Hover to see them, click one to edit the text or leave
       a comment. Your notes are kept across all pages, so review as many as you like and export once.</p>
  </header>

  <main>
    <div class="how">
      <h2>How it works</h2>
      <ol>
        <li>Open a page and click the ✎ beside anything you want to change.</li>
        <li>Rewrite the text, leave a comment, or flag it — Reword, Wrong, or Cut.</li>
        <li>Edits show in place, so the page reads as it would once applied.</li>
        <li>Hit <strong>Export CSV</strong> from any page, then run <code>python3 tools/apply-review.py</code>.</li>
      </ol>
    </div>

    <div class="bar">
      <span class="n" id="n">—</span>
      <button id="csv">Export CSV</button>
      <button class="ghost" id="reset">Reset everything</button>
    </div>

__LINKS__
  </main>

  <script>
    var KEY = '__KEY__';
    var state = {};
    try { state = JSON.parse(localStorage.getItem(KEY)) || {}; } catch (e) {}
    document.getElementById('n').textContent =
      Object.keys(state).length + ' of __TOTAL__ strings touched, across __PAGES__ pages';

    function cell(v) {
      v = v == null ? '' : String(v);
      return /[",\n]/.test(v) ? '"' + v.replace(/"/g, '""') + '"' : v;
    }
    document.getElementById('csv').addEventListener('click', function () {
      var lines = [['Page','Path','Field','Screenshot','Original','Edited','Flag','Comment'].join(',')];
      Object.keys(state).sort().forEach(function (k) {
        var s = state[k], p = k.split('|');
        lines.push([p[0], p[1], s.field || '', '', s.orig || '',
                    s.edited || '', s.flag || '', s.comment || ''].map(cell).join(','));
      });
      if (lines.length === 1) { alert('Nothing edited or commented yet.'); return; }
      var d = new Date(), z = function (n) { return (n < 10 ? '0' : '') + n; };
      var blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8' });
      var a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = 'copy-review-' + d.getFullYear() + '-' + z(d.getMonth()+1) + '-' + z(d.getDate()) + '.csv';
      document.body.appendChild(a); a.click(); document.body.removeChild(a);
    });
    document.getElementById('reset').addEventListener('click', function () {
      if (!confirm('Discard every edit and comment across all pages?')) return;
      localStorage.removeItem(KEY);
      location.reload();
    });
  </script>
</body>

</html>
'''

if __name__ == '__main__':
    main()
