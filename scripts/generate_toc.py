#!/usr/bin/env python3
"""Generate or verify '<!-- toc -->' ... '<!-- toc stop -->' blocks (H2 and H3) in markdown.

Usage: generate_toc.py [--check] [--inject] PATH...
  default   rewrite TOC blocks in files that already contain the markers
  --inject  also insert a TOC before the first H2 in files without markers
  --check   report files whose TOC is missing or stale, exit 1, write nothing
Ported from le-linux/scripts/generate_toc.py.
"""
import os
import re
import sys

SKIP_DIRS = {'.git', 'node_modules', '.claude'}


def create_anchor(text):
    a = re.sub(r'`([^`]*)`', r'\1', text)
    a = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', a)
    a = a.strip().lower()
    a = re.sub(r'[^\w\s-]', '', a)
    return re.sub(r'\s', '-', a)


def build(lines):
    fence, heads = False, []
    start = end = first_h2 = -1
    for i, line in enumerate(lines):
        if line.startswith('```'):
            fence = not fence
            continue
        if fence:
            continue
        s = line.strip()
        if s == '<!-- toc -->':
            start = i
        elif s == '<!-- toc stop -->':
            end = i
        m = re.match(r'^(#{2,3})\s+(.+)$', line)
        if m:
            lvl, text = len(m.group(1)), m.group(2).strip()
            if text.lower() == 'table of contents':
                continue
            if first_h2 == -1 and lvl == 2:
                first_h2 = i
            heads.append((lvl, text))
    toc = ['<!-- toc -->\n', '## Table of Contents\n', '\n']
    seen = {}
    for lvl, text in heads:
        a = create_anchor(text)
        n = seen.get(a, 0)
        seen[a] = n + 1
        if n:
            a = '%s-%d' % (a, n)
        toc.append('%s- [%s](#%s)\n' % ('  ' if lvl == 3 else '', text, a))
    # Keep every element exactly one line, so a TOC read back from disk with
    # readlines() compares equal to a freshly built one and --check is stable.
    toc.append('\n')
    toc.append('<!-- toc stop -->\n')
    return heads, start, end, first_h2, toc


def process(path, check, inject):
    with open(path, encoding='utf-8') as fh:
        lines = fh.readlines()
    heads, start, end, first_h2, toc = build(lines)
    has = start != -1 and end != -1 and start < end
    if not heads or (not has and (not inject or first_h2 == -1)):
        return None
    if has:
        new = lines[:start] + toc + lines[end + 1:]
    else:
        pad = ['\n'] if first_h2 > 0 and lines[first_h2 - 1].strip() else []
        new = lines[:first_h2] + pad + toc + ['\n'] + lines[first_h2:]
    if new == lines:
        return False
    if not check:
        with open(path, 'w', encoding='utf-8') as fh:
            fh.writelines(new)
    return True


def skip_file(path):
    """Per-question question.md and solution.md get no table of contents.

    They are short, they are read in a terminal through the practice CLI, and
    the guide builder inlines them, so a TOC there becomes forty-five stray
    contents blocks in the middle of the generated guide.
    """
    parts = path.replace(os.sep, '/').split('/')
    return 'questions' in parts and 'practice-cli' in parts


def md_files(paths):
    for p in paths:
        if os.path.isfile(p):
            if not skip_file(p):
                yield p
            continue
        for d, dirs, files in os.walk(p):
            dirs[:] = [x for x in dirs if x not in SKIP_DIRS]
            for f in files:
                if f.endswith('.md') and not skip_file(os.path.join(d, f)):
                    yield os.path.join(d, f)


if __name__ == '__main__':
    args = sys.argv[1:]
    check, inject = '--check' in args, '--inject' in args
    paths = [a for a in args if not a.startswith('--')] or ['.']
    files = changed = 0
    for f in md_files(paths):
        r = process(f, check, inject)
        if r is None:
            continue
        files += 1
        if r:
            changed += 1
            print(('STALE TOC: ' if check else 'Updated TOC: ') + f)
    print('generate_toc: %d file(s) with TOC, %d %s'
          % (files, changed, 'stale' if check else 'updated'))
    sys.exit(1 if (check and changed) else 0)
