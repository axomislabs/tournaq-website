#!/usr/bin/env python3
"""Print ready-to-paste `shot(...)` lines for js/guide/pages.js.

`shot(src, w, h, sizes, title, body, alt)` carries the derivative widths that
are actually on disk and a width/height pair holding the aspect ratio, so the
page reserves the right box and nothing jumps as the image loads. Neither is
guessable for a rolling capture, whose height is whatever the page scrolled to —
`08_league/03_setup_full` and `12_swiss_system/03_setup_full` are both 430 wide
and 500px apart in height.

So read them off the source instead of typing them, reusing the importer's own
`classify` / `derivatives` rather than a second copy of the size rules.

    python3 tools/shot-entries.py 08_league            # a whole folder
    python3 tools/shot-entries.py 08_league/04_table   # one shot

Titles and bodies come out as `TODO` on purpose: they are the editorial half of
a shot and belong to whoever is writing that guide section. This tool gets the
mechanical half right.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# The importer's filename has a dash, so it cannot be imported by name.
import importlib.util

_spec = importlib.util.spec_from_file_location(
    'import_guide_shots',
    os.path.join(os.path.dirname(os.path.abspath(__file__)),
                 'import-guide-shots.py'),
)
_ig = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_ig)

from PIL import Image  # noqa: E402  (after the spec load, which needs no PIL)


def entries(target):
    src = _ig.DEFAULT_SRC
    path = os.path.join(src, target)

    if os.path.isdir(path):
        rels = [os.path.join(target, f) for f in sorted(os.listdir(path))
                if f.endswith('.png')]
    else:
        rels = [target if target.endswith('.png') else target + '.png']

    for rel in rels:
        full = os.path.join(src, rel)
        if not os.path.exists(full):
            sys.exit('no such shot: %s' % rel)

        im = Image.open(full)
        kind, spec = _ig.classify(im.width, im.height)
        if not spec:
            print('  // %s: unrecognised frame %dx%d' % (rel, im.width, im.height))
            continue
        if rel in _ig.CROPS:
            im = im.crop(_ig.CROPS[rel])

        derivs = _ig.derivatives(rel, im, spec)
        widths = [d[1] for d in derivs]
        _, w, h = derivs[0]

        stem = rel[:-4]
        name = stem.split('/')[-1]
        print("    shot('guide/%s',%d,%d,%s," % (stem, w, h, widths))
        print("      'TODO title',")
        print("      'TODO body.',")
        print("      'TODO alt: %s'),  // %s" % (name.replace('_', ' '), kind))


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    entries(sys.argv[1])
