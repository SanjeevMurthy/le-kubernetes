#!/usr/bin/env python3
"""Check that every question id referenced in the docs actually exists.

The study notes, checklists, exam compilations and mock sets all point at
practice questions by id. Nothing stops those references drifting: a question
gets renumbered, a note cites one that was never built, or a "(planned)" marker
outlives the thing it described. Each of those sends the reader to a question
the CLI cannot run.

A reference to an unbuilt question is fine when it is marked "(planned)". A
reference to an unbuilt question with no marker is an error, and so is a
"(planned)" marker on a question that now exists.

Usage:
  scripts/check-question-refs.py            # every kit
  scripts/check-question-refs.py cks        # one kit, while another is still being built

Exit status 1 when anything is inconsistent.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NEEDED = ('meta', 'question.md', 'solution.md', 'setup.sh', 'verify.sh', 'cleanup.sh')

KITS = (
    ('cks', 'cks/practice-cli/questions',
     ('cks/study-notes', 'cks/study-plan', 'cks/practice-tests', 'cks/mock-exams')),
    ('lfcs', 'lfcs/practice-cli/questions',
     ('lfcs/study-notes', 'lfcs/study-plan', 'lfcs/practice-tests', 'lfcs/mock-exams')),
)

# "Q7", "Q24", optionally followed by a planned marker.
REF = re.compile(r'\bQ(\d{1,2})\b(\s*\*?\(planned\)\*?)?')


def built(qdir):
    out = set()
    full = os.path.join(ROOT, qdir)
    if not os.path.isdir(full):
        return out
    for name in sorted(os.listdir(full)):
        m = re.match(r'^q(\d{2})-', name)
        if not m:
            continue
        d = os.path.join(full, name)
        if all(os.path.exists(os.path.join(d, f)) and os.path.getsize(os.path.join(d, f)) > 0
               for f in NEEDED):
            out.add(int(m.group(1)))
    return out


def md_files(dirs):
    for d in dirs:
        full = os.path.join(ROOT, d)
        if not os.path.isdir(full):
            continue
        for base, _, files in os.walk(full):
            for f in files:
                if f.endswith('.md'):
                    yield os.path.join(base, f)


def main():
    wanted = [a for a in sys.argv[1:] if not a.startswith('-')]
    kits = [k for k in KITS if not wanted or k[0] in wanted]
    if wanted and not kits:
        print('no such kit: %s (known: %s)' % (', '.join(wanted), ', '.join(k[0] for k in KITS)))
        return 1
    problems = []
    for kit, qdir, docdirs in kits:
        ids = built(qdir)
        for path in sorted(md_files(docdirs)):
            rel = os.path.relpath(path, ROOT)
            fence = False
            for n, line in enumerate(open(path, encoding='utf-8'), 1):
                if line.startswith('```'):
                    fence = not fence
                    continue
                if fence:
                    continue
                for m in REF.finditer(line):
                    qid, marker = int(m.group(1)), m.group(2)
                    if qid in ids and marker:
                        problems.append('%s:%d: Q%d is built but still marked (planned)' % (rel, n, qid))
                    elif qid not in ids and not marker:
                        problems.append('%s:%d: Q%d is referenced but not built, and not marked (planned)'
                                        % (rel, n, qid))

        # Mock sets must only name questions that exist, since the CLI runs them.
        setdir = os.path.join(ROOT, os.path.dirname(qdir).replace('practice-cli', 'mock-exams'))
        if os.path.isdir(setdir):
            for f in sorted(os.listdir(setdir)):
                if not f.endswith('.set'):
                    continue
                p = os.path.join(setdir, f)
                for n, line in enumerate(open(p, encoding='utf-8'), 1):
                    line = line.strip()
                    if not line or line.startswith('#'):
                        continue
                    qid = int(line.split('|')[0])
                    if qid not in ids:
                        problems.append('%s/%s:%d: mock names Q%d, which is not built'
                                        % (os.path.relpath(setdir, ROOT), f, n, qid))

    for p in problems:
        print(p)
    scope = ', '.join(k[0] for k in kits)
    print('check-question-refs (%s): %d problem(s)' % (scope, len(problems)))
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
