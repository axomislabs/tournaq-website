#!/usr/bin/env python3
"""Check the site's translations against the English written into the pages.

Translations live as a baked LOCALES literal inside js/i18n.js, and the pages
carry their English inline as the fallback. applyTranslations overwrites that
inline text whenever a key exists, which makes one specific mistake invisible
and expensive:

    change a string's English in the HTML, keep the same data-i18n key,
    and German and Spanish visitors keep reading the OLD claim.

That is not a cosmetic drift — it is how a site ends up telling two thirds of
its audience that a shipped feature is "still coming". So the rule is that a
string whose meaning changes gets a NEW key, and this script enforces it by
comparing every page's inline English against LOCALES.en.

    python3 tools/check-i18n.py            # report, exit 1 on any problem
    python3 tools/check-i18n.py --quiet    # only the summary

Exits non-zero if any check fails, so it can gate a commit.
"""
import argparse
import html as html_module
import json
import subprocess
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
I18N = os.path.join(REPO, 'js/i18n.js')
PAGE_DIRS = ['pages', 'legal']

TAG = re.compile(r'<([a-z0-9]+)\b([^>]*?)\bdata-i18n(-html)?="([^"]+)"([^>]*)>', re.I)
ATTR_ALT = re.compile(r'data-i18n-alt="([^"]+)"')


def locales():
    """Pull the LOCALES object out of i18n.js.

    It is a JavaScript literal, not JSON — bare `en:` / `de:` / `es:` keys — so
    it is read by the one thing guaranteed to agree with the browser about what
    the file means. node is a dependency already: it is the syntax gate that
    keeps a bad edit here from blanking every page on the site.
    """
    script = r'''
      const fs = require('fs');
      const src = fs.readFileSync(process.argv[1], 'utf8');
      const at = src.indexOf('var LOCALES = ');
      if (at < 0) { console.error('no LOCALES literal found'); process.exit(2); }
      const open = src.indexOf('{', at);
      let depth = 0, inStr = false, esc = false, end = -1;
      for (let i = open; i < src.length; i++) {
        const c = src[i];
        if (inStr) {
          if (esc) esc = false;
          else if (c === '\\') esc = true;
          else if (c === '"') inStr = false;
        } else if (c === '"') inStr = true;
        else if (c === '{') depth++;
        else if (c === '}' && --depth === 0) { end = i; break; }
      }
      if (end < 0) { console.error('unterminated LOCALES literal'); process.exit(2); }
      process.stdout.write(JSON.stringify(eval('(' + src.slice(open, end + 1) + ')')));
    '''
    proc = subprocess.run(['node', '-e', script, I18N],
                          capture_output=True, text=True)
    if proc.returncode != 0:
        raise SystemExit('could not read LOCALES: %s' % proc.stderr.strip())
    return json.loads(proc.stdout)


def pages():
    for root_name in PAGE_DIRS:
        root = os.path.join(REPO, root_name)
        if not os.path.isdir(root):
            continue
        for dirpath, _, files in os.walk(root):
            for f in sorted(files):
                if f.endswith('.html'):
                    yield os.path.join(dirpath, f)


VOID = {'img', 'br', 'hr', 'input', 'meta', 'link'}


def inner_html(html, tag, start):
    """Raw inner HTML of the element whose opening tag ends at `start`.

    Walks to the matching close rather than to the next '<', because plenty of
    translated elements contain a link or an <em> and stopping at the first
    child would compare half a sentence against a whole one.
    """
    if tag.lower() in VOID:
        return ''
    depth, i = 1, start
    pat = re.compile(r'<(/?)%s\b[^>]*?(/?)>' % re.escape(tag), re.I)
    while depth and i < len(html):
        m = pat.search(html, i)
        if not m:
            return html[start:]
        depth += -1 if m.group(1) else (0 if m.group(2) else 1)
        i = m.end()
        if not depth:
            return html[start:m.start()]
    return html[start:i]


def normalise(s, strip_tags=True):
    """Compare like the browser would: entities decoded, whitespace collapsed."""
    if strip_tags:
        s = re.sub(r'<[^>]+>', '', s)
    s = html_module.unescape(s)
    s = re.sub(r'\s+', ' ', s)
    if not strip_tags:
        # "<br> Email" and "<br>Email" render identically; source formatting
        # around a tag is not a translation difference.
        s = re.sub(r'\s*(<[^>]+>)\s*', r'\1', s)
    return s.strip()


def first_diff(want, got):
    """Where two strings diverge, with a little context on each side."""
    n = min(len(want), len(got))
    i = next((k for k in range(n) if want[k] != got[k]), n)
    lo = max(0, i - 25)
    return ('…' if lo else '') + got[lo:i + 45], ('…' if lo else '') + want[lo:i + 45]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--quiet', action='store_true')
    args = ap.parse_args()

    L = locales()
    langs = sorted(L)
    problems = []

    # 1. every language carries the same key set
    en_keys = set(L['en'])
    for lang in langs:
        if lang == 'en':
            continue
        missing = en_keys - set(L[lang])
        extra = set(L[lang]) - en_keys
        for k in sorted(missing):
            problems.append('%s: missing key %s' % (lang, k))
        for k in sorted(extra):
            problems.append('%s: key not in en: %s' % (lang, k))

    # 2. every key used by a page exists, and its English still matches
    used, stale, unknown = set(), [], []
    for path in pages():
        rel = os.path.relpath(path, REPO)
        html = open(path, encoding='utf-8').read()
        for m in TAG.finditer(html):
            key = m.group(4)
            used.add(key)
            if key not in L['en']:
                continue          # inline English is the fallback — fine
            # data-i18n sets textContent (markup is replaced), data-i18n-html
            # sets innerHTML — so only the latter is compared with tags intact.
            keep_tags = bool(m.group(3))
            body = inner_html(html, m.group(1), m.end())
            want = normalise(L['en'][key], strip_tags=not keep_tags)
            got = normalise(body, strip_tags=not keep_tags)
            if got and want != got:
                stale.append((rel, key, want, got))
        for m in ATTR_ALT.finditer(html):
            used.add(m.group(1))

    for rel, key, want, got in stale:
        g, w = first_diff(want, got)
        problems.append(
            '%s: "%s" diverges\n        page : %r\n        en   : %r\n'
            '        -> DE/ES still show the en text; give the new wording a new key'
            % (rel, key, g, w))

    # 3. keys nothing references any more (dead weight, not an error)
    orphans = sorted(en_keys - used)

    if not args.quiet:
        for p in problems:
            print('  !! %s' % p)
        if orphans:
            print('  -- %d key(s) defined but unused (harmless): %s%s'
                  % (len(orphans), ', '.join(orphans[:6]),
                     ' …' if len(orphans) > 6 else ''))

    print('locales: %s' % ', '.join('%s=%d' % (l, len(L[l])) for l in langs))
    print('keys used by pages: %d' % len(used))
    print('%d problem(s)' % len(problems))
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
