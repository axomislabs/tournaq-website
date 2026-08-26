#!/usr/bin/env python3
"""Bake a feature-matrix CSV export back into the matrix page as its defaults.

The matrix page carries its data inline (a FEATURES array plus a DEFAULT_CELLS
map) so it works from file:// with no fetch. This script regenerates that block
from a CSV exported by the page's own "Export CSV" button, which makes the loop

    edit in the browser  ->  Export CSV  ->  bake  ->  reload

repeatable for every future round of updates.

    python3 tools/bake-feature-matrix.py                  # newest export in ~/Downloads
    python3 tools/bake-feature-matrix.py path/to.csv      # a specific file
    python3 tools/bake-feature-matrix.py --page pages/features/feature-matrix.html

Older exports (before the Section column existed) are handled too: rows sharing
tournament-features.html are split at the first Live Tournament feature.
"""
import argparse, csv, glob, json, os, re, shutil, sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_PAGE = os.path.join(REPO, 'pages/features/feature-matrix.html')
DOWNLOADS = os.path.expanduser('~/Downloads/feature-matrix-*.csv')

PAGE_SECTION = {
    'scoring.html': 'scoring',
    'tournament-features.html': 'tournament',
    'live-tournament.html': 'live',
    'device-scalability.html': 'device',
    'navigation.html': 'navigation',
    'user-administration.html': 'administration',
}
LIVE_STARTS_AT = 'Multi-device sync'   # only needed for pre-Section-column exports
SECTION_ORDER = ['scoring', 'tournament', 'live', 'device', 'navigation', 'administration']

STATUS = {'Available': 'available', 'In Progress': 'progress', 'Planned': 'planned'}
CELL = {'Available': 'yes', 'Planned': 'planned', 'N/A': 'na', '': ''}
MODE_COL = {
    'Quick Game': 'quick-game', 'Social Scrambles': 'social-scramble',
    'Royal Rotations': 'royal-rotation', 'Doghouses': 'doghouse',
    'Royal Shuffles': 'royal-shuffle', 'Eliminations': 'ko-system',
    # Die alten Namen bleiben gueltig: der Export kommt von aussen und wurde
    # womoeglich noch nicht umbenannt. Die Spalten-Id ist zugleich der
    # Dateiname der Modusseite — die Matrix baut ihren Link daraus.
    'Scramble Kings': 'royal-rotation', 'Kings of the Court': 'royal-shuffle',
    'Leagues': 'league', 'TournaQ Classics': 'group-single-elimination',
    'Swiss Systems': 'swiss-system', 'Other Tournament Modes': 'other-tournament-modes',
}


def newest_export():
    hits = sorted(glob.glob(DOWNLOADS), key=os.path.getmtime, reverse=True)
    if not hits:
        sys.exit('no feature-matrix-*.csv found in ~/Downloads — pass a path instead')
    return hits[0]


def read(path):
    rows = list(csv.reader(open(path, encoding='utf-8')))
    head, body = rows[0], [r for r in rows[1:] if any(c.strip() for c in r)]
    col = {name: i for i, name in enumerate(head)}
    modes = [(i, MODE_COL[n]) for i, n in enumerate(head) if n in MODE_COL]
    if len(modes) != len(MODE_COL):
        sys.exit('expected %d mode columns, found %d — is this a matrix export?'
                 % (len(MODE_COL), len(modes)))

    features, cells, counter, in_live = [], {}, {}, False
    for r in body:
        if 'Section' in col:
            sec = r[col['Section']].strip()
        else:
            sec = PAGE_SECTION[r[col['HTML File']].strip()]
            if sec == 'tournament':
                in_live = in_live or r[col['Title']].strip() == LIVE_STARTS_AT
                sec = 'live' if in_live else sec
        if sec not in SECTION_ORDER:
            sys.exit('unknown section %r' % sec)
        counter[sec] = counter.get(sec, 0) + 1
        fid = '%s-%d' % (sec, counter[sec])
        status = r[col['Status']].strip()
        if status not in STATUS:
            sys.exit('unknown status %r in row %r' % (status, r[col['Title']]))
        features.append({
            'id': fid, 'section': sec, 'status': STATUS[status],
            'title': r[col['Title']].strip(),
            'desc': r[col['Description']].strip(),
            'note': r[col['Note']].strip() if 'Note' in col else '',
        })
        row = {}
        for i, mid in modes:
            v = CELL.get(r[i].strip())
            if v is None:
                sys.exit('unknown cell value %r' % r[i])
            if v:
                row[mid] = v
        if row:
            cells[fid] = row

    # keep sections in page order even if the CSV was reordered
    features.sort(key=lambda f: (SECTION_ORDER.index(f['section']), int(f['id'].split('-')[-1])))
    return features, cells


def js_block(features, cells, source):
    out = ['  var FEATURES = [']
    for f in features:
        out.append('    { id: %s, section: %s, status: %s,' % (
            json.dumps(f['id']), json.dumps(f['section']), json.dumps(f['status'])))
        out.append('      title: %s,' % json.dumps(f['title'], ensure_ascii=False))
        out.append('      desc: %s%s' % (json.dumps(f['desc'], ensure_ascii=False),
                                         ',' if f['note'] else ' },'))
        if f['note']:
            out.append('      note: %s },' % json.dumps(f['note'], ensure_ascii=False))
    out.append('  ];')
    out.append('')
    out.append('    // Availability baked in from %s — regenerate with' % os.path.basename(source))
    out.append('    // python3 tools/bake-feature-matrix.py')
    out.append('    var DEFAULT_CELLS = {')
    keys = [f['id'] for f in features if f['id'] in cells]
    for n, fid in enumerate(keys):
        pairs = ', '.join('%s: %s' % (json.dumps(k), json.dumps(v)) for k, v in cells[fid].items())
        out.append('      %s: { %s }%s' % (json.dumps(fid), pairs, '' if n == len(keys) - 1 else ','))
    out.append('    };')
    return '\n'.join(out)


def bump_storage_key(html):
    """Old browser state keys rows by position, so it must not survive a re-bake."""
    m = re.search(r"var STORAGE_KEY = 'tq-feature-matrix-draft-v(\d+)';", html)
    if not m:
        return html, None
    nxt = int(m.group(1)) + 1
    return html.replace(m.group(0), "var STORAGE_KEY = 'tq-feature-matrix-draft-v%d';" % nxt), nxt


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('csv', nargs='?', help='export to bake (default: newest in ~/Downloads)')
    ap.add_argument('--page', default=DEFAULT_PAGE, help='matrix page to update')
    args = ap.parse_args()

    source = args.csv or newest_export()
    page = args.page if os.path.isabs(args.page) else os.path.join(REPO, args.page)
    features, cells = read(source)

    html = open(page, encoding='utf-8').read()
    new, n = re.subn(r'(?s)  var FEATURES = \[.*?\n    \};', js_block(features, cells, source), html, count=1)
    if n != 1:
        sys.exit('could not find the FEATURES / DEFAULT_CELLS block in ' + page)
    new, version = bump_storage_key(new)
    open(page, 'w', encoding='utf-8').write(new)

    # keep the edit-first working copy in drafts/ byte-identical, so the two never drift
    draft_page = os.path.join(REPO, 'drafts/features/feature-matrix.html')
    if os.path.abspath(page) != draft_page:
        os.makedirs(os.path.dirname(draft_page), exist_ok=True)
        open(draft_page, 'w', encoding='utf-8').write(new)

    # the CSV copy lives in drafts/ (git-ignored) so it never ships with the site
    keep = os.path.join(REPO, 'drafts/features/feature-matrix-data.csv')
    os.makedirs(os.path.dirname(keep), exist_ok=True)
    if not (os.path.exists(keep) and os.path.samefile(source, keep)):  # re-baking the kept copy
        shutil.copy(source, keep)

    per = {}
    for f in features:
        per[f['section']] = per.get(f['section'], 0) + 1
    print('source : %s' % source)
    print('page   : %s' % os.path.relpath(page, REPO))
    print('baked  : %d features (%s)' % (len(features), ', '.join(
        '%s:%d' % (s, per[s]) for s in SECTION_ORDER if s in per)))
    print('         %d filled cells, %d notes' % (sum(len(v) for v in cells.values()),
                                                  sum(1 for f in features if f['note'])))
    if version:
        print('storage: key bumped to v%d (browser state from the old row set is dropped)' % version)
    print('copies : %s' % os.path.relpath(keep, REPO))
    if os.path.abspath(page) != draft_page:
        print('         %s (edit-first working copy)' % os.path.relpath(draft_page, REPO))


if __name__ == '__main__':
    main()
