#!/usr/bin/env bash
# Validate fenced mermaid blocks in markdown files.
# Lint always runs (diagram type, bracket balance outside quotes, tabs, empty block).
# Rendering with mermaid-cli runs when npx exists unless MERMAID_RENDER=0.
# The first render downloads Chromium for puppeteer (roughly 300 MB); set MERMAID_RENDER=0 to skip.
# Usage: check-mermaid.sh [FILE.md ...]   (default: every *.md in the repo)
set -o pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

files=()
if [[ $# -gt 0 ]]; then
  files=("$@")
else
  while IFS= read -r f; do files+=("$f"); done < <(find "$ROOT" -name '*.md' -not -path '*/.git/*' -not -path '*/node_modules/*')
fi
if [[ ${#files[@]} -eq 0 ]]; then echo "check-mermaid: 0 block(s), 0 failure(s)"; exit 0; fi

# Extract and lint. Blocks that pass the lint are written to $TMP/<n>.mmd for rendering,
# with $TMP/<n>.src naming their origin. Counts land in $TMP/counts as "<total> <lintfailures>".
python3 - "$TMP" "${files[@]}" <<'PY'
import os, re, sys
tmp, srcs = sys.argv[1], sys.argv[2:]
TYPES = ('graph', 'flowchart', 'sequenceDiagram', 'classDiagram', 'stateDiagram', 'erDiagram',
         'gantt', 'pie', 'journey', 'gitGraph', 'mindmap', 'timeline', 'quadrantChart',
         'xychart', 'block-beta', 'sankey', 'requirementDiagram', 'C4Context')
FENCE_RE = re.compile(r'^(\s*)(`{3,}|~{3,})\s*([A-Za-z0-9_+-]*)')


def mermaid_blocks(text):
    """Yield the body of every top-level ```mermaid fence.

    Line-based so that a 4-backtick fence may contain 3-backtick examples, and so
    that fence markers appearing mid-line (inside a printf or a regex) are ignored.
    """
    blocks, marker, lang, body = [], None, None, []
    for line in text.splitlines():
        m = FENCE_RE.match(line)
        if marker is None:
            if m and m.group(3).lower() == 'mermaid':
                marker, lang, body = m.group(2), 'mermaid', []
            elif m:
                marker, lang, body = m.group(2), m.group(3).lower(), None
            continue
        # inside a fence: close only on a bare marker at least as long as the opener
        if m and m.group(2)[0] == marker[0] and len(m.group(2)) >= len(marker) and not m.group(3):
            if lang == 'mermaid':
                blocks.append('\n'.join(body))
            marker, lang, body = None, None, None
            continue
        if body is not None:
            body.append(line)
    return blocks


total = fails = kept = 0
for src in srcs:
    try:
        text = open(src, encoding='utf-8').read()
    except OSError as exc:
        print('FAIL (read): %s: %s' % (src, exc))
        fails += 1
        continue
    for i, body in enumerate(mermaid_blocks(text), 1):
        total += 1
        problems = []
        lines = [l for l in body.splitlines() if l.strip() and not l.strip().startswith('%%')]
        if not lines:
            problems.append('empty block')
        elif not lines[0].strip().startswith(TYPES):
            problems.append('unknown diagram type: %r' % lines[0].strip()[:40])
        if '\t' in body:
            problems.append('tab character')
        stripped = re.sub(r'"[^"\n]*"', '', body)
        for open_ch, close_ch in (('[', ']'), ('(', ')'), ('{', '}')):
            if stripped.count(open_ch) != stripped.count(close_ch):
                problems.append('unbalanced %s %s (%d vs %d)'
                                % (open_ch, close_ch, stripped.count(open_ch), stripped.count(close_ch)))
        if problems:
            fails += 1
            print('FAIL (lint): %s block %d: %s' % (src, i, '; '.join(problems)))
        else:
            kept += 1
            with open(os.path.join(tmp, '%d.mmd' % kept), 'w', encoding='utf-8') as fh:
                fh.write(body)
            with open(os.path.join(tmp, '%d.src' % kept), 'w', encoding='utf-8') as fh:
                fh.write('%s block %d' % (src, i))
with open(os.path.join(tmp, 'counts'), 'w', encoding='utf-8') as fh:
    fh.write('%d %d' % (total, fails))
PY

read -r total lint_fail < "$TMP/counts"

render_fail=0
mode=" (lint only)"
if [[ "${MERMAID_RENDER:-1}" == "1" ]] && command -v npx >/dev/null 2>&1; then
  mode=""
  for m in "$TMP"/*.mmd; do
    [[ -e "$m" ]] || continue
    if ! npx -y @mermaid-js/mermaid-cli -q -i "$m" -o "$m.svg" >/dev/null 2>"$m.err"; then
      echo "FAIL (render): $(cat "${m%.mmd}.src")"
      sed 's/^/    /' "$m.err" | head -5
      render_fail=$(( render_fail + 1 ))
    fi
  done
fi

fail=$(( lint_fail + render_fail ))
echo "check-mermaid: $total block(s), $fail failure(s)$mode"
[[ $fail -eq 0 ]]
