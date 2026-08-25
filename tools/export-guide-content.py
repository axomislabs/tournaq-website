#!/usr/bin/env python3
"""Export every piece of guide copy to a CSV you can edit in Excel or Word.

The guide's content lives in the PAGES object inside pages/guide.html — a
nested structure of typed blocks. This flattens it to one row per editable
string, each with a stable address in the ID column, so the sheet can be
filled in and read back by tools/import-guide-content.py.

    python3 tools/export-guide-content.py             # -> guide-content.csv
    python3 tools/export-guide-content.py --md        # also an indented outline

The ID is the contract. Never edit it. To ADD content, insert a row and give
it an ID that follows the scheme of its neighbours (see README rows at the
top of the sheet) — the importer places new rows by that address.
"""
import csv, io, json, os, re, subprocess, sys, tempfile

ROOT  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GUIDE = os.path.join(ROOT, 'pages', 'guide.html')
OUT   = os.path.join(ROOT, 'guide-content.csv')


def extract():
    """Run the guide's own data block in node and hand back PAGES + NAV."""
    src = io.open(GUIDE, encoding='utf-8').read()
    start = src.index('const panel')
    end   = src.index('];', src.index('const NAV')) + 2
    js = src[start:end] + '\nconsole.log(JSON.stringify({PAGES, NAV}));\n'
    with tempfile.NamedTemporaryFile('w', suffix='.js', delete=False,
                                     encoding='utf-8') as fh:
        fh.write(js); tmp = fh.name
    try:
        raw = subprocess.check_output(['node', tmp], text=True)
    finally:
        os.unlink(tmp)
    return json.loads(raw)


ROWS = []
def row(rid, level, outline, field, text, kind=''):
    if text is None or text == '':
        return
    ROWS.append({
        'ID': rid,
        'Ebene': level,
        'Struktur': ('    ' * (level - 1)) + outline,
        'Block': kind,
        'Feld': field,
        'Text': re.sub(r'\s+', ' ', str(text)).strip(),
        'Neu/Kommentar': '',
    })


def walk(pid, page):
    title = page.get('title', pid)
    row(pid + '/title',   1, title, 'title',   title, 'page')
    row(pid + '/eyebrow', 2, '· Eyebrow',  'eyebrow', page.get('eyebrow'), 'page')
    h1 = page.get('h1')
    if h1:
        row(pid + '/h1',  2, '· Überschrift', 'h1', ''.join(h1), 'page')
    row(pid + '/lead',    2, '· Lead',     'lead', page.get('lead'), 'page')

    for bi, b in enumerate(page.get('blocks') or []):
        t   = b.get('t')
        bid = '%s/b%d' % (pid, bi)

        if t == 'panel':
            row(bid + '/badge', 2, '▸ Panel: ' + (b.get('badge') or ''), 'badge', b.get('badge'), 'panel')
            row(bid + '/sub',   3, '· Unterzeile', 'sub', b.get('sub'), 'panel')
            for ii, it in enumerate(b.get('items') or []):
                iid = '%s/i%d' % (bid, ii)
                k   = it.get('k', 'item')
                row(iid + '/label', 3, '• ' + (it.get('label') or ''), 'label', it.get('label'), k)
                row(iid + '/cap',   4, '· ' + (it.get('cap') or ''),   'cap',   it.get('cap'),   k)

        elif t == 'fbox':
            row(bid + '/title', 2, '▸ Box: ' + (b.get('title') or ''), 'title', b.get('title'), 'fbox')
            row(bid + '/body',  3, '· Fließtext', 'body', b.get('body'), 'fbox')
            for li, ln in enumerate(b.get('lines') or []):
                row('%s/l%d/title' % (bid, li), 3, '• ' + (ln.get('title') or ''),
                    'title', ln.get('title'), 'fbox-line')
                row('%s/l%d/body' % (bid, li), 4, '· ' + (ln.get('body') or ''),
                    'body', ln.get('body'), 'fbox-line')

        elif t == 'grid':
            row(bid, 2, '▸ Karten-Grid', 'grid', '(%d Karten)' % len(b.get('cards') or []), 'grid')
            for ci, c in enumerate(b.get('cards') or []):
                cid = '%s/c%d' % (bid, ci)
                row(cid + '/label', 3, '• ' + (c.get('label') or ''), 'label', c.get('label'), 'card')
                row(cid + '/cap',   4, '· ' + (c.get('cap') or ''),   'cap',   c.get('cap'),   'card')

        elif t == 'sect':
            row(bid + '/label', 2, '── Abschnitt: ' + (b.get('label') or ''),
                'label', b.get('label'), 'sect')

        elif t == 'note':
            row(bid + '/title', 2, '▸ Note: ' + (b.get('title') or ''), 'title', b.get('title'), 'note')
            row(bid + '/body',  3, '· Notiztext', 'body', b.get('body'), 'note')

        elif t == 'flow':
            row(bid, 2, '▸ Flow-Diagramm (im Code gezeichnet)', 'spec', b.get('spec'), 'flow')


def main():
    data  = extract()
    pages = data['PAGES']
    order = [i for sec in data['NAV'] for i in sec['ids']]
    order += [k for k in pages if k not in order]

    for pid in order:
        walk(pid, pages[pid])

    cols = ['ID', 'Ebene', 'Struktur', 'Block', 'Feld', 'Text', 'Neu/Kommentar']
    with io.open(OUT, 'w', encoding='utf-8-sig', newline='') as fh:
        w = csv.DictWriter(fh, fieldnames=cols)
        w.writeheader()
        for r in ROWS:
            w.writerow(r)

    print('%d Zeilen -> %s' % (len(ROWS), os.path.relpath(OUT, ROOT)))

    if '--md' in sys.argv:
        md = os.path.join(ROOT, 'guide-content.md')
        with io.open(md, 'w', encoding='utf-8') as fh:
            fh.write('# TournaQ User Guide — Content\n\n')
            for r in ROWS:
                pad = '  ' * (r['Ebene'] - 1)
                if r['Ebene'] == 1:
                    fh.write('\n\n## %s\n\n' % r['Text'])
                else:
                    fh.write('%s- **%s** %s\n' % (pad, r['Feld'], r['Text']))
        print('Gliederung  -> %s' % os.path.relpath(md, ROOT))


if __name__ == '__main__':
    main()
