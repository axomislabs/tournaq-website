#!/usr/bin/env python3
"""Apply a copy-review CSV back into the specs, and surface the comments.

Companion to build-review.py. The review page exports only the rows you
touched; this walks them, writes every edit into the spec field it came from,
rebuilds the affected pages, and prints the comments and flags so the things
that need a human decision are not buried among the mechanical replacements.

    python3 tools/apply-review.py                     # newest in ~/Downloads
    python3 tools/apply-review.py path/to.csv
    python3 tools/apply-review.py --dry-run           # show, change nothing

Edits are applied only where the CSV's Original still matches what the spec
says. If a string moved on since the export, the row is reported as stale
rather than overwriting newer wording with older wording.
"""
import argparse
import csv
import glob
import json
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPECS = os.path.join(REPO, 'tools/specs')
DOWNLOADS = os.path.expanduser('~/Downloads/copy-review-*.csv')


def newest_export():
    hits = sorted(glob.glob(DOWNLOADS), key=os.path.getmtime, reverse=True)
    if not hits:
        sys.exit('no copy-review-*.csv in ~/Downloads — pass a path instead')
    return hits[0]


def resolve(spec, path):
    """Walk a spec by the review page's path, returning (container, key)."""
    parts = path.split('/')
    node = spec
    for part in parts[:-1]:
        node = node[int(part)] if part.isdigit() else node[part]
    last = parts[-1]
    return node, (int(last) if last.isdigit() else last)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('csv', nargs='?', help='review export (default: newest in ~/Downloads)')
    ap.add_argument('--dry-run', action='store_true')
    args = ap.parse_args()

    source = args.csv or newest_export()
    rows = list(csv.DictReader(open(source, encoding='utf-8')))
    if not rows:
        sys.exit('%s has no rows' % source)

    specs, applied, stale, missing = {}, [], [], []
    notes = []

    for r in rows:
        slug, path = r['Page'], r['Path']
        if slug not in specs:
            p = os.path.join(SPECS, slug + '.json')
            if not os.path.exists(p):
                missing.append(slug)
                continue
            specs[slug] = json.load(open(p, encoding='utf-8'))
        spec = specs.get(slug)
        if spec is None:
            continue

        if r.get('Comment') or r.get('Flag'):
            notes.append(r)

        edited = (r.get('Edited') or '').strip()
        if not edited:
            continue
        try:
            node, key = resolve(spec, path)
            current = node[key]
        except (KeyError, IndexError, ValueError):
            stale.append((slug, path, 'path no longer exists'))
            continue
        if current != r['Original']:
            stale.append((slug, path, 'text changed since export'))
            continue
        node[key] = edited
        applied.append((slug, path, r['Original'], edited))

    print('source : %s' % source)
    print('rows   : %d touched' % len(rows))

    if applied and not args.dry_run:
        for slug in sorted({a[0] for a in applied}):
            p = os.path.join(SPECS, slug + '.json')
            json.dump(specs[slug], open(p, 'w', encoding='utf-8'), indent=2, ensure_ascii=False)
        targets = [os.path.join(SPECS, s + '.json') for s in sorted({a[0] for a in applied})]
        subprocess.run([sys.executable, os.path.join(REPO, 'tools/build-guide-page.py')] + targets,
                       check=True, cwd=REPO)

    print('edits  : %d applied%s' % (len(applied), ' (dry run)' if args.dry_run else ''))
    for slug, path, was, now in applied:
        print('         %s %s' % (slug, path))
        print('           - %s' % was[:96])
        print('           + %s' % now[:96])

    if stale:
        print('stale  : %d row(s) skipped — re-export and redo these' % len(stale))
        for slug, path, why in stale:
            print('         %-28s %-34s %s' % (slug, path, why))
    if missing:
        print('unknown: no spec for %s' % ', '.join(sorted(set(missing))))

    if notes:
        print('')
        print('comments — these need a decision, nothing was changed for them:')
        for r in notes:
            flag = (' [%s]' % r['Flag']) if r.get('Flag') else ''
            print('  %s %s%s' % (r['Page'], r['Path'], flag))
            print('    field   : %s%s' % (r['Field'],
                                          ('  ·  ' + r['Screenshot']) if r.get('Screenshot') else ''))
            print('    text    : %s' % (r['Original'] or '')[:110])
            if r.get('Comment'):
                print('    comment : %s' % r['Comment'])
    else:
        print('comments: none')


if __name__ == '__main__':
    main()
