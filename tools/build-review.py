#!/usr/bin/env python3
"""Build a review page listing every editable string on the guide pages.

The mode and feature pages are generated from tools/specs/*.json, so the useful
thing to comment on is not the rendered HTML — it is the string in the spec that
produced it. This walks every spec, addresses each string by its path, and emits
one page carrying the lot, next to the screenshot each one describes.

    python3 tools/build-review.py          # -> drafts/review/review.html
    open drafts/review/review.html

The loop mirrors the feature matrix: edit in the browser, Export CSV, and

    python3 tools/apply-review.py

writes the edits back into the specs and prints the comments. Every row carries
its spec path, so an edit lands on exactly the string it came from.

Lives in drafts/ (git-ignored) because it is a working tool, not a page of the
site — unlike the feature matrix, nobody should ever see this published.
"""
import glob
import html
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib
_sec = importlib.import_module('build-guide-section')

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, 'drafts/review/review.html')
STORAGE_KEY = 'tq-copy-review-v1'

# Which spec fields are prose worth reviewing. Everything else in a spec is
# structure — ids, screenshot names, output paths — and editing those here
# would break the page rather than improve it.
LABELS = {
    'title': 'Page title',
    'subtitle': 'Hero subtitle',
    'intro': 'Intro paragraph',
    'bestfor': 'Best for',
    'workflow': 'Workflow step',
    'feedback': 'Feedback prompt',
    'feature_list_title': 'Feature list heading',
    'feature_list_text': 'Feature list intro',
    'sec.title': 'Section heading',
    'sec.text': 'Section intro',
    'card.h': 'Card heading',
    'card.p': 'Card text',
    'card.alt': 'Image alt text',
}


def rows_for(spec):
    """(path, label, text, shot) for every reviewable string in one spec."""
    out = []
    folder = spec.get('folder', '')

    def add(path, label, text, shot=None):
        if text:
            out.append({'path': path, 'label': label, 'text': text, 'shot': shot or ''})

    hero_shot = ''
    hero = spec.get('hero') or {}
    if hero.get('shot'):
        hero_shot = hero['shot'] if '/' in hero['shot'] else '%s/%s' % (folder, hero['shot'])

    add('title', LABELS['title'], spec.get('title'), hero_shot)
    add('subtitle', LABELS['subtitle'], spec.get('subtitle'))
    for i, p in enumerate(spec.get('intro', [])):
        add('intro/%d' % i, LABELS['intro'], p, hero_shot if i == 0 else '')
    if hero.get('alt'):
        add('hero/alt', LABELS['card.alt'], hero['alt'], hero_shot)
    for i, p in enumerate(spec.get('bestfor', [])):
        add('bestfor/%d' % i, LABELS['bestfor'], p)

    for si, sec in enumerate(spec.get('sections', [])):
        add('sections/%d/title' % si, LABELS['sec.title'], sec.get('title'))
        add('sections/%d/text' % si, LABELS['sec.text'], sec.get('text'))
        for ci, card in enumerate(sec.get('cards', [])):
            shot = card.get('shot', '')
            if shot and '/' not in shot:
                shot = '%s/%s' % (folder, shot)
            base = 'sections/%d/cards/%d' % (si, ci)
            add(base + '/h', LABELS['card.h'], card.get('h'), shot)
            body = card.get('p')
            if isinstance(body, list):
                for pi, para in enumerate(body):
                    add(base + '/p/%d' % pi, LABELS['card.p'], para, shot)
            else:
                add(base + '/p', LABELS['card.p'], body, shot)
            add(base + '/alt', LABELS['card.alt'], card.get('alt'), shot)

    for i, step in enumerate(spec.get('workflow', [])):
        add('workflow/%d' % i, LABELS['workflow'], step)
    add('feature_list_title', LABELS['feature_list_title'], spec.get('feature_list_title'))
    add('feature_list_text', LABELS['feature_list_text'], spec.get('feature_list_text'))
    add('feedback', LABELS['feedback'], spec.get('feedback'))
    return out


def thumb_for(shot):
    """Smallest derivative of a shot, as a path relative to the review page."""
    if not shot:
        return ''
    for w in (430, 645, 860):
        rel = 'assets/guide/%s-%d.webp' % (shot, w)
        if os.path.exists(os.path.join(REPO, rel)):
            return '../../' + rel
    return ''


def main():
    pages = []
    for path in sorted(glob.glob(os.path.join(REPO, 'tools/specs/*.json'))):
        spec = json.load(open(path, encoding='utf-8'))
        rows = rows_for(spec)
        for r in rows:
            r['thumb'] = thumb_for(r['shot'])
        pages.append({
            'slug': spec['slug'],
            'title': spec['title'],
            'out': spec['out'],
            'rows': rows,
        })

    total = sum(len(p['rows']) for p in pages)
    data = json.dumps(pages, ensure_ascii=False, indent=1)
    doc = TEMPLATE.replace('__DATA__', data) \
                  .replace('__KEY__', STORAGE_KEY) \
                  .replace('__COUNT__', str(total)) \
                  .replace('__PAGES__', str(len(pages)))

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    open(OUT, 'w', encoding='utf-8').write(doc)
    print('page   : %s' % os.path.relpath(OUT, REPO))
    print('review : %d strings across %d pages' % (total, len(pages)))
    for p in pages:
        print('         %-28s %3d' % (p['slug'], len(p['rows'])))


TEMPLATE = r'''<!DOCTYPE html>
<!--
  Copy review — generated by tools/build-review.py. Not part of the site.

  Edit any string in place and/or leave a comment, then Export CSV and run
      python3 tools/apply-review.py
  which writes the edits back into tools/specs/*.json, rebuilds the pages and
  prints the comments. Nothing here is applied until that script runs.

  State is kept in localStorage, so closing the tab does not lose your work.
-->
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Copy review – TournaQ</title>
  <link rel="icon" href="../../favicon.ico" sizes="any">
  <style>
    :root {
      --olive: #556B2F; --olive-dark: #3A3E16; --olive-light: #EEF2E6;
      --gold: #F0D47A; --gold-dark: #A97800; --border: #D6E0C2;
      --bg: #F9FAF6; --text: #1A1A1A; --muted: #666; --radius: 12px;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: var(--bg); color: var(--text); line-height: 1.55; padding-bottom: 80px;
    }
    header {
      position: sticky; top: 0; z-index: 20;
      background: var(--olive-dark); color: white; padding: 14px 22px;
      display: flex; gap: 14px; align-items: center; flex-wrap: wrap;
    }
    header h1 { font-size: 17px; color: var(--gold); margin-right: 6px; }
    header .count { font-size: 13px; opacity: 0.8; }
    .spacer { flex: 1; }
    .tbtn {
      background: var(--gold); color: var(--olive-dark); border: 0;
      font-weight: 700; font-size: 13px; padding: 7px 14px;
      border-radius: 999px; cursor: pointer;
    }
    .tbtn.ghost { background: rgba(255,255,255,0.16); color: white; }
    .tbtn:hover { filter: brightness(1.06); }
    select, input[type=search] {
      font: inherit; font-size: 13px; padding: 6px 10px;
      border-radius: 999px; border: 1px solid rgba(255,255,255,0.25);
      background: rgba(255,255,255,0.12); color: white;
    }
    select option { color: var(--text); }
    main { max-width: 1180px; margin: 0 auto; padding: 24px 22px; }
    .page { margin-bottom: 34px; }
    .page > h2 {
      font-size: 19px; color: var(--olive-dark); margin-bottom: 2px;
      display: flex; align-items: baseline; gap: 10px;
    }
    .page > h2 a { font-size: 12px; font-weight: 400; color: var(--olive); }
    .page > .sub { font-size: 12px; color: var(--muted); margin-bottom: 12px; }
    .row {
      display: grid; grid-template-columns: 92px 150px minmax(0,1fr) minmax(0,320px);
      gap: 14px; align-items: start;
      background: white; border: 1px solid var(--border); border-radius: var(--radius);
      padding: 12px 14px; margin-bottom: 8px;
    }
    .row.is-edited { border-color: var(--gold-dark); box-shadow: 0 0 0 2px rgba(240,212,122,0.35); }
    .row.is-flagged { border-color: #c0392b; box-shadow: 0 0 0 2px rgba(192,57,43,0.18); }
    .thumb { width: 92px; }
    .thumb img {
      width: 100%; border-radius: 6px; border: 1px solid var(--border);
      background: var(--olive-light); display: block; cursor: zoom-in;
    }
    .thumb .none { font-size: 10px; color: #bbb; text-align: center; padding-top: 6px; }
    .meta .label {
      font-size: 10px; font-weight: 700; text-transform: uppercase;
      letter-spacing: 0.5px; color: var(--olive); display: block;
    }
    .meta .path { font-size: 10px; color: #aaa; font-family: ui-monospace, Menlo, monospace; word-break: break-all; }
    .text {
      font-size: 14px; outline: none; border-radius: 6px; padding: 4px 6px;
      border: 1px dashed transparent; min-height: 26px;
    }
    .text:hover { background: #F6F8F1; border-color: var(--border); }
    .text:focus { background: #FFFDF2; border-color: var(--gold-dark); border-style: solid; }
    .side { display: flex; flex-direction: column; gap: 6px; }
    .side textarea {
      font: inherit; font-size: 13px; width: 100%; min-height: 46px; resize: vertical;
      border: 1px solid var(--border); border-radius: 6px; padding: 6px 8px; background: #FCFDF9;
    }
    .side textarea:focus { outline: none; border-color: var(--gold-dark); background: #FFFDF2; }
    .flags { display: flex; gap: 5px; flex-wrap: wrap; }
    .flag {
      font-size: 11px; font-weight: 700; padding: 3px 9px; border-radius: 999px;
      border: 1px solid var(--border); background: white; color: var(--muted); cursor: pointer;
    }
    .flag.on { background: var(--olive); border-color: var(--olive); color: white; }
    .flag.on[data-flag="wrong"] { background: #c0392b; border-color: #c0392b; }
    .flag.on[data-flag="cut"] { background: #7f8c8d; border-color: #7f8c8d; }
    .orig { font-size: 11px; color: var(--gold-dark); margin-top: 4px; }
    .orig b { font-weight: 700; }
    .hidden { display: none !important; }
    #lightbox {
      position: fixed; inset: 0; background: rgba(0,0,0,0.8); z-index: 50;
      display: none; align-items: center; justify-content: center; padding: 30px;
    }
    #lightbox.on { display: flex; }
    #lightbox img { max-width: 100%; max-height: 100%; border-radius: 10px; }
    @media (max-width: 900px) {
      .row { grid-template-columns: 64px 1fr; }
      .thumb { width: 64px; }
      .meta { grid-column: 2; }
      .text, .side { grid-column: 1 / -1; }
    }
  </style>
</head>

<body>
  <header>
    <h1>Copy review</h1>
    <span class="count" id="count">__COUNT__ strings · __PAGES__ pages</span>
    <select id="f-page"><option value="">All pages</option></select>
    <select id="f-kind">
      <option value="">Everything</option>
      <option value="touched">Only edited or commented</option>
      <option value="edited">Only edited</option>
      <option value="commented">Only commented</option>
      <option value="alt">Only alt text</option>
    </select>
    <input type="search" id="f-text" placeholder="Search text…">
    <span class="spacer"></span>
    <button class="tbtn" id="btn-csv">Export CSV</button>
    <button class="tbtn ghost" id="btn-reset">Reset</button>
  </header>

  <main id="app"></main>
  <div id="lightbox"><img alt=""></div>

  <script>
    var PAGES = __DATA__;
    var KEY = '__KEY__';

    var state = {};
    try { state = JSON.parse(localStorage.getItem(KEY)) || {}; } catch (e) { state = {}; }
    function save() { try { localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) {} }
    function get(id) { return state[id] || (state[id] = {}); }

    var FLAGS = [['reword', 'Reword'], ['wrong', 'Factually wrong'], ['cut', 'Cut it']];

    function el(tag, cls, text) {
      var n = document.createElement(tag);
      if (cls) n.className = cls;
      if (text != null) n.textContent = text;
      return n;
    }

    function render() {
      var app = document.getElementById('app');
      app.innerHTML = '';
      PAGES.forEach(function (page) {
        var wrap = el('div', 'page');
        wrap.dataset.slug = page.slug;
        var h = el('h2');
        h.appendChild(el('span', null, page.title));
        var a = el('a', null, page.out);
        a.href = '../../' + page.out;
        a.target = '_blank';
        a.rel = 'noopener';
        h.appendChild(a);
        wrap.appendChild(h);
        wrap.appendChild(el('div', 'sub', page.rows.length + ' strings'));

        page.rows.forEach(function (r) {
          var id = page.slug + '|' + r.path;
          var st = get(id);
          var row = el('div', 'row');
          row.dataset.id = id;
          row.dataset.label = r.label;

          var thumb = el('div', 'thumb');
          if (r.thumb) {
            var img = document.createElement('img');
            img.src = r.thumb;
            img.loading = 'lazy';
            img.alt = '';
            img.addEventListener('click', function () {
              var lb = document.getElementById('lightbox');
              lb.querySelector('img').src = r.thumb;
              lb.classList.add('on');
            });
            thumb.appendChild(img);
          } else {
            thumb.appendChild(el('div', 'none', '—'));
          }
          row.appendChild(thumb);

          var meta = el('div', 'meta');
          meta.appendChild(el('span', 'label', r.label));
          meta.appendChild(el('span', 'path', r.path));
          row.appendChild(meta);

          var text = el('div', 'text', st.edited != null ? st.edited : r.text);
          text.contentEditable = 'true';
          text.spellcheck = true;
          text.addEventListener('input', function () {
            var v = text.textContent;
            if (v === r.text) delete st.edited; else st.edited = v;
            save();
            mark(row, st, r);
          });
          var textCell = el('div');
          textCell.appendChild(text);
          var orig = el('div', 'orig hidden');
          orig.innerHTML = '<b>was:</b> ' + r.text.replace(/&/g, '&amp;').replace(/</g, '&lt;');
          textCell.appendChild(orig);
          row.appendChild(textCell);

          var side = el('div', 'side');
          var ta = document.createElement('textarea');
          ta.placeholder = 'Comment…';
          ta.value = st.comment || '';
          ta.addEventListener('input', function () {
            if (ta.value.trim()) st.comment = ta.value; else delete st.comment;
            save();
            mark(row, st, r);
          });
          side.appendChild(ta);
          var flags = el('div', 'flags');
          FLAGS.forEach(function (f) {
            var b = el('button', 'flag', f[1]);
            b.dataset.flag = f[0];
            if (st.flag === f[0]) b.classList.add('on');
            b.addEventListener('click', function () {
              if (st.flag === f[0]) delete st.flag; else st.flag = f[0];
              save();
              flags.querySelectorAll('.flag').forEach(function (x) {
                x.classList.toggle('on', x.dataset.flag === st.flag);
              });
              mark(row, st, r);
            });
            flags.appendChild(b);
          });
          side.appendChild(flags);
          row.appendChild(side);

          mark(row, st, r);
          wrap.appendChild(row);
        });
        app.appendChild(wrap);
      });
      applyFilter();
    }

    function mark(row, st, r) {
      var edited = st.edited != null && st.edited !== r.text;
      row.classList.toggle('is-edited', edited);
      row.classList.toggle('is-flagged', st.flag === 'wrong');
      row.querySelector('.orig').classList.toggle('hidden', !edited);
      row.dataset.edited = edited ? '1' : '';
      row.dataset.commented = st.comment ? '1' : '';
    }

    function applyFilter() {
      var slug = document.getElementById('f-page').value;
      var kind = document.getElementById('f-kind').value;
      var q = document.getElementById('f-text').value.trim().toLowerCase();
      var shown = 0;
      document.querySelectorAll('.page').forEach(function (p) {
        var any = 0;
        p.querySelectorAll('.row').forEach(function (row) {
          var ok = true;
          if (slug && p.dataset.slug !== slug) ok = false;
          if (ok && kind === 'touched') ok = !!(row.dataset.edited || row.dataset.commented);
          if (ok && kind === 'edited') ok = !!row.dataset.edited;
          if (ok && kind === 'commented') ok = !!row.dataset.commented;
          if (ok && kind === 'alt') ok = row.dataset.label === 'Image alt text';
          if (ok && q) ok = row.querySelector('.text').textContent.toLowerCase().indexOf(q) !== -1;
          row.classList.toggle('hidden', !ok);
          if (ok) { any++; shown++; }
        });
        p.classList.toggle('hidden', any === 0);
      });
      document.getElementById('count').textContent =
        shown + ' shown · ' + Object.keys(state).filter(function (k) {
          return state[k].edited != null || state[k].comment || state[k].flag;
        }).length + ' touched';
    }

    function csvCell(v) {
      v = v == null ? '' : String(v);
      return /[",\n]/.test(v) ? '"' + v.replace(/"/g, '""') + '"' : v;
    }

    function stamp() {
      var d = new Date();
      function p(n) { return (n < 10 ? '0' : '') + n; }
      return d.getFullYear() + '-' + p(d.getMonth() + 1) + '-' + p(d.getDate());
    }

    document.getElementById('btn-csv').addEventListener('click', function () {
      var head = ['Page', 'Path', 'Field', 'Screenshot', 'Original', 'Edited', 'Flag', 'Comment'];
      var lines = [head.map(csvCell).join(',')];
      PAGES.forEach(function (page) {
        page.rows.forEach(function (r) {
          var st = state[page.slug + '|' + r.path] || {};
          var edited = (st.edited != null && st.edited !== r.text) ? st.edited : '';
          // only rows the reviewer actually touched — a full dump would bury
          // eight comments under two thousand unchanged lines
          if (!edited && !st.comment && !st.flag) return;
          lines.push([page.slug, r.path, r.label, r.shot, r.text,
                      edited, st.flag || '', st.comment || ''].map(csvCell).join(','));
        });
      });
      if (lines.length === 1) { alert('Nothing edited, flagged or commented yet.'); return; }
      var blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8' });
      var url = URL.createObjectURL(blob);
      var a = document.createElement('a');
      a.href = url;
      a.download = 'copy-review-' + stamp() + '.csv';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      setTimeout(function () { URL.revokeObjectURL(url); }, 1000);
    });

    document.getElementById('btn-reset').addEventListener('click', function () {
      if (!confirm('Discard every edit and comment on this page?')) return;
      state = {};
      save();
      render();
    });

    document.getElementById('lightbox').addEventListener('click', function () {
      this.classList.remove('on');
    });
    ['f-page', 'f-kind', 'f-text'].forEach(function (id) {
      document.getElementById(id).addEventListener('input', applyFilter);
    });

    var sel = document.getElementById('f-page');
    PAGES.forEach(function (p) {
      var o = document.createElement('option');
      o.value = p.slug;
      o.textContent = p.title;
      sel.appendChild(o);
    });

    render();
  </script>
</body>

</html>
'''

if __name__ == '__main__':
    main()
