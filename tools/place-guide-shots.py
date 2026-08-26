#!/usr/bin/env python3
"""Place the app's guide screenshots onto the guide nodes that describe them.

The guide tree already has three nodes per mode — "Setting up a League",
"Running a League", "Scoring a League match" — and until now every one of them
was pure text. This writes the matching `shot(...)` entries into
js/guide/pages.js, once, at a defined position in each node's `blocks` array.

Every mode node has the same skeleton:

    blocks:[ panel, fbox, sect('Every setting on the page'), opts, sect, grid ]

so the shots go **after the fbox and before the first sect** — the picture lands
at the end of the prose and ahead of the option reference tables, which is where
a reader looking for "what does this screen look like" stops.

Idempotent: a node that already carries a `shot('guide/...` for the same source
is left alone, so this can be re-run after adding a mode.

    python3 tools/place-guide-shots.py            # write
    python3 tools/place-guide-shots.py --dry-run  # show what would change

Then `node tools/bake-guide.mjs` to rebuild the pages.
"""
import argparse
import importlib.util
import io
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
PAGES = os.path.join(REPO, 'js/guide/pages.js')

_spec = importlib.util.spec_from_file_location(
    'import_guide_shots', os.path.join(HERE, 'import-guide-shots.py'))
_ig = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_ig)
from PIL import Image  # noqa: E402


# ── The assignment ───────────────────────────────────────────────────────────
#
# node id -> [(source under screenshots/guide_v2, title, body, alt), ...]
#
# Copy is deliberately about what the reader is looking at, not about the mode —
# the surrounding prose already covers the mode.

def scorecard_pair(area, mode, portrait='07_scorecard',
                   landscape='08_scorecard_landscape'):
    """The two shots every set-scoring mode's `-score` node gets."""
    return [
        (f'{area}/{portrait}',
         'The scorecard, top to bottom',
         'A best-of-three match part-way through: the first set decided, the '
         'second one running under the thumbs, the third still to come. Tap a '
         'set in the strip to look back at it without losing the live score.',
         f'A {mode} scorecard mid second set of three'),
        (f'{area}/{landscape}',
         'Turned sideways',
         'Rotate the phone and the same match fills the width — bigger '
         'numbers, both thumbs still in reach. Nothing is hidden in landscape; '
         'it is the same card, laid out for a court-side glance.',
         f'The same {mode} scorecard in landscape'),
    ]


def queue_court_matrix(area, mode):
    """The eight court shots a queue mode's `-score` node gets."""
    return [
        (f'{area}/07_court_manual_assigning',
         'Manual: choosing who comes on',
         'With manual assignment nobody is seated for you. The card offers the '
         'fairest pairings it can find on the left and the whole queue on the '
         'right — one tap on a suggestion starts that side immediately.',
         f'A {mode} court with the manual side picker open'),
        (f'{area}/08_court_manual_assigning_landscape',
         'The picker, sideways',
         'Landscape keeps the suggestions and the roster side by side.',
         f'The {mode} manual picker in landscape'),
        (f'{area}/09_court_manual_running',
         'Manual: the court running',
         'Once a side is seated the picker gives way to the score. There is no '
         'challenger queue here — in manual assignment you decide who comes on '
         'next, so the card shows only the game in front of you.',
         f'A {mode} court running under manual assignment'),
        (f'{area}/10_court_manual_running_landscape',
         'Running, sideways',
         'The same court in landscape, with the eject rail on the edge.',
         f'A running {mode} court in landscape'),
        (f'{area}/11_court_automated',
         'Automated: the queue picks',
         'Automated assignment fills the chain for you: who is on court, who '
         'challenges next, who is up after them. Re-roll if a pairing looks '
         'wrong, and the rest of the queue shuffles up behind it.',
         f'A {mode} court with the automated challenger queue'),
        (f'{area}/12_court_automated_landscape',
         'The queue, sideways',
         'Landscape stacks the chain beside the score instead of above it.',
         f'An automated {mode} court in landscape'),
        (f'{area}/13_court_allplay',
         'Auto All-Play',
         'All-Play adds a third tier and a scorekeeper drawn from outside the '
         'rotation, so everyone at the court has a job. It needs a fuller '
         'court than the other two modes — the queue is longer by a whole side.',
         f'A {mode} court in Auto All-Play with its scorekeeper'),
        (f'{area}/14_court_allplay_landscape',
         'All-Play, sideways',
         'The full chain and the scorekeeper, laid out for the sideline.',
         f'An Auto All-Play {mode} court in landscape'),
    ]


def setup_shot(area, mode, name='03_setup_full'):
    return [(f'{area}/{name}',
             'The whole setup page',
             'Every choice on one screen, scrolled out in full. Defaults are '
             'already sensible — in practice you set the people, the courts '
             'and the time, and leave the rest alone.',
             f'The complete {mode} setup page')]


PLACEMENTS = {
    # ── League ───────────────────────────────────────────────────────────────
    'm-league-hub': setup_shot('08_league', 'League'),
    'm-league-run': [
        ('08_league/04_table',
         'The tournament page',
         'The row of pills under the header is the whole event at a glance — '
         'and most of them are also the way in: Standings, Crosstable and '
         'Allocation open, the padlocked ones tell you what is already fixed.',
         'A running League with its pill row and schedule'),
        ('08_league/06_schedule_by_round',
         'Three ways to read the schedule',
         'Time, Round or Court. The same fixtures, grouped the way you happen '
         'to need them — by when they start, by the round they belong to, or '
         'by which court to walk to.',
         'The League schedule grouped by round'),
        ('08_league/12_crosstable',
         'The crosstable',
         'League’s own view, and the one no other mode has: every team '
         'against every other, with the head-to-head result in the cell. Blank '
         'cells are fixtures still to come.',
         'A half-played League crosstable'),
    ],
    'm-league-score': scorecard_pair('08_league', 'League', '08_scorecard',
                                     '09_scorecard_landscape'),

    # ── Elimination ──────────────────────────────────────────────────────────
    'm-elimination-hub': setup_shot('09_elimination_single', 'Elimination'),
    'm-elimination-run': [
        ('09_elimination_single/04_bracket',
         'The tournament page',
         'The draw as a list, newest round first, with the pill row above it '
         'carrying the event’s shape and its way into standings, the '
         'bracket and court allocation.',
         'A running single-elimination event'),
        ('09_elimination_single/11_standings_bracket',
         'The bracket',
         'The same draw drawn as a tree. Winners feed to the right, and a seat '
         'reads TBD until the match below it is decided. Pinch, or use the '
         'buttons in the corner, to move around a big draw.',
         'A single-elimination bracket with the quarter-finals decided'),
        ('10_elimination_double/04_bracket_canvas',
         'Double elimination',
         'The same view with a losers bracket underneath: one defeat drops a '
         'team to the lower band rather than out, and the two bands meet again '
         'at the grand final.',
         'A double-elimination bracket showing both bands'),
    ],
    'm-elimination-score': scorecard_pair('09_elimination_single',
                                          'Elimination'),

    # ── TournaQ Classic ──────────────────────────────────────────────────────
    'm-classic-hub': setup_shot('11_tournaq_classic', 'TournaQ Classic'),
    'm-classic-run': [
        ('11_tournaq_classic/04_schedule',
         'The tournament page',
         'A Classic runs in two halves, and the page shows whichever one you '
         'are in — group fixtures first, then the knockout draw once the '
         'groups have decided who goes where.',
         'A running TournaQ Classic during its group stage'),
        ('11_tournaq_classic/10_standings_table',
         'Group standings',
         'One table per group, in the order that decides qualification. The '
         'positions that go through are the ones you picked at setup.',
         'TournaQ Classic group tables mid-stage'),
        ('11_tournaq_classic/17_advanced_standings_bracket',
         'Groups feeding the draw',
         'The full shape in one picture: group tables on the left, a connector '
         'from each qualifying place to the seat it fills, and a bracket per '
         'tier. Here four uneven groups feed a Gold and a Silver draw — and '
         'because one group is a team short, Silver carries a real bye.',
         'Group tables feeding Gold and Silver knockout brackets'),
    ],
    'm-classic-score': scorecard_pair('11_tournaq_classic', 'TournaQ Classic'),

    # ── Swiss ────────────────────────────────────────────────────────────────
    'm-swiss-hub': setup_shot('12_swiss_system', 'Swiss System'),
    'm-swiss-run': [
        ('12_swiss_system/04_rounds',
         'The tournament page',
         'Swiss draws one round at a time. Score the round you are in and the '
         'next pairing appears, built from the table as it stands — so there '
         'is never a fixture list running to the end of the day.',
         'A running Swiss System with one round scored'),
        ('12_swiss_system/10_standings_table',
         'The table',
         'What the next round is drawn from. Teams on the same score meet each '
         'other, which is what keeps the pairings competitive without seeding '
         'anybody by hand.',
         'A Swiss System standings table'),
        ('12_swiss_system/11_standings_chart',
         'The ladder',
         'Every team’s path through the rounds, one line each. It is the '
         'quickest way to see who has had the hard draw and who has not.',
         'The Swiss System ladder view'),
    ],
    'm-swiss-score': scorecard_pair('12_swiss_system', 'Swiss System'),

    # ── Social Scramble ──────────────────────────────────────────────────────
    'm-social-scramble-hub': setup_shot('03_social_scramble',
                                        'Social Scramble'),
    'm-social-scramble-run': [
        ('03_social_scramble/04_overview',
         'The tournament page',
         'Rounds down the page, courts across them, and the pill row above '
         'carrying the session’s shape. Everyone’s partner changes '
         'every round, so the schedule is the mode.',
         'A running Social Scramble'),
        ('03_social_scramble/06_overview_by_court',
         'Read it by court',
         'The same rounds regrouped by court, which is what you want when you '
         'are standing on one of them.',
         'A Social Scramble schedule grouped by court'),
        ('03_social_scramble/09_court_allocation',
         'Court allocation',
         'How many courts are in play, and when. Closing one mid-session costs '
         'players rather than minutes, and the grid prices it before you '
         'commit.',
         'The Social Scramble court allocation grid'),
    ],
    'm-social-scramble-score': [
        ('03_social_scramble/07_scorecard',
         'The scorecard, top to bottom',
         'One game, two sides, and the round it belongs to. Scramble games are '
         'scored as a single race rather than in sets, so the card stays down '
         'to the two numbers that matter.',
         'A Social Scramble scorecard mid-game'),
        ('03_social_scramble/08_scorecard_landscape',
         'Turned sideways',
         'The same game across the width of the phone.',
         'A Social Scramble scorecard in landscape'),
    ],

    # ── Royal Rotation ───────────────────────────────────────────────────────
    'm-royal-rotation-hub': setup_shot('04_royal_rotation', 'Royal Rotation'),
    'm-royal-rotation-run': [
        ('04_royal_rotation/04_overview',
         'The tournament page',
         'Rounds and courts, with the queue behind each one. Teams are drawn '
         'fresh every round, so the teams pill is worth a look before play '
         'starts.',
         'A running Royal Rotation'),
        ('04_royal_rotation/06_overview_by_court',
         'Read it by court',
         'The same session grouped by court.',
         'A Royal Rotation schedule grouped by court'),
        ('04_royal_rotation/15_court_allocation',
         'Court allocation',
         'Courts in play across the session, measured in rounds.',
         'The Royal Rotation court allocation grid'),
    ],
    'm-royal-rotation-score': queue_court_matrix('04_royal_rotation',
                                                 'Royal Rotation'),

    # ── Royal Shuffle ────────────────────────────────────────────────────────
    'm-royal-shuffle-hub': setup_shot('06_royal_shuffle', 'Royal Shuffle'),
    'm-royal-shuffle-run': [
        ('06_royal_shuffle/04_overview',
         'The tournament page',
         'Every court and the queue waiting on it. Partners are shuffled for '
         'each new turn on court, so nobody plays the whole session with the '
         'same person.',
         'A running Royal Shuffle'),
        ('06_royal_shuffle/06_overview_by_court',
         'Read it by court',
         'The same session grouped by court.',
         'A Royal Shuffle schedule grouped by court'),
        ('06_royal_shuffle/15_court_allocation',
         'Court allocation',
         'Courts in play across the session. A queue mode honours the court '
         'count down to a minimum you set — below it the queue would stall '
         'rather than shorten.',
         'The Royal Shuffle court allocation grid'),
    ],
    'm-royal-shuffle-score': queue_court_matrix('06_royal_shuffle',
                                                'Royal Shuffle'),

    # ── Doghouse Shuffle ─────────────────────────────────────────────────────
    'm-doghouse-hub': setup_shot('07_doghouse_shuffle', 'Doghouse Shuffle'),
    'm-doghouse-run': [
        ('07_doghouse_shuffle/04_overview',
         'The tournament page',
         'Courts, queue and the two ways out of the doghouse — escape by '
         'reaching the target, or hit the loss limit and be ejected. The pills '
         'carry both thresholds.',
         'A running Doghouse Shuffle'),
        ('07_doghouse_shuffle/06_overview_by_court',
         'Read it by court',
         'The same session grouped by court.',
         'A Doghouse Shuffle schedule grouped by court'),
        ('07_doghouse_shuffle/15_court_allocation',
         'Court allocation',
         'Courts in play across the session.',
         'The Doghouse Shuffle court allocation grid'),
    ],
    'm-doghouse-score': queue_court_matrix('07_doghouse_shuffle',
                                           'Doghouse Shuffle'),

    # ── Royal Duo ────────────────────────────────────────────────────────────
    'm-royal-duo-hub': (
        setup_shot('05_royal_duo', 'Royal Duo')
        + [('05_royal_duo/20_teams_sheet',
            'The duos',
            'What makes this its own mode: partners are fixed for the whole '
            'session. Pair the roster up here, or bring standing teams over '
            'from Administration.',
            'The Royal Duo teams sheet listing standing pairs')]
    ),
    'm-royal-duo-run': [
        ('05_royal_duo/04_overview',
         'The tournament page',
         'Rounds, courts and the queue — the same shape as Royal Rotation, '
         'except the names beside each other never change.',
         'A running Royal Duo'),
        ('05_royal_duo/06_overview_by_court',
         'Read it by court',
         'The same session grouped by court.',
         'A Royal Duo schedule grouped by court'),
        ('05_royal_duo/15_court_allocation',
         'Court allocation',
         'Courts in play across the session, measured in rounds.',
         'The Royal Duo court allocation grid'),
    ],
    'm-royal-duo-score': queue_court_matrix('05_royal_duo', 'Royal Duo'),

    # ── Quick Game — two screens, no running page ─────────────────────────────
    'quick-game-hub': [
        ('02_quick_game/03_quick_start_sheet',
         'Starting a game',
         'Names, format, target score. Nothing is saved until the first point '
         'is scored, so this is a cheap thing to open.',
         'The Quick Game start sheet'),
    ],
    'quick-game-score': [
        ('02_quick_game/08_scorecard_three_sets',
         'A best-of-three, mid match',
         'One set each and the decider under way. The set strip keeps the '
         'finished sets in view while the live one is scored.',
         'A Quick Game scorecard in the deciding set'),
        ('02_quick_game/07_scorecard_landscape',
         'Turned sideways',
         'The same scoreboard across the width of the phone.',
         'A Quick Game scorecard in landscape'),
    ],
}


# ── Rendering ────────────────────────────────────────────────────────────────

def js(text):
    return text.replace('\\', '\\\\').replace("'", "\\'")


def render(rel, title, body, alt):
    full = os.path.join(_ig.DEFAULT_SRC, rel + '.png')
    if not os.path.exists(full):
        sys.exit('no such shot: %s' % rel)
    im = Image.open(full)
    kind, spec = _ig.classify(im.width, im.height)
    if not spec:
        sys.exit('unrecognised frame for %s: %dx%d' % (rel, im.width, im.height))
    if rel + '.png' in _ig.CROPS:
        im = im.crop(_ig.CROPS[rel + '.png'])
    derivs = _ig.derivatives(rel + '.png', im, spec)
    _, w, h = derivs[0]
    widths = ', '.join(str(d[1]) for d in derivs)
    return (
        "    shot('guide/%s',%d,%d,[%s],\n"
        "      '%s',\n"
        "      '%s',\n"
        "      '%s'),\n" % (rel, w, h, widths, js(title), js(body), js(alt))
    )


def block_span(s, node):
    """(start, end) of the node's `blocks:[ ... ]` contents."""
    i = s.index("'%s': {" % node)
    j = s.index('blocks:[', i)
    depth, k = 0, j + len('blocks:[') - 1
    while True:
        if s[k] in '[{(':
            depth += 1
        elif s[k] in ']})':
            depth -= 1
            if depth == 0:
                break
        k += 1
    return j + len('blocks:['), k


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dry-run', action='store_true')
    args = ap.parse_args()

    s = io.open(PAGES, encoding='utf-8').read()
    placed = skipped = 0

    for node, shots in PLACEMENTS.items():
        if "'%s': {" % node not in s:
            sys.exit('no such guide node: %s' % node)
        start, end = block_span(s, node)
        body = s[start:end]

        fresh = [t for t in shots if "shot('guide/%s'" % t[0] not in body]
        skipped += len(shots) - len(fresh)
        if not fresh:
            continue

        chunk = ''.join(render(*t) for t in fresh)

        # After the prose, before the option tables. Falls back to the end of
        # the array for a node with no `sect` divider — Royal Duo is the one.
        m = re.search(r'^\s{4}sect\(', body, re.M)
        at = start + (m.start() if m else len(body.rstrip().rstrip(',')) )
        if not m:
            trimmed = body.rstrip()
            at = start + len(trimmed) + (0 if trimmed.endswith(',') else 0)
            chunk = ('' if trimmed.endswith(',') else ',') + '\n' + chunk
        s = s[:at] + chunk + s[at:]
        placed += len(fresh)
        print('%-26s +%d' % (node, len(fresh)))

    print('\nplaced %d, already present %d' % (placed, skipped))
    if args.dry_run:
        print('(dry run, nothing written)')
        return
    io.open(PAGES, 'w', encoding='utf-8').write(s)
    print('wrote %s — now run: node tools/bake-guide.mjs' % PAGES)


if __name__ == '__main__':
    main()
