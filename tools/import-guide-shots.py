#!/usr/bin/env python3
"""Import the Flutter guide screenshots into the site as sized WebP derivatives.

The app generates its documentation set with

    flutter test test/screenshots/*_shots.dart

which writes ~194 PNGs (36 MB) to tournaq/screenshots/guide/. Those are far too
big to ship: a 860x1864 phone screen is rendered on the site at 145-230 CSS px.
This script converts every shot to the handful of widths the site actually uses,
so the loop

    regenerate in the app  ->  import  ->  reload the page

is one command each time. Output mirrors the source tree, so the guide README
stays a valid map of what is on the site:

    guide/03_social_scramble/07_scorecard.png
      -> assets/guide/03_social_scramble/07_scorecard-430.webp
      -> assets/guide/03_social_scramble/07_scorecard-645.webp

Widths come from the frame the generator used (see CLASSES), not from a fixed
list — a rolling capture is natively 645 wide and upscaling it would be a lie.

    python3 tools/import-guide-shots.py                  # everything new or changed
    python3 tools/import-guide-shots.py --only 07_league # one folder
    python3 tools/import-guide-shots.py --check          # CI: stale? dead refs?
    python3 tools/import-guide-shots.py snippet 00_shell/04_arena --slot card

Re-runs are cheap: a manifest keyed on the source SHA-256 skips anything that
has not moved. The generator is byte-reproducible for all but three shots that
drive a live stopwatch, so a re-import after regeneration only touches what
actually changed in the UI.
"""
import argparse
import hashlib
import json
import os
import re
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit('Pillow is required: pip3 install --user Pillow')

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_SRC = os.path.join(os.path.dirname(REPO), 'tournaq/screenshots/guide')
OUT = os.path.join(REPO, 'assets/guide')
MANIFEST = os.path.join(OUT, '.import-manifest.json')
SKIP_DIRS = {'_smoke'}

# Frame classes, keyed by the exact size the generator emits. `widths` are the
# derivatives to write; never wider than the source, or we would be upscaling.
CLASSES = {
    'phone':     {'match': lambda w, h: w == 860 and h > w,   'widths': [430, 860],       'q': 80},
    'rolling':   {'match': lambda w, h: w == 645,             'widths': [430, 645],       'q': 80},
    'landscape': {'match': lambda w, h: w == 1864 and h == 860, 'widths': [860, 1600],    'q': 80},
    'canvas':    {'match': lambda w, h: w == 2560 and h == 1800, 'widths': [860, 1600],   'q': 85},
    'marketing': {'match': lambda w, h: w == 1320 and h == 2868, 'widths': [430, 860, 1280], 'q': 82},
}

# The pan/zoom canvas views are mostly empty space — the diagram floats in the
# middle with an app bar above it and zoom controls in the bottom-right corner.
# Cropping is what makes them legible at 430-860 px, and auto-detection is not
# trustworthy here (the app bar spans the full width, the FABs anchor a corner),
# so each one carries an explicit box. Regenerate suggestions with --suggest-crop.
CROPS = {
    '07_league/12_crosstable.png':                          (415, 447, 2144, 1463),
    '08_elimination_single/11_standings_bracket.png':       (208, 471, 1810, 1494),
    '09_elimination_double/04_bracket_canvas.png':          (136, 393, 2041, 1536),
    '09_elimination_double/05_bracket_completed.png':       (136, 422, 2423, 1536),
    '10_tournaq_classic/11_standings_bracket.png':          (146, 646, 1957, 1401),
    '10_tournaq_classic/13_final_standings.png':            (146, 646, 2413, 1401),
    '10_tournaq_classic/17_advanced_standings_bracket.png': (229, 349, 1981, 1713),
    '10_tournaq_classic/18_advanced_final_standings.png':   (229, 369, 2330, 1713),
    # cropped above the in-image legend — it is reproduced as the figcaption
    '11_swiss_system/11_standings_chart.png':               (115, 507, 2386, 1470),
}

# Brand art. Not screenshots, but the same problem: the logo ships 2.1 MB to
# paint a 225x150 box on every page, and the header banner ships 1.9 MB to sit
# under a 65%-opaque gradient that hides most of it.
BRAND = [
    ('assets/tournaq_logo_transparent_land.png', 'assets/brand/tournaq-logo-land-450.webp', 450, 85),
    ('assets/tournaq-background-banner-2.png',   'assets/brand/tournaq-banner-1871.webp', 1871, 85),
]

# `sizes` presets matching the site's real CSS slots, so a phone downloads the
# small derivative instead of the retina one.
SLOTS = {
    'format':    '(max-width: 760px) 90vw, 170px',
    'showcase':  '(max-width: 760px) 90vw, 145px',
    'card':      '(max-width: 760px) 90vw, 230px',
    'explainer': '(max-width: 860px) 92vw, 850px',
    'hero':      '(max-width: 760px) 90vw, 380px',
    'full':      '100vw',
}

# Anything taller than this relative to its width needs the .shot-scroll wrapper
# rather than being dropped into a card at full height.
LONG_ASPECT = 2.6


def classify(w, h):
    for name, spec in CLASSES.items():
        if spec['match'](w, h):
            return name, spec
    return None, None


def sources(src, only):
    for folder in sorted(os.listdir(src)):
        d = os.path.join(src, folder)
        if not os.path.isdir(d) or folder in SKIP_DIRS:
            continue
        if only and folder not in only:
            continue
        for name in sorted(os.listdir(d)):
            if name.lower().endswith('.png'):
                yield '%s/%s' % (folder, name), os.path.join(d, name)


def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def load_manifest():
    try:
        with open(MANIFEST, encoding='utf-8') as fh:
            return json.load(fh)
    except (IOError, ValueError):
        return {}


def stamp_for(rel, digest, width, spec):
    """The manifest entry identifying one derivative's inputs.

    `crop` is a list, not the tuple it comes from: the manifest round-trips
    through JSON, which has no tuples, so a tuple would never compare equal on
    reload and every cropped shot would re-encode on every run.
    """
    crop = CROPS.get(rel)
    return {'sha': digest, 'crop': list(crop) if crop else None,
            'w': width, 'q': spec['q']}


def derivatives(rel, im, spec):
    """(output_rel_path, width, height) for each derivative of one source."""
    stem = rel[:-4]
    out = []
    for w in spec['widths']:
        if w > im.width:
            continue
        h = max(1, round(im.height * w / im.width))
        out.append(('%s-%d.webp' % (stem, w), w, h))
    return out


def convert(rel, path, spec, force, manifest):
    """Write every derivative of one source. Returns (written, total_bytes)."""
    digest = sha(path)
    im = Image.open(path)
    if rel in CROPS:
        im = im.crop(CROPS[rel])
    im = im.convert('RGBA' if 'A' in im.getbands() else 'RGB')

    written, total = 0, 0
    for out_rel, w, h in derivatives(rel, im, spec):
        dest = os.path.join(OUT, out_rel)
        stamp = stamp_for(rel, digest, w, spec)
        if not force and manifest.get(out_rel) == stamp and os.path.exists(dest):
            total += os.path.getsize(dest)
            continue
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        im.resize((w, h), Image.LANCZOS).save(
            dest, 'WEBP', quality=spec['q'], method=6)
        manifest[out_rel] = stamp
        written += 1
        total += os.path.getsize(dest)
    return written, total


def cmd_import(args):
    src = args.src or DEFAULT_SRC
    if not os.path.isdir(src):
        sys.exit('source not found: %s (pass --src)' % src)
    manifest = {} if args.force else load_manifest()
    only = set(args.only or [])

    per_class, written, total, count = {}, 0, 0, 0
    for rel, path in sources(src, only):
        with Image.open(path) as probe:
            name, spec = classify(probe.width, probe.height)
        if not spec:
            print('  ?? unknown frame %dx%d — skipped: %s'
                  % (probe.width, probe.height, rel))
            continue
        w, b = convert(rel, path, spec, args.force, manifest)
        written += w
        total += b
        count += 1
        agg = per_class.setdefault(name, [0, 0])
        agg[0] += 1
        agg[1] += b

    os.makedirs(OUT, exist_ok=True)
    with open(MANIFEST, 'w', encoding='utf-8') as fh:
        json.dump(manifest, fh, indent=1, sort_keys=True)

    print('source : %s' % src)
    print('output : %s' % os.path.relpath(OUT, REPO))
    for name in sorted(per_class):
        n, b = per_class[name]
        print('  %-10s %3d files -> %6.2f MB' % (name, n, b / 1e6))
    print('total  : %d sources, %d derivatives written, %.2f MB on disk'
          % (count, written, total / 1e6))
    if not written:
        print('         (everything already up to date)')


def cmd_brand(args):
    total = 0
    for src_rel, out_rel, width, q in BRAND:
        src = os.path.join(REPO, src_rel)
        if not os.path.exists(src):
            print('  !! missing %s' % src_rel)
            continue
        dest = os.path.join(REPO, out_rel)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        im = Image.open(src)
        im = im.convert('RGBA' if 'A' in im.getbands() else 'RGB')
        h = max(1, round(im.height * width / im.width))
        im.resize((width, h), Image.LANCZOS).save(dest, 'WEBP', quality=q, method=6)
        before, after = os.path.getsize(src), os.path.getsize(dest)
        total += after
        print('  %-46s %7.0f KB -> %6.1f KB  (%dx%d)'
              % (out_rel, before / 1e3, after / 1e3, width, h))
    print('brand total: %.1f KB' % (total / 1e3))


def cmd_suggest_crop(args):
    """Content bbox of a canvas shot, ignoring the app bar and the zoom FABs."""
    src = args.src or DEFAULT_SRC
    path = os.path.join(src, args.target)
    im = Image.open(path).convert('RGB')
    w, h = im.size

    # Drop the app bar: it is a solid full-width band, so scan down until a row
    # stops matching the colour of the very first pixel.
    bar = im.getpixel((0, 0))
    top = 0
    for y in range(h):
        if im.getpixel((w // 2, y)) != bar:
            top = y
            break

    # Blank the zoom FABs in the bottom-right so they cannot pin the bbox open.
    body = im.crop((0, top, w, h)).copy()
    fab_x, fab_y = int(w * 0.86), int(body.height * 0.72)
    body.paste(body.getpixel((5, body.height - 5)),
               (fab_x, fab_y, body.width, body.height))

    bg = Image.new('RGB', body.size, body.getpixel((5, body.height - 5)))
    from PIL import ImageChops
    box = ImageChops.difference(body, bg).convert('L').point(
        lambda v: 255 if v > 12 else 0).getbbox()
    if not box:
        sys.exit('no content found — is this a canvas shot?')

    pad = args.pad
    x0 = max(0, box[0] - pad)
    y0 = max(0, box[1] + top - pad)
    x1 = min(w, box[2] + pad)
    y1 = min(h, box[3] + top + pad)
    print("    '%s': (%d, %d, %d, %d),   # %dx%d  aspect %.2f"
          % (args.target, x0, y0, x1, y1, x1 - x0, y1 - y0, (x1 - x0) / (y1 - y0)))


def cmd_snippet(args):
    src = args.src or DEFAULT_SRC
    rel = args.target if args.target.endswith('.png') else args.target + '.png'
    path = os.path.join(src, rel)
    if not os.path.exists(path):
        sys.exit('no such shot: %s' % rel)

    im = Image.open(path)
    if rel in CROPS:
        im = im.crop(CROPS[rel])
    _, spec = classify(*Image.open(path).size)
    derivs = derivatives(rel, im, spec)
    base = '../' * args.depth + 'assets/guide/'

    small = derivs[0]
    srcset = ',\n             '.join('%s%s %dw' % (base, d[0], d[1]) for d in derivs)
    aspect = small[2] / small[1]
    cls = (' class="%s"' % args.cls) if args.cls else ''
    loading = 'eager" fetchpriority="high' if args.eager else 'lazy'

    print('<img src="%s%s"' % (base, small[0]))
    print('     srcset="%s"' % srcset)
    print('     sizes="%s"' % SLOTS[args.slot])
    print('     width="%d" height="%d"' % (small[1], small[2]))
    print('     loading="%s" decoding="async"%s' % (loading, cls))
    print('     alt="%s">' % args.alt)
    if aspect > LONG_ASPECT:
        print('<!-- aspect 1:%.1f — wrap in <div class="shot-scroll"> -->' % aspect)


def cmd_check(args):
    """Exit 1 if derivatives are stale, images are missing, or tags lack hints."""
    src = args.src or DEFAULT_SRC
    problems = []

    manifest = load_manifest()
    if os.path.isdir(src):
        for rel, path in sources(src, None):
            with Image.open(path) as probe:
                _, spec = classify(probe.width, probe.height)
            if not spec:
                continue
            im = Image.open(path)
            if rel in CROPS:
                im = im.crop(CROPS[rel])
            digest = sha(path)
            for out_rel, w, _ in derivatives(rel, im, spec):
                stamp = stamp_for(rel, digest, w, spec)
                if not os.path.exists(os.path.join(OUT, out_rel)):
                    problems.append('missing derivative: %s' % out_rel)
                elif manifest.get(out_rel) != stamp:
                    problems.append('stale derivative: %s' % out_rel)
    else:
        print('note: source tree absent, skipping staleness check (%s)' % src)

    img_re = re.compile(r'<img\b[^>]*>', re.I | re.S)
    src_re = re.compile(r'\bsrc="([^"]+)"')
    for root, _, files in os.walk(os.path.join(REPO, 'pages')):
        for name in files:
            if not name.endswith('.html'):
                continue
            page = os.path.join(root, name)
            rel_page = os.path.relpath(page, REPO)
            with open(page, encoding='utf-8') as fh:
                html = fh.read()
            for tag in img_re.findall(html):
                m = src_re.search(tag)
                if not m:
                    continue
                target = m.group(1)
                if target.startswith(('http://', 'https://', 'data:')):
                    continue
                resolved = os.path.normpath(os.path.join(os.path.dirname(page), target))
                if not os.path.exists(resolved):
                    problems.append('%s: dead image reference %s' % (rel_page, target))
                for attr in ('width=', 'height=', 'loading='):
                    if attr not in tag:
                        problems.append('%s: <img %s> missing %s'
                                        % (rel_page, target, attr.rstrip('=')))

    for p in problems:
        print('  !! %s' % p)
    print('%d problem(s)' % len(problems))
    return 1 if problems else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('command', nargs='?', default='import',
                    choices=['import', 'brand', 'check', 'snippet', 'suggest-crop'])
    ap.add_argument('target', nargs='?', help='shot path, for snippet / suggest-crop')
    ap.add_argument('--src', help='guide/ source root (default: ../tournaq/screenshots/guide)')
    ap.add_argument('--only', nargs='*', help='limit to these folders')
    ap.add_argument('--force', action='store_true', help='ignore the manifest and re-encode')
    ap.add_argument('--slot', default='card', choices=sorted(SLOTS), help='snippet: CSS slot')
    ap.add_argument('--depth', type=int, default=2, help='snippet: ../ levels up to the repo root')
    ap.add_argument('--alt', default='', help='snippet: alt text')
    ap.add_argument('--cls', default='', help='snippet: class attribute')
    ap.add_argument('--eager', action='store_true', help='snippet: mark as the LCP image')
    ap.add_argument('--pad', type=int, default=30, help='suggest-crop: padding in px')
    args = ap.parse_args()

    if args.command in ('snippet', 'suggest-crop') and not args.target:
        sys.exit('%s needs a shot path, e.g. 00_shell/04_arena' % args.command)

    if args.command == 'import':
        cmd_import(args)
    elif args.command == 'brand':
        cmd_brand(args)
    elif args.command == 'check':
        sys.exit(cmd_check(args))
    elif args.command == 'snippet':
        cmd_snippet(args)
    elif args.command == 'suggest-crop':
        cmd_suggest_crop(args)


if __name__ == '__main__':
    main()
