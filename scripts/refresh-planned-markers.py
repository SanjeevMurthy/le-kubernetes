#!/usr/bin/env python3
"""Clear "(planned)" markers for practice questions that now exist.

The study notes, checklists and exam compilations reference questions by id and
mark the ones not yet built, for example "Q24 (planned)" or "Q24 *(planned)*".
As questions get built those markers go stale, and a stale marker is worse than
none: it tells you to skip a question you could be drilling.

This walks each kit, works out which question ids actually exist on disk, and
removes the marker only for those. Ids still unbuilt keep their marker.

Usage:
  scripts/refresh-planned-markers.py            # report what would change
  scripts/refresh-planned-markers.py --write    # make the changes
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Each kit: where its questions live, and which docs reference them.
KITS = (
    ('cks', 'cks/practice-cli/questions', ('cks/study-notes', 'cks/study-plan', 'cks/practice-tests')),
    ('lfcs', 'lfcs/practice-cli/questions', ('lfcs/study-notes', 'lfcs/study-plan', 'lfcs/practice-tests')),
)

# "Q24 (planned)", "Q24 *(planned)*", "Q24 (planned, ...)" and the same with
# surrounding whitespace variations. The id is captured so we only touch built ones.
MARKER = re.compile(r'\bQ(\d{1,2})(\s*\*?\(planned\)\*?)')


def built_ids(qdir):
    """Ids of questions that exist and are complete enough to drill."""
    out = set()
    full = os.path.join(ROOT, qdir)
    if not os.path.isdir(full):
        return out
    for name in os.listdir(full):
        m = re.match(r'^q(\d{2})-', name)
        if not m:
            continue
        d = os.path.join(full, name)
        needed = ('meta', 'question.md', 'solution.md', 'setup.sh', 'verify.sh', 'cleanup.sh')
        if all(os.path.getsize(os.path.join(d, f)) > 0
               for f in needed if os.path.exists(os.path.join(d, f))) and \
           all(os.path.exists(os.path.join(d, f)) for f in needed):
            out.add(int(m.group(1)))
    return out


def md_files(dirs):
    for d in dirs:
        full = os.path.join(ROOT, d)
        for base, _, files in os.walk(full):
            for f in files:
                if f.endswith('.md'):
                    yield os.path.join(base, f)


def main():
    write = '--write' in sys.argv
    total_changed = total_files = 0

    for kit, qdir, docdirs in KITS:
        ids = built_ids(qdir)
        if not ids:
            print('%s: no built questions found, nothing to clear' % kit)
            continue
        print('%s: %d built question(s)' % (kit, len(ids)))
        for path in sorted(md_files(docdirs)):
            src = open(path, encoding='utf-8').read()

            def repl(m):
                return 'Q' + m.group(1) if int(m.group(1)) in ids else m.group(0)

            new = MARKER.sub(repl, src)
            if new == src:
                continue
            n = len(MARKER.findall(src)) - len(MARKER.findall(new))
            total_changed += n
            total_files += 1
            rel = os.path.relpath(path, ROOT)
            print('  %-58s %d marker(s)' % (rel, n))
            if write:
                open(path, 'w', encoding='utf-8').write(new)

    verb = 'cleared' if write else 'would clear'
    print('\nrefresh-planned-markers: %s %d marker(s) across %d file(s)%s'
          % (verb, total_changed, total_files, '' if write else '  (use --write to apply)'))
    return 0


if __name__ == '__main__':
    sys.exit(main())
