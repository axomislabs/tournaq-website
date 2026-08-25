#!/usr/bin/env python3
"""Read guide-content.csv back into pages/guide.html.

Counterpart to tools/export-guide-content.py. Matching is by the ID column,
never by position, so rows may be re-sorted or filtered in Excel without
breaking anything. Only rows whose Text actually changed are touched, and each
replacement must resolve to exactly one string literal inside that page's own
block — otherwise the run aborts before writing, so a bad match can never
half-apply.

    python3 tools/import-guide-content.py --dry-run   # show what would change
    python3 tools/import-guide-content.py             # write it

Rows with an ID that does not exist yet (content you added) are reported and
skipped: new blocks need a structural decision, not a string swap.
"""
import csv, io, os, re, subprocess, sys

ROOT  = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GUIDE = os.path.join(ROOT, 'pages', 'guide.html')
CSV   = os.path.join(ROOT, 'guide-content.csv')
EXPORT = os.path.join(ROOT, 'tools', 'export-guide-content.py')

norm = lambda s: re.sub(r'\s+', ' ', s).strip()


def baseline():
    """Re-export into a temp copy to learn each ID's current text."""
    import tempfile, shutil
    out = os.path.join(ROOT, 'guide-content.csv')
    keep = None
    if os.path.exists(out):
        keep = tempfile.mktemp(suffix='.csv'); shutil.copy(out, keep)
    subprocess.check_call([sys.executable, EXPORT], stdout=subprocess.DEVNULL)
    base = {r['ID']: r['Text']
            for r in csv.DictReader(io.open(out, encoding='utf-8-sig'))}
    if keep:
        shutil.move(keep, out)
    return base


def page_span(src, pid):
    """Byte range of one page's object literal inside guide.html."""
    m = re.search(r"(?m)^'?" + re.escape(pid) + r"'?:\s*\{", src)
    if not m:
        return None
    end = src.index('\n},', m.end())
    return m.start(), end


def js_literals(chunk):
    """Every single-quoted JS string literal in a chunk, with its span."""
    return [(m.start(), m.end(), m.group(1))
            for m in re.finditer(r"'((?:[^'\\]|\\.)*)'", chunk)]


def main():
    dry = '--dry-run' in sys.argv
    src = io.open(GUIDE, encoding='utf-8').read()
    base = baseline()

    edits, missing, unresolved = [], [], []

    for r in csv.DictReader(io.open(CSV, encoding='utf-8-sig')):
        rid, new = r['ID'], norm(r['Text'])
        if rid not in base:
            missing.append(rid); continue
        old = norm(base[rid])
        if old == new or not new:
            continue

        pid  = rid.split('/')[0]
        span = page_span(src, pid)
        if not span:
            unresolved.append((rid, 'Seite %s nicht gefunden' % pid)); continue

        chunk = src[span[0]:span[1]]
        hits  = [(s, e, lit) for s, e, lit in js_literals(chunk)
                 if norm(lit.replace("\\'", "'")) == old]
        if len(hits) != 1:
            unresolved.append((rid, '%d Treffer statt 1' % len(hits))); continue

        s, e, _ = hits[0]
        edits.append((span[0] + s, span[0] + e, new, rid, old))

    for pos, end, new, rid, old in sorted(edits, reverse=True):
        esc = new.replace('\\', '\\\\').replace("'", "\\'")
        print('  %-30s %s\n%s-> %s' % (rid, old[:60], ' ' * 33, new[:60]))
        if not dry:
            src = src[:pos] + "'" + esc + "'" + src[end:]

    print('\n%d Änderung(en)%s' % (len(edits), ' (dry-run)' if dry else ''))
    if missing:
        print('%d neue ID(s) — übersprungen, brauchen einen echten Block:' % len(missing))
        for m in missing[:10]:
            print('   ', m)
    if unresolved:
        print('ABBRUCH — %d Zeile(n) nicht eindeutig zuordenbar:' % len(unresolved))
        for rid, why in unresolved:
            print('   ', rid, '·', why)
        sys.exit(1)

    if not dry and edits:
        io.open(GUIDE, 'w', encoding='utf-8').write(src)
        print('geschrieben:', os.path.relpath(GUIDE, ROOT))


if __name__ == '__main__':
    main()
