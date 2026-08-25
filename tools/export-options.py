#!/usr/bin/env python3
"""setup-options.md and tournament-options.md → their CSV twins.

The markdown files are the source of truth — they are what gets read and edited.
This flattens their tables into one spreadsheet each, so the whole option set can
be reviewed in a single sort, the way guide-content.csv does for the guide copy.

A table is picked up when its header row matches one of the shapes below; the
prose tables that only point at source files are skipped, because they list
files rather than options. Every row is stamped with the H1 and H2 it sits
under, which is what makes the flat file navigable again.

Replaces tools/export-setup-options.py, which only knew the setup file.
"""
import csv
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# md → (csv, [table shapes]). A shape is the header row as it appears in the
# file; the CSV takes those same names, after Seite and Abschnitt.
SOURCES = {
    'setup-options.md': (
        'setup-options.csv',
        [
            ['Einstellung', 'Werte / Presets', 'Default', 'Grenzen',
             'Bedingungen & Warnungen', 'Wofür', 'Hilfetext in der App (wörtlich)'],
            # 0.5's roster table asks the same seven questions about things
            # that are not settings, so it heads its first column differently.
            ['Element', 'Werte / Presets', 'Default', 'Grenzen',
             'Bedingungen & Warnungen', 'Wofür', 'Hilfetext in der App (wörtlich)'],
            ['Fall', 'Meldung in der App (wörtlich)', 'Blockiert Create'],
        ],
    ),
    'scorecard-options.md': (
        'scorecard-options.csv',
        [
            ['Bedienelement', 'Was es tut', 'Wann sichtbar / Bedingung',
             'Text in der App (wörtlich)'],
            ['Modus', 'Besonderheit', 'Text in der App (wörtlich)'],
        ],
    ),
    'tournament-options.md': (
        'tournament-options.csv',
        [
            ['Element', 'Beschriftung in der App', 'Aktion', 'Bearbeitbar hier?',
             'Bedingung / Sperrgrund', 'Wofür'],
            ['Element', 'Wo', 'Was es tut', 'Bedingung'],
            ['Sheet', 'Datei', 'Was darin geht', 'Grenzen'],
            ['Grund', 'Text in der App (wörtlich)', 'Wann'],
            ['Action', 'Glyph', 'Farbe', 'Bedeutung'],
        ],
    ),
}

DIVIDER = re.compile(r'\|[\s:|-]+\|')


def cells(line):
    return [c.strip() for c in line.strip().strip('|').split('|')]


def rows_of(md, shapes):
    """(page, section, shape, cells) for every data row under a known shape."""
    page = section = ''
    shape = None
    # The first column of a header is enough to recognise it, except where two
    # shapes share one ('Element'), so match the whole row.
    for line in md.read_text().splitlines():
        if line.startswith('# '):
            page, section, shape = line[2:].strip(), '', None
        elif line.startswith('## '):
            section, shape = line[3:].strip(), None
        elif not line.startswith('|'):
            shape = None
        elif DIVIDER.fullmatch(line.strip()):
            continue
        else:
            c = cells(line)
            if c in shapes:
                shape = c
            elif shape is not None and len(c) == len(shape):
                yield page, section, shape, c


def main():
    total = 0
    for name, (out_name, shapes) in SOURCES.items():
        md = ROOT / name
        if not md.exists():
            print(f'übersprungen: {name} fehlt', file=sys.stderr)
            continue

        # One CSV per source, with the widest shape's names as its columns —
        # narrower shapes pad, so a mixed file still reads as one table.
        widest = max(shapes, key=len)
        header = ['Seite', 'Abschnitt'] + widest
        out = ROOT / out_name
        n = 0
        with out.open('w', newline='', encoding='utf-8-sig') as fh:
            w = csv.writer(fh)
            w.writerow(header)
            for page, section, shape, c in rows_of(md, shapes):
                if shape is widest or shape == widest:
                    padded = c
                else:
                    # Keep the narrower shape's own column names with the values,
                    # so nothing silently lands under a heading it does not mean.
                    padded = [f'{k}: {v}' for k, v in zip(shape, c)]
                    padded += [''] * (len(widest) - len(padded))
                w.writerow([page, section] + padded)
                n += 1
        total += n
        print(f'{n} Zeilen → {out.relative_to(ROOT)}')
    return 0 if total else 1


if __name__ == '__main__':
    sys.exit(main())
