#!/usr/bin/env python3
"""Emit guide-card sections for a walkthrough page from a small JSON spec.

The copy on these pages is written by hand; what is not worth writing by hand
is the image markup — srcset, sizes, intrinsic width/height, lazy loading, and
the decision about whether a shot is too long to sit in a card. Getting one of
those wrong on one of ~200 images is easy and invisible, so the spec carries
the words and this fills in the mechanics.

    python3 tools/build-guide-section.py spec.json

Spec shape:

    {"depth": 2, "folder": "03_social_scramble",
     "sections": [
       {"id": "setup", "title": "...", "text": "...", "cols": 3, "cards": [
          {"h": "Card heading", "p": "Card body.", "shot": "02_setup"},
          {"h": "...", "p": "...", "shot": "90_features/03_match_details_sheet"},
          {"h": "...", "p": "...", "shot": "08_scorecard_landscape", "wide": true}
       ]}
     ]}

`shot` is resolved against `folder` unless it already contains a slash. A shot
whose aspect is taller than the card can show is wrapped in .shot-scroll
automatically; `wide` spans the card across the grid for landscape shots.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib
_imp = importlib.import_module('import-guide-shots')
Image, CROPS, classify, derivatives = _imp.Image, _imp.CROPS, _imp.classify, _imp.derivatives
DEFAULT_SRC, LONG_ASPECT = _imp.DEFAULT_SRC, _imp.LONG_ASPECT

CARD_SIZES = '(max-width: 760px) 90vw, 280px'
WIDE_SIZES = '(max-width: 760px) 92vw, 1120px'
SPLIT_SIZES = '(max-width: 1040px) 45vw, 240px'


def shot_markup(rel, depth, alt, wide, indent, sizes=None):
    path = os.path.join(DEFAULT_SRC, rel + '.png')
    if not os.path.exists(path):
        raise SystemExit('no such shot: %s' % rel)
    src = Image.open(path)
    _, spec = classify(*src.size)
    im = src.crop(CROPS[rel + '.png']) if rel + '.png' in CROPS else src
    derivs = derivatives(rel + '.png', im, spec)
    base = '../' * depth + 'assets/guide/'
    small = derivs[0]
    aspect = small[2] / small[1]
    long_shot = aspect > LONG_ASPECT

    pad = ' ' * indent
    srcset = (',\n' + pad + '        ').join(
        '%s%s %dw' % (base, d[0], d[1]) for d in derivs)
    # .vertical caps a portrait phone screen so it does not tower over its card.
    # A landscape shot needs the opposite — the cap would shrink it to a stamp.
    portrait = aspect > 1
    cls = ' class="vertical"' if (portrait and not wide and not long_shot) else ''
    if not portrait and sizes is None:
        sizes = '(max-width: 760px) 90vw, 380px'
    img = (
        '%s<img src="%s%s"\n'
        '%s     srcset="%s"\n'
        '%s     sizes="%s"\n'
        '%s     width="%d" height="%d"\n'
        '%s     loading="lazy" decoding="async"%s\n'
        '%s     alt="%s">'
        % (pad, base, small[0], pad, srcset, pad,
           sizes or (WIDE_SIZES if wide else CARD_SIZES),
           pad, small[1], small[2], pad, cls, pad, alt))

    if long_shot:
        inner = '\n'.join('  ' + line for line in img.split('\n'))
        return ('%s<div class="shot-scroll">\n%s\n%s</div>' % (pad, inner, pad))
    return img


def main():
    spec = json.load(open(sys.argv[1], encoding='utf-8'))
    depth, folder = spec.get('depth', 2), spec.get('folder', '')
    out = []

    for sec in spec['sections']:
        grid = 'guide-grid-2' if sec.get('cols') == 2 else 'guide-grid'
        out.append('    <!-- %s -->' % sec['title'])
        out.append('    <section id="%s" style="margin-top: 40px;">' % sec['id'])
        out.append('      <h2 class="section-title">%s</h2>' % sec['title'])
        out.append('      <p class="section-text">%s</p>' % sec['text'])
        out.append('')
        if sec.get('split'):
            # screenshot in a fixed column with the words beside it, rather than
            # stacked above them — two cards per row so a wide page stays filled
            out.append('      <div class="guide-split-grid">')
            for card in sec['cards']:
                rel = card['shot'] if '/' in card['shot'] else '%s/%s' % (folder, card['shot'])
                out.append('      <div class="guide-card guide-split">')
                out.append('        <div class="split-media">')
                out.append(shot_markup(rel, depth, card.get('alt', ''), False, 10,
                                       sizes=SPLIT_SIZES))
                out.append('        </div>')
                out.append('        <div class="split-copy">')
                out.append('          <h3>%s</h3>' % card['h'])
                for para in card['p'] if isinstance(card['p'], list) else [card['p']]:
                    out.append('          <p>%s</p>' % para)
                out.append('        </div>')
                out.append('      </div>')
            out.append('      </div>')
            out.append('    </section>')
            out.append('')
            continue

        out.append('      <div class="%s">' % grid)
        for card in sec['cards']:
            rel = card['shot'] if '/' in card['shot'] else '%s/%s' % (folder, card['shot'])
            style = ' style="grid-column: 1 / -1"' if card.get('wide') else ''
            out.append('        <div class="guide-card"%s>' % style)
            out.append('          <h3>%s</h3>' % card['h'])
            out.append('          <p>%s</p>' % card['p'])
            out.append(shot_markup(rel, depth, card.get('alt', ''),
                                   card.get('wide', False), 10))
            out.append('        </div>')
        out.append('      </div>')
        out.append('    </section>')
        out.append('')

    print('\n'.join(out))


if __name__ == '__main__':
    main()
