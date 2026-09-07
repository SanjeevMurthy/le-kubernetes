#!/usr/bin/env python3
"""Check relative links, images and #anchors in markdown files.

Usage: check-links.py [PATH ...]   (default: repo root; skips .git, node_modules, .claude)
Exit status 1 when any link is broken.
"""
import os
import re
import sys
import urllib.parse

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP_DIRS = {'.git', 'node_modules', '.claude'}
LINK_RE = re.compile(r'(?<!!)\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)')
IMG_RE = re.compile(r'!\[[^\]]*\]\(([^)\s]+)')
HEADING_RE = re.compile(r'^(#{1,6})\s+(.+?)\s*#*\s*$')
HTML_ANCHOR_RE = re.compile(r'<a\s[^>]*\b(?:id|name)\s*=\s*["\']([^"\']+)["\']', re.I)
_anchor_cache = {}


def slug(text):
    text = re.sub(r'`([^`]*)`', r'\1', text)
    text = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', text)
    text = text.strip().lower()
    text = re.sub(r'[^\w\s-]', '', text)
    return re.sub(r'\s', '-', text)


def anchors_of(path):
    if path in _anchor_cache:
        return _anchor_cache[path]
    seen, out, fence = {}, set(), False
    try:
        with open(path, encoding='utf-8') as fh:
            for line in fh:
                if line.startswith('```'):
                    fence = not fence
                    continue
                if fence:
                    continue
                out.update(HTML_ANCHOR_RE.findall(line))
                m = HEADING_RE.match(line)
                if m:
                    s = slug(m.group(2))
                    n = seen.get(s, 0)
                    seen[s] = n + 1
                    out.add(s if n == 0 else '%s-%d' % (s, n))
    except OSError:
        pass
    _anchor_cache[path] = out
    return out


def md_files(paths):
    for p in paths:
        if os.path.isfile(p):
            yield p
            continue
        for d, dirs, files in os.walk(p):
            dirs[:] = [x for x in dirs if x not in SKIP_DIRS]
            for f in files:
                if f.endswith('.md'):
                    yield os.path.join(d, f)


def check(path):
    errors, fence = [], False
    with open(path, encoding='utf-8') as fh:
        for n, line in enumerate(fh, 1):
            if line.startswith('```'):
                fence = not fence
                continue
            if fence:
                continue
            for target in LINK_RE.findall(line) + IMG_RE.findall(line):
                if re.match(r'^[a-z][a-z0-9+.-]*:', target):
                    continue  # http:, https:, mailto: and friends
                target = urllib.parse.unquote(target)
                file_part, _, anchor = target.partition('#')
                if file_part:
                    dest = os.path.normpath(os.path.join(os.path.dirname(path), file_part))
                    if not os.path.exists(dest):
                        errors.append('%s:%d: missing file %s' % (path, n, file_part))
                        continue
                else:
                    dest = path
                if anchor and dest.endswith('.md') and anchor not in anchors_of(dest):
                    errors.append('%s:%d: missing anchor #%s in %s'
                                  % (path, n, anchor, os.path.relpath(dest, ROOT)))
    return errors


if __name__ == '__main__':
    paths = sys.argv[1:] or [ROOT]
    problems = [e for p in md_files(paths) for e in check(p)]
    for e in problems:
        print(e)
    print('check-links: %d problem(s)' % len(problems))
    sys.exit(1 if problems else 0)
