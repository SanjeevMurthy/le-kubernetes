# CKS Kit Part 1: Tooling and Docs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **Status: built.** This plan was executed and the result is in the repository.
> The checkboxes below are the original task list, left as written rather than
> ticked, because they record what was planned. What was actually built, and
> where it differed, is section 15 of
> [`../specs/2026-09-06-cks-lfcs-prep-design.md`](../specs/2026-09-06-cks-lfcs-prep-design.md).

**Goal:** Ship the repo-wide verification tooling, fix the six broken verifiers, and deliver the complete CKS document set (exam-environment note, six upgraded domain notes, cheatsheet, Anki deck, real-exam compilation, dated study plan, lab-setup guide) so study can start on 26 Sep 2026.

**Architecture:** Phase 0 adds `scripts/` (Python and bash checkers, no third-party dependencies except optional mermaid-cli via npx) and patches four CKS and two CKA v2 verify scripts. Phase 1 rewrites and extends the markdown under `cks/` in recipe style, one file per task, each verified by `scripts/check-docs.sh` before commit. The CLI itself is Part 2 (`2026-09-06-cks-cli-plan.md`).

**Tech Stack:** bash 3.2-compatible scripts (macOS default), python3 3.9+, optional `npx @mermaid-js/mermaid-cli`, optional `shellcheck`, kubectl jsonpath for verifiers, GitHub-flavoured markdown with `<!-- toc -->` markers and mermaid fences.

**Spec:** `docs/superpowers/specs/2026-09-06-cks-lfcs-prep-design.md` (sections 2, 4, 5, 6, 9, 10, 11, 12)

## Global Constraints

- Branch `cks`; commit after every task; PR at the end of Phase 1 covering Phases 0 and 1.
- Every markdown file under `cks/` that has H2 headings carries a `<!-- toc -->` / `<!-- toc stop -->` block and passes `scripts/check-docs.sh`.
- At most one mermaid diagram per note, and only for a flow (spec §9).
- Notes are exam-task recipes: "What the exam asks", numbered recipes with Goal, Commands, Verify, Gotchas, Docs; "Quick reference"; "Memorise" (spec §9).
- Exam facts must match spec §2 exactly: Kubernetes v1.35 environment, 15 to 20 tasks, 2 hours, 67%, allowed docs list, `k` alias and `yq` present, no `jq`, no bookmarks.
- Verifiers never grep compact JSON; they use `-o jsonpath`, `-o yaml`, or effect tests (spec §7).
- File and directory names are lowercase with hyphens (CLAUDE.md).
- Subagents: at most three in parallel, one file each, content returned inline and written by the main session (spec §12).
- Commit trailer on every commit:
  `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01VDFGGfnXyAR8hsizcKsJzb`.

---

## File structure

| Path | Responsibility |
|---|---|
| `.gitignore` | ignore CLI state files |
| `scripts/check-links.py` | relative link, image, and anchor checker (exit 1 on problems) |
| `scripts/generate_toc.py` | TOC generator and `--check` verifier, ported from le-linux |
| `scripts/check-mermaid.sh` | extract mermaid fences, lint, render with mermaid-cli when available |
| `scripts/check-docs.sh` | orchestrator: bash -n, shellcheck, links, TOC, mermaid |
| `cka/practice-cli/v2/questions/q17-network-policy/verify.sh` | jsonpath fix |
| `cka/practice-cli/v2/questions/q18-storageclass/verify.sh` | jsonpath fix |
| `cks/practice-cli/questions/q01-networkpolicy-default-deny/verify.sh` | jsonpath rewrite plus DNS effect test |
| `cks/practice-cli/questions/q14-image-policy/verify.sh` | `-o yaml` grep for Kyverno path |
| `cks/practice-cli/questions/q15-static-analysis/verify.sh` | jsonpath for capabilities drop |
| `cks/practice-cli/questions/q18-immutable-containers/verify.sh` | jsonpath for mountPath |
| `cks/study-notes/00-exam-environment.md` | new: verified exam facts and environment rules |
| `cks/study-notes/01-cluster-setup.md` … `06-monitoring-logging-runtime.md` | upgraded recipe notes |
| `cks/study-notes/README.md` | reading order and question map |
| `cks/cheatsheets/cks-exam-cheatsheet.md`, `cks/cheatsheets/cks-anki-deck.txt` | new |
| `cks/practice-tests/exam-questions/cks-real-exam-questions.md` | new compilation |
| `cks/study-plan/README.md`, `00-calendar.md` (replaces `00-daily-schedule.md`), `01-domain-checklists.md`, `02-resources.md`, `03-exam-day-playbook.md` | re-dated plan |
| `cks/lab-setup/README.md` | new: minikube tier 1, Killercoda tier 2 |
| `cks/README.md` | refreshed |

---

## Phase 0: tooling and verifier fixes

### Task 1: Ignore CLI state files

**Files:**
- Modify: `.gitignore` (append after the `*todo*.md` line)

- [ ] **Step 1: Append the state-file patterns**

```gitignore

# Practice CLI runtime state
.timer
.progress
*.set.results
```

- [ ] **Step 2: Verify nothing tracked matches**

Run: `git ls-files | grep -E '(^|/)\.(timer|progress)$' || echo "clean"`
Expected: `clean`

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore: ignore practice CLI state files"
```

### Task 2: Relative link and anchor checker

**Files:**
- Create: `scripts/check-links.py`

**Interfaces:**
- Produces: `python3 scripts/check-links.py [PATH ...]`, prints `path:line: missing file X` or `missing anchor #y in z`, ends with `check-links: N problem(s)`, exit 1 when N > 0. Anchor slug rule: lowercase, drop backticks and punctuation, spaces to hyphens, duplicate headings get `-1`, `-2`. `generate_toc.py` must produce the same slugs.

- [ ] **Step 1: Write the script**

```python
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
```

- [ ] **Step 2: Test against a deliberately broken file**

```bash
mkdir -p /tmp/lc && printf '# T\n\n## Real Heading\n\n[ok](#real-heading) [bad](#nope) [gone](missing.md)\n' > /tmp/lc/t.md
python3 scripts/check-links.py /tmp/lc/t.md; echo "exit=$?"
```
Expected: two lines (`missing anchor #nope`, `missing file missing.md`), `check-links: 2 problem(s)`, `exit=1`.

- [ ] **Step 3: Run on the repo and record the baseline**

Run: `python3 scripts/check-links.py cks cka ckad README.md | tail -5`
Expected: known legacy problems may appear under `cka/` and `ckad/`; note them in the commit message, do not fix them here. `cks/` must report zero problems (the repo analysis found all 37 links resolve).

- [ ] **Step 4: Commit**

```bash
git add scripts/check-links.py
git commit -m "tooling: add markdown link and anchor checker"
```

### Task 3: TOC generator with check mode

**Files:**
- Create: `scripts/generate_toc.py` (ported from `/Users/sanjeevmurthy/le/repos/le-linux/scripts/generate_toc.py`, which hard-codes a le-linux path and always writes)

**Interfaces:**
- Produces: `python3 scripts/generate_toc.py [--check] [--inject] PATH...`. Default rewrites TOC blocks in files that already contain the markers. `--inject` also inserts a TOC before the first H2 of files without markers. `--check` prints `STALE TOC: path` and exits 1, writing nothing. Slugs identical to `check-links.py`.

- [ ] **Step 1: Write the script**

```python
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
    toc.append('\n<!-- toc stop -->\n')
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
```

- [ ] **Step 2: Test inject, check, and idempotence**

```bash
printf '# T\n\n## First\n\ntext\n\n### Sub\n\n## `kubectl` Second\n' > /tmp/lc/toc.md
python3 scripts/generate_toc.py --inject /tmp/lc/toc.md && python3 scripts/generate_toc.py --check /tmp/lc/toc.md; echo "exit=$?"
grep -c 'kubectl-second' /tmp/lc/toc.md
```
Expected: `Updated TOC: /tmp/lc/toc.md`, then `generate_toc: 1 file(s) with TOC, 0 stale`, `exit=0`, and `1` (the backtick heading slugged to `kubectl-second`).

- [ ] **Step 3: Confirm the repo is untouched by default mode**

Run: `python3 scripts/generate_toc.py --check cks README.md`
Expected: `generate_toc: 0 file(s) with TOC, 0 stale` (no markers exist yet under `cks/`).

- [ ] **Step 4: Commit**

```bash
git add scripts/generate_toc.py
git commit -m "tooling: add TOC generator with --check, ported from le-linux"
```

### Task 4: Mermaid block checker

**Files:**
- Create: `scripts/check-mermaid.sh`

**Interfaces:**
- Produces: `bash scripts/check-mermaid.sh [FILE.md ...]` (default: all `*.md` under the repo). Lints every fenced mermaid block (known diagram type on the first non-comment line, balanced brackets, no tabs) and renders it with `npx -y @mermaid-js/mermaid-cli` when `npx` exists and `MERMAID_RENDER` is not `0`. Prints `check-mermaid: N block(s), M failure(s)`; exit 1 when M > 0.

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Validate fenced mermaid blocks in markdown files.
# Lint always runs. Rendering with mermaid-cli runs when npx exists unless MERMAID_RENDER=0.
# The first render downloads Chromium for puppeteer (roughly 300 MB); set MERMAID_RENDER=0 to skip.
set -o pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fail=0; total=0
files=()
if [[ $# -gt 0 ]]; then
  files=("$@")
else
  while IFS= read -r f; do files+=("$f"); done < <(find "$ROOT" -name '*.md' -not -path '*/.git/*' -not -path '*/node_modules/*')
fi

extract() {  # $1 = markdown file; writes $TMP/<basename>.<n>.mmd; prints the block count
  python3 - "$1" "$TMP" <<'PY'
import os, re, sys
src, tmp = sys.argv[1], sys.argv[2]
text = open(src, encoding='utf-8').read()
blocks = re.findall(r'```mermaid[^\n]*\n(.*?)```', text, re.S)
base = os.path.basename(src)
for i, b in enumerate(blocks, 1):
    open(os.path.join(tmp, '%s.%d.mmd' % (base, i)), 'w', encoding='utf-8').write(b)
print(len(blocks))
PY
}

count() { grep -o "$2" "$1" | wc -l | tr -d ' '; }

lint() {  # $1 = .mmd file
  local first
  first=$(grep -m1 -vE '^[[:space:]]*(%%|$)' "$1" | sed 's/^[[:space:]]*//')
  case "$first" in
    graph*|flowchart*|sequenceDiagram*|classDiagram*|stateDiagram*|erDiagram*|gantt*|pie*|journey*|gitGraph*|mindmap*|timeline*|quadrantChart*|xychart*|block-beta*|sankey*) ;;
    *) echo "  unknown diagram type: '$first'"; return 1 ;;
  esac
  local pairs="[:] (:) {:}"
  local p o c
  for p in $pairs; do
    o=$(count "$1" "\\${p%%:*}"); c=$(count "$1" "\\${p##*:}")
    [[ "$o" -eq "$c" ]] || { echo "  unbalanced ${p%%:*} ${p##*:} ($o vs $c)"; return 1; }
  done
  if grep -q "$(printf '\t')" "$1"; then echo "  tab character found"; return 1; fi
  return 0
}

render_ok=0
if [[ "${MERMAID_RENDER:-1}" == "1" ]] && command -v npx >/dev/null 2>&1; then render_ok=1; fi

for f in "${files[@]}"; do
  n=$(extract "$f")
  [[ "$n" -eq 0 ]] && continue
  for m in "$TMP/$(basename "$f")".*.mmd; do
    total=$((total + 1))
    blk=$(basename "$m" .mmd); blk=${blk##*.}
    if ! lint "$m"; then
      echo "FAIL (lint): $f block $blk"; fail=$((fail + 1)); continue
    fi
    if [[ $render_ok -eq 1 ]]; then
      if ! npx -y @mermaid-js/mermaid-cli -q -i "$m" -o "$m.svg" >/dev/null 2>"$m.err"; then
        echo "FAIL (render): $f block $blk"; sed 's/^/    /' "$m.err" | head -5; fail=$((fail + 1))
      fi
    fi
  done
done

mode=""; [[ $render_ok -eq 1 ]] || mode=" (lint only)"
echo "check-mermaid: $total block(s), $fail failure(s)$mode"
[[ $fail -eq 0 ]]
```

- [ ] **Step 2: Test lint on a good and a bad block**

```bash
printf '# T\n\n```mermaid\nflowchart LR\n  A[start] --> B{ok?}\n```\n\n```mermaid\nnotadiagram\n  A --> B\n```\n' > /tmp/lc/mm.md
MERMAID_RENDER=0 bash scripts/check-mermaid.sh /tmp/lc/mm.md; echo "exit=$?"
```
Expected: `FAIL (lint): /tmp/lc/mm.md block 2` with `unknown diagram type: 'notadiagram'`, then `check-mermaid: 2 block(s), 1 failure(s) (lint only)`, `exit=1`.

- [ ] **Step 3: Test rendering once (downloads Chromium on first run)**

Run: `bash scripts/check-mermaid.sh /Users/sanjeevmurthy/le/repos/le-linux/linux-notes/05-lvm/lvm.md`
Expected: `check-mermaid: 6 block(s), 0 failure(s)`. If the download is unwanted now, run with `MERMAID_RENDER=0` and record that rendering is still unverified in the commit message.

- [ ] **Step 4: Commit**

```bash
git add scripts/check-mermaid.sh
git commit -m "tooling: add mermaid block lint and render check"
```

### Task 5: Documentation check orchestrator

**Files:**
- Create: `scripts/check-docs.sh`

**Interfaces:**
- Produces: `bash scripts/check-docs.sh [PATH ...]` (default targets: `cks lfcs shared scripts README.md CLAUDE.md roadmap.md docs`). Steps: `bash -n` on every `*.sh` and CLI entrypoint, `shellcheck -S warning` when installed, `check-links.py`, `generate_toc.py --check`, `check-mermaid.sh`. Ends with `check-docs: ALL OK` or `check-docs: FAILURES (see above)`; exit 1 on failures.

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Repo documentation and script checks.
# Usage: scripts/check-docs.sh [PATH ...]
set -o pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

targets=("$@")
if [[ ${#targets[@]} -eq 0 ]]; then targets=(cks lfcs shared scripts README.md CLAUDE.md roadmap.md docs); fi
existing=()
for t in "${targets[@]}"; do [[ -e "$t" ]] && existing+=("$t"); done
status=0
step() { printf '\n== %s ==\n' "$1"; }

step "bash -n"
n=0; bad=0
while IFS= read -r f; do
  n=$((n + 1))
  if ! bash -n "$f" 2>"$ROOT/.checkdocs.err"; then
    bad=$((bad + 1)); echo "SYNTAX: $f"; sed 's/^/    /' "$ROOT/.checkdocs.err"
  fi
done < <(find "${existing[@]}" -type f \( -name '*.sh' -o -name cka -o -name ckad -o -name cks -o -name lfcs \) -not -path '*/.git/*' 2>/dev/null)
rm -f "$ROOT/.checkdocs.err"
echo "bash -n: $n file(s), $bad failure(s)"
[[ $bad -eq 0 ]] || status=1

step "shellcheck"
if command -v shellcheck >/dev/null 2>&1; then
  while IFS= read -r f; do shellcheck -S warning "$f" || status=1; done < <(find "${existing[@]}" -type f -name '*.sh' -not -path '*/.git/*' 2>/dev/null)
  echo "shellcheck: done"
else
  echo "shellcheck not installed (brew install shellcheck) - skipped"
fi

step "links and anchors"
python3 scripts/check-links.py "${existing[@]}" || status=1

step "TOC"
python3 scripts/generate_toc.py --check "${existing[@]}" || status=1

step "mermaid"
mdfiles=()
while IFS= read -r f; do mdfiles+=("$f"); done < <(find "${existing[@]}" -name '*.md' -not -path '*/.git/*' 2>/dev/null)
if [[ ${#mdfiles[@]} -gt 0 ]]; then bash scripts/check-mermaid.sh "${mdfiles[@]}" || status=1; else echo "no markdown files"; fi

echo
if [[ $status -eq 0 ]]; then echo "check-docs: ALL OK"; else echo "check-docs: FAILURES (see above)"; fi
exit $status
```

- [ ] **Step 2: Run it on the current tree**

Run: `bash scripts/check-docs.sh cks scripts docs; echo "exit=$?"`
Expected: `bash -n` reports 0 failures for the 61 CKS scripts; links 0 problems under `cks/`; TOC 0 files; mermaid 0 blocks under `cks/` (research docs under `docs/` contain no mermaid); `check-docs: ALL OK`, `exit=0`. If `docs/research/*.md` trips the link checker on odd markdown, fix the checker's regex, not the report.

- [ ] **Step 3: Commit**

```bash
chmod +x scripts/*.sh
git add scripts/check-docs.sh
git commit -m "tooling: add check-docs orchestrator (bash -n, shellcheck, links, TOC, mermaid)"
```

### Task 6: Fix the two CKA v2 verifiers

**Files:**
- Modify: `cka/practice-cli/v2/questions/q17-network-policy/verify.sh:34-63`
- Modify: `cka/practice-cli/v2/questions/q18-storageclass/verify.sh:45`

- [ ] **Step 1: Replace the three grep checks in q17 (lines 34 to 63) with jsonpath checks**

```bash
echo "Checking ingress allows from podSelector role=backend..."
BACKEND_MATCH=$(kubectl get networkpolicy allow-frontend -n production -o jsonpath='{.spec.ingress[*].from[*].podSelector.matchLabels.role}' 2>/dev/null)
if [[ " $BACKEND_MATCH " == *" backend "* ]]; then
  echo "  PASS: Ingress allows from podSelector role=backend"
  ((PASS++))
else
  echo "  FAIL: Ingress does not allow from podSelector role=backend (found: '$BACKEND_MATCH')"
  ((FAIL++))
fi

echo "Checking ingress allows from namespaceSelector monitoring..."
NS_MATCH=$(kubectl get networkpolicy allow-frontend -n production -o jsonpath='{.spec.ingress[*].from[*].namespaceSelector.matchLabels.kubernetes\.io/metadata\.name}' 2>/dev/null)
if [[ " $NS_MATCH " == *" monitoring "* ]]; then
  echo "  PASS: Ingress allows from namespaceSelector monitoring"
  ((PASS++))
else
  echo "  FAIL: Ingress does not allow from namespaceSelector for monitoring namespace (found: '$NS_MATCH')"
  ((FAIL++))
fi

echo "Checking port 80 is specified..."
PORT_MATCH=$(kubectl get networkpolicy allow-frontend -n production -o jsonpath='{.spec.ingress[*].ports[*].port}' 2>/dev/null)
if [[ " $PORT_MATCH " == *" 80 "* ]]; then
  echo "  PASS: Port 80 is specified in ingress rules"
  ((PASS++))
else
  echo "  FAIL: Port 80 not found in ingress rules (found: '$PORT_MATCH')"
  ((FAIL++))
fi
```

Delete the now-unused `INGRESS_JSON=` line (old line 35).

- [ ] **Step 2: Replace line 45 of q18**

```bash
DEFAULT_COUNT=$(kubectl get storageclass -o jsonpath='{range .items[*]}{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}{"\n"}{end}' 2>/dev/null | grep -cx true || true)
```

- [ ] **Step 3: Syntax-check and prove the jsonpath shape offline**

```bash
bash -n cka/practice-cli/v2/questions/q17-network-policy/verify.sh cka/practice-cli/v2/questions/q18-storageclass/verify.sh && echo syntax-ok
kubectl create -f - --dry-run=client -o jsonpath='{.spec.ingress[*].from[*].podSelector.matchLabels.role}{"\n"}' <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: t, namespace: production}
spec:
  podSelector: {matchLabels: {role: frontend}}
  ingress:
  - from:
    - podSelector: {matchLabels: {role: backend}}
    - namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: monitoring}}
    ports: [{port: 80}]
EOF
```
Expected: `syntax-ok` and `backend` (dry-run never contacts the cluster; the active context is irrelevant).

- [ ] **Step 4: Commit**

```bash
git add cka/practice-cli/v2/questions/q17-network-policy/verify.sh cka/practice-cli/v2/questions/q18-storageclass/verify.sh
git commit -m "fix(cka-v2): q17 and q18 verifiers no longer grep compact JSON"
```

### Task 7: Fix the four CKS verifiers

**Files:**
- Modify: `cks/practice-cli/questions/q01-networkpolicy-default-deny/verify.sh` (full rewrite)
- Modify: `cks/practice-cli/questions/q14-image-policy/verify.sh:7-8`
- Modify: `cks/practice-cli/questions/q15-static-analysis/verify.sh:7`
- Modify: `cks/practice-cli/questions/q18-immutable-containers/verify.sh:7`

- [ ] **Step 1: Rewrite q01 verify.sh**

```bash
#!/bin/bash
# Q1 — NetworkPolicy default-deny + selective allow: Verify
PASS=0; FAIL=0
NS=prod
deny=0; allow=0; dns=0
for p in $(kubectl get networkpolicy -n "$NS" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
  get() { kubectl get networkpolicy "$p" -n "$NS" -o jsonpath="$1" 2>/dev/null; }
  sel=$(get '{.spec.podSelector}')
  types=$(get '{.spec.policyTypes[*]}')
  if [[ "$sel" == "{}" && "$types" == *Ingress* && "$types" == *Egress* ]]; then deny=1; fi
  if [[ "$(get '{.spec.podSelector.matchLabels.app}')" == "backend" ]]; then
    from=$(get '{.spec.ingress[*].from[*].podSelector.matchLabels.app}')
    ports=$(get '{.spec.ingress[*].ports[*].port}')
    if [[ " $from " == *" frontend "* && " $ports " == *" 8080 "* ]]; then allow=1; fi
  fi
  if [[ " $(get '{.spec.egress[*].ports[*].port}') " == *" 53 "* ]]; then dns=1; fi
done

echo "Checking a default-deny policy (Ingress+Egress, empty podSelector)..."
if [[ $deny -eq 1 ]]; then echo "  PASS: default-deny ingress+egress present"; ((PASS++)); else echo "  FAIL: no policy with empty podSelector and both policyTypes"; ((FAIL++)); fi

echo "Checking backend accepts ingress from frontend on TCP 8080..."
if [[ $allow -eq 1 ]]; then echo "  PASS: backend <- frontend :8080 allowed"; ((PASS++)); else echo "  FAIL: missing allow rule (backend <- frontend :8080)"; ((FAIL++)); fi

echo "Checking an egress rule allows DNS (port 53)..."
if [[ $dns -eq 1 ]]; then echo "  PASS: DNS egress (53) allowed"; ((PASS++)); else echo "  FAIL: no egress rule for port 53 — DNS would break"; ((FAIL++)); fi

echo "Checking DNS actually resolves from inside the namespace (effect test)..."
if kubectl run np-dns-check -n "$NS" --rm -i --restart=Never --image=busybox:1.36 --pod-running-timeout=90s -- nslookup kubernetes.default.svc.cluster.local >/dev/null 2>&1; then
  echo "  PASS: nslookup succeeded under the policies"; ((PASS++))
else
  echo "  FAIL: nslookup failed — egress to kube-dns on UDP/TCP 53 is blocked"; ((FAIL++))
fi

echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
```

- [ ] **Step 2: Replace q14 lines 7 and 8**

```bash
  if kubectl get clusterpolicy -o yaml 2>/dev/null | grep -q 'registry\.internal' && \
     kubectl get clusterpolicy -o jsonpath='{.items[*].spec.validationFailureAction}' 2>/dev/null | grep -qi 'enforce'; then
```

- [ ] **Step 3: Replace q15 line 7**

```bash
DROP=$($B='{.spec.template.spec.containers[0].securityContext.capabilities.drop[*]}' 2>/dev/null | tr ' ' '\n' | grep -x 'ALL')
```

- [ ] **Step 4: Replace q18 line 7**

```bash
MNT=$($B='{.spec.template.spec.containers[0].volumeMounts[*].mountPath}' 2>/dev/null | tr ' ' '\n' | grep -x '/tmp')
```

- [ ] **Step 5: Syntax-check and prove the shapes offline**

```bash
bash -n cks/practice-cli/questions/q01-networkpolicy-default-deny/verify.sh cks/practice-cli/questions/q14-image-policy/verify.sh cks/practice-cli/questions/q15-static-analysis/verify.sh cks/practice-cli/questions/q18-immutable-containers/verify.sh && echo syntax-ok
kubectl create -f - --dry-run=client -o jsonpath='{.spec.template.spec.containers[0].securityContext.capabilities.drop[*]}|{.spec.template.spec.containers[0].volumeMounts[*].mountPath}{"\n"}' <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata: {name: t}
spec:
  selector: {matchLabels: {a: b}}
  template:
    metadata: {labels: {a: b}}
    spec:
      containers:
      - name: c
        image: nginx
        securityContext: {capabilities: {drop: [ALL]}}
        volumeMounts: [{name: tmp, mountPath: /tmp}]
      volumes: [{name: tmp, emptyDir: {}}]
EOF
```
Expected: `syntax-ok` and `ALL|/tmp`.

- [ ] **Step 6: Commit**

```bash
git add cks/practice-cli/questions/q01-networkpolicy-default-deny/verify.sh cks/practice-cli/questions/q14-image-policy/verify.sh cks/practice-cli/questions/q15-static-analysis/verify.sh cks/practice-cli/questions/q18-immutable-containers/verify.sh
git commit -m "fix(cks): q01, q14, q15, q18 verifiers use jsonpath and a DNS effect test"
```

### Task 8: Phase 0 gate

- [ ] **Step 1: Run the full check**

Run: `bash scripts/check-docs.sh; echo "exit=$?"`
Expected: `check-docs: ALL OK`, `exit=0`.

- [ ] **Step 2: Push the branch**

```bash
git push -u origin cks
```

---

## Phase 1: CKS documents

Each note task below has the same test cycle. Do not skip it.

**Standard verification for a note** (run after writing, before commit):

```bash
python3 scripts/generate_toc.py --inject cks/study-notes/<file>.md
bash scripts/check-docs.sh cks/study-notes/<file>.md
grep -c '^## Recipe' cks/study-notes/<file>.md      # equals the recipe count in the task
grep -q '^## Memorise' cks/study-notes/<file>.md && echo memorise-ok
```
Expected: `check-docs: ALL OK`, the recipe count from the task, `memorise-ok`.

**Standard commit for a note:** `git add <file> && git commit -m "docs(cks): <what>"`.

**Recipe block format** (use verbatim structure in every note):

```markdown
## Recipe N: <task as the exam words it>

**Goal.** One sentence: the end state the grader checks.
**Frequency.** <n> candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q<ids>.
**Commands.**
```bash
# exact commands and file edits, in order
```
**Verify.**
```bash
# the command that proves it worked
```
**Gotchas.** Bullets: the traps candidates reported.
**Docs.** Allowed page title(s) to search on kubernetes.io or falco.org, or "none allowed: memorise".
```

### Task 9: New note 00-exam-environment.md

**Files:**
- Create: `cks/study-notes/00-exam-environment.md`

- [ ] **Step 1: Write the note** with these sections, all facts from spec §2 and `docs/research/2026-09-06-cks-exam-research.md` §1:
  1. `## Exam facts at a glance` table: version v1.35, 15 to 20 tasks (plan for 16), 2 h, 67%, one retake within 12 months, valid 2 years, CARE extension of CKA, two killer.sh sessions of 17 different questions.
  2. `## The remote desktop`: PSI Bridge, one monitor, Firefox with allowed domains only, terminal, VSCodium, notepad, timer alerts 30/15/5, flagging, `Ctrl+Alt+W`, `Ctrl+Shift+C/V`, INSERT key disabled (press `i`), `Ctrl+Alt+K` locate cursor.
  3. `## Hosts and tools`: `base` never rebooted, `ssh <node>` per task, no nested ssh, `sudo -i`, tools present (`k` alias with completion, `yq`, `curl`, `wget`, `man`), tools absent (`jq`, bookmarks, Docker CLI assumed absent: use `crictl` and `podman`), security tools present on the target node (Falco, Trivy, kube-bench, AppArmor utilities, `runsc`).
  4. `## Allowed documentation` verbatim list of the eight sources plus the Quick Reference box; explicit "not allowed" list (Trivy, kube-bench, AppArmor, kubesec docs, GitHub, external search results).
  5. `## Doc page titles to search` list of 14 kubernetes.io titles from research §5.2 plus falco.org "Supported Fields" and "Rules", docs.cilium.io "Network Policy" and "Transparent Encryption".
  6. `## First two minutes on a task host` code block: `sudo -i`, `k config current-context`, `export do="--dry-run=client -o yaml"`, `cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak`, vim `set nu sw=2 et ts=2 ai`, open a second terminal for `watch crictl ps`.
  7. `## Memorise` bullets: the eight allowed domains, the four present tools, the 67% and 16-task arithmetic (about 11 solid tasks pass).
- [ ] **Step 2: Standard verification** (recipe count is 0 for this note; skip the `## Recipe` grep).
- [ ] **Step 3: Commit** `docs(cks): add 00-exam-environment note`.

### Task 10: Upgrade 01-cluster-setup.md

**Files:**
- Modify: `cks/study-notes/01-cluster-setup.md` (403 lines; keep the good worked examples, restructure into the recipe format)

- [ ] **Step 1: Rewrite into 8 recipes** (source material: existing note, research §3 rows 4, 6, 13, 14, 24):
  1. Default-deny ingress and egress plus DNS egress (UDP and TCP 53, `namespaceSelector` for kube-system with `k8s-app: kube-dns`), verify with `kubectl run … nslookup`. Drill Q1.
  2. Selective allow: `podSelector`, `namespaceSelector`, `ipBlock`, `ports`; the AND-inside-one-item versus OR-across-items trap with two YAML examples. Drill Q1, Q35.
  3. Block the metadata endpoint: egress to `0.0.0.0/0` with `except: [169.254.169.254/32]`. Drill Q24.
  4. kube-bench: `kube-bench run --targets master,node`, `--check 1.2.9`, mapping table CIS id to file (1.2.x apiserver manifest, 1.3.x controller-manager, 2.x etcd, 4.2.x `/var/lib/kubelet/config.yaml`), the kubelet fixes (`readOnlyPort: 0`, `authentication.anonymous.enabled: false`, `authorization.mode: Webhook`, `protectKernelDefaults: true`), `chown -R etcd:etcd /var/lib/etcd`, `--profiling=false`, `systemctl restart kubelet`, re-run with `--check`. Drill Q2, Q22.
  5. TLS versions and ciphers on apiserver and etcd: `--tls-min-version=VersionTLS13`, `--tls-cipher-suites=TLS_AES_128_GCM_SHA256,TLS_AES_256_GCM_SHA384`, etcd `--cipher-suites`; verify with `openssl s_client -connect 127.0.0.1:6443 -tls1_2` failing. Drill Q33.
  6. Ingress with TLS: `openssl req -x509 -newkey rsa:2048 -nodes -keyout tls.key -out tls.crt -subj "/CN=web.example" -days 365`, `kubectl create secret tls web-tls --cert --key`, `spec.tls[].hosts/secretName`, `nginx.ingress.kubernetes.io/ssl-redirect: "true"`, verify `curl -kv --resolve web.example:443:<ingress-ip> https://web.example`. Drill Q3.
  7. Verify platform binaries: `sha512sum kubelet`, `echo "<hash>  kubelet" | sha512sum --check`, compare the running binary `sha512sum $(command -v kubelet)`, checksums from `https://dl.k8s.io/release/v1.35.0/bin/linux/amd64/kubelet.sha512`. Drill Killercoda "Verify Platform Binaries" (no repo question).
  8. Node metadata and dashboard exposure: one paragraph that the GUI bullet was removed in October 2024; keep the RBAC pointer to 02.
- [ ] **Step 2: Add `## What the exam asks`** table before the recipes: task type, sources count, drill question (rows from research §3: NetworkPolicy 12, kube-bench 12, Ingress TLS 7, binaries 7, metadata 4).
- [ ] **Step 3: Add `## Quick reference` and `## Memorise`** (kube-bench flags, CIS id to file map, openssl one-liner, sha512sum syntax, `ipBlock.except`).
- [ ] **Step 4: Standard verification** (expect 8 recipes) and commit `docs(cks): rewrite 01-cluster-setup as recipes`.

### Task 11: Upgrade 02-cluster-hardening.md

**Files:**
- Modify: `cks/study-notes/02-cluster-hardening.md`

- [ ] **Step 1: Rewrite into 7 recipes** (research §3 rows 7, 9, 17, 18, 23, 26):
  1. RBAC least privilege imperatively: `kubectl create role/rolebinding/clusterrole/clusterrolebinding`, SA subject `system:serviceaccount:<ns>:<sa>`, verify `kubectl auth can-i list pods --as=system:serviceaccount:ns:sa -n ns`, remove `system:anonymous` and `system:unauthenticated` bindings (`kubectl get clusterrolebinding -o wide | grep -E 'anonymous|unauthenticated'`). Drill Q4, Q29.
  2. ServiceAccount hygiene: `automountServiceAccountToken: false` on the SA and on the pod, `kubectl create token <sa> --duration=10m`, projected token volume, verify `kubectl exec … -- ls /var/run/secrets/kubernetes.io/serviceaccount` fails. Drill Q5.
  3. Safe apiserver edit and recovery: backup, edit flags (`--anonymous-auth=false`, `--authorization-mode=Node,RBAC`, `--enable-admission-plugins=NodeRestriction`, remove `--kubernetes-service-node-port`, `--profiling=false`), then `watch crictl ps`, `curl -k https://127.0.0.1:6443/readyz`; recovery sequence `journalctl -fu kubelet | grep -i apiserver`, `crictl ps -a | grep apiserver`, `crictl logs <id>`, `ls -t /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/ | head -1`; note the kubelet rescans manifests every 20 s. Drill Q6, Q23, Q37.
  4. NodeRestriction: enable the plugin; prove it with `kubectl --kubeconfig /etc/kubernetes/kubelet.conf label node <other> a=b` refused. Drill Q6.
  5. kubeadm upgrade one minor version: control plane (`apt-mark unhold kubeadm`, `apt-get install kubeadm=1.35.x-*`, `kubeadm upgrade plan`, `kubeadm upgrade apply v1.35.x`, drain, kubelet and kubectl, `systemctl daemon-reload && systemctl restart kubelet`, uncordon), worker (`kubeadm upgrade node`). Drill Q39.
  6. CSR for a user: `openssl genrsa -out jane.key 2048`, `openssl req -new -key jane.key -subj "/CN=jane" -out jane.csr`, CertificateSigningRequest with `request: $(base64 -w0 jane.csr)`, `signerName: kubernetes.io/kube-apiserver-client`, `kubectl certificate approve jane`, `kubectl get csr jane -o jsonpath='{.status.certificate}' | base64 -d > jane.crt`, `kubectl config set-credentials jane --client-key --client-certificate`, bind a Role. Drill Q40.
  7. Contexts and certificate extraction: `kubectl config get-contexts -o name`, `kubectl config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d | openssl x509 -noout -subject -dates`. Drill Killercoda "kubeconfig" style task.
- [ ] **Step 2: `## What the exam asks`** table (RBAC 10, apiserver flags 9, upgrade 6, SA hygiene 6, kubeconfig 4, CSR 3).
- [ ] **Step 3: Quick reference and Memorise** (the recovery sequence, `auth can-i` syntax, `signerName`, upgrade order).
- [ ] **Step 4: Standard verification** (7 recipes) and commit `docs(cks): rewrite 02-cluster-hardening as recipes`.

### Task 12: Upgrade 03-system-hardening.md

**Files:**
- Modify: `cks/study-notes/03-system-hardening.md`

- [ ] **Step 1: Rewrite into 7 recipes** (research §3 rows 5, 20, 22):
  1. Reduce host footprint: `systemctl list-units --type=service --state=running`, `systemctl disable --now <svc>`, `ss -tlpn`, `lsof -i :<port>`, `apt list --installed | grep <pkg>`, `apt-get remove --purge`. Drill Q41.
  2. Least-privilege identity: `usermod -L`, `usermod -s /usr/sbin/nologin`, `gpasswd -d user group`, `chgrp`, `visudo` with `NOPASSWD` removal, sshd `PermitRootLogin no` and `PasswordAuthentication no` then `sshd -t && systemctl restart sshd`. Drill Q42.
  3. Minimise external access: UFW `ufw allow 22/tcp`, `ufw allow from 10.0.0.0/8 to any port 6443`, `ufw enable`, `ufw status numbered`; iptables one-liner alternative. Drill Q41.
  4. Kernel modules: `lsmod`, `/etc/modprobe.d/blacklist.conf` with `blacklist sctp` and `install sctp /bin/true`, `modprobe -r sctp`, `modprobe --showconfig | grep sctp`. Drill Q42.
  5. AppArmor: `apparmor_parser -q /etc/apparmor.d/<file>`, `aa-status | grep <profile-name>`, the profile name inside the file is what the pod references (not the filename), pod `securityContext.appArmorProfile: {type: Localhost, localhostProfile: <name>}` (1.30+) and the legacy annotation, schedule to the node where the profile is loaded (`nodeName`), verify `kubectl exec … -- touch /tmp/x` denied and `dmesg | grep apparmor`. Drill Q7, Q34.
  6. seccomp: profile JSON under `/var/lib/kubelet/seccomp/profiles/audit.json` (`defaultAction: SCMP_ACT_LOG`) and a deny example (`SCMP_ACT_ERRNO` for `mkdir`), pod `seccompProfile: {type: Localhost, localhostProfile: profiles/audit.json}`, `RuntimeDefault`, verify `grep Seccomp /proc/$(crictl inspect --output go-template --template '{{.info.pid}}' <id>)/status` equals 2, or `journalctl -k | grep audit`. Drill Q8, Q30.
  7. Capabilities and securityContext scope: `capabilities: {drop: [ALL], add: [NET_BIND_SERVICE]}`, `capsh --print` inside the container, table of pod-level versus container-level fields (`runAsUser`, `runAsNonRoot`, `fsGroup`, `seccompProfile`, `appArmorProfile` at both; `capabilities`, `privileged`, `allowPrivilegeEscalation`, `readOnlyRootFilesystem` container only), plus strace investigation: `crictl ps`, `crictl inspect` for the PID, `strace -p <pid> -f -e trace=kill`. Drill Q15, Q43.
- [ ] **Step 2: `## What the exam asks`** (AppArmor 12, seccomp mentioned by 5, Linux hardening 4, strace 5, capabilities within securityContext tasks).
- [ ] **Step 3: Quick reference and Memorise** (profile name versus file, seccomp path, `crictl inspect` template, UFW syntax).
- [ ] **Step 4: Standard verification** (7 recipes) and commit `docs(cks): rewrite 03-system-hardening as recipes`.

### Task 13: Expand 04-microservice-vulnerabilities.md

**Files:**
- Modify: `cks/study-notes/04-microservice-vulnerabilities.md` (190 lines; this is a 20% domain, target 350 to 450 lines)

- [ ] **Step 1: Write 9 recipes** (research §3 rows 8, 12, 15, 19, 21, 27):
  1. Pod Security Admission: labels `pod-security.kubernetes.io/enforce|audit|warn` and `-version`, the restricted checklist (`runAsNonRoot`, `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`, `seccompProfile.type: RuntimeDefault|Localhost`), enforcement affects new pods only, find violators with `kubectl label --dry-run=server --overwrite ns <ns> pod-security.kubernetes.io/enforce=restricted` and read the warnings, write them to a file. Drill Q9, Q36.
  2. OPA Gatekeeper: full `ConstraintTemplate` (kind `K8sBlockedRegistries`, Rego that denies images not starting with an allowed prefix) and a `Constraint` with `enforcementAction: deny`; edit an existing constraint with `kubectl edit`, `kubectl get constraints`, dry-run mode. Drill Q11.
  3. Kyverno `ClusterPolicy` validate with `validationFailureAction: Enforce` restricting `image` to `registry.internal/*`; `kubectl get cpol`. Drill Q11, Q14.
  4. ValidatingAdmissionPolicy (CEL) policy plus binding requiring `spec.template.spec.securityContext.runAsNonRoot == true`; one paragraph, marked as plausible future task.
  5. Secrets encryption at rest: `EncryptionConfiguration` with `aescbc` first and `identity` last, `head -c 32 /dev/urandom | base64`, apiserver `--encryption-provider-config` plus hostPath volume and mount, `kubectl get secrets -A -o json | kubectl replace -f -`, verify `ETCDCTL_API=3 etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/etcd/server.crt --key /etc/kubernetes/pki/etcd/server.key get /registry/secrets/<ns>/<name> | hexdump -C | head -3` shows `k8s:enc:aescbc:v1:`. Drill Q10, Q26.
  6. Read and decode secrets: from etcd (previous command without encryption), `kubectl get secret -o jsonpath='{.data.password}' | base64 -d`, secrets as env versus volume, `immutable: true`. Drill Q25.
  7. gVisor: containerd `plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc` with `runtime_type = "io.containerd.runsc.v1"`, `RuntimeClass` handler `runsc`, pod `runtimeClassName: gvisor`, verify `kubectl exec … -- dmesg | head -3` shows gVisor and `uname -r` differs. Drill Q12, Q28.
  8. Cilium: `CiliumNetworkPolicy` with `endpointSelector`, `ingress.fromEndpoints`, `toPorts` with `rules.http` method and path (L7), verify with `cilium status` and `kubectl -n kube-system exec ds/cilium -- cilium encrypt status`; WireGuard enablement `encryption.enabled=true encryption.type=wireguard` via Helm values. Drill Q35, Q44.
  9. Istio: `PeerAuthentication` with `mtls.mode: STRICT` at namespace and mesh scope, verify with `curl` from a non-injected pod failing and `istioctl x describe pod`. Drill Q44.
- [ ] **Step 2: One mermaid diagram** (`flowchart LR`) of the admission chain: request, authentication, authorization, mutating admission, validating admission (PSA, Gatekeeper, Kyverno, ValidatingAdmissionPolicy, ImagePolicyWebhook), etcd. Place it under `## What the exam asks`.
- [ ] **Step 3: `## What the exam asks`** (gVisor 10, secrets and encryption 8, Cilium 8, PSA 6, Gatekeeper 5, Istio 3) and a `## Isolation techniques` table (namespace, RBAC, NetworkPolicy, ResourceQuota, PSA, sandbox, dedicated nodes).
- [ ] **Step 4: Quick reference and Memorise** (etcdctl flags, `k8s:enc:` prefix, PSA label syntax, `runsc` handler name, `cilium encrypt status`, `PeerAuthentication` fields).
- [ ] **Step 5: Standard verification** (9 recipes; mermaid block renders) and commit `docs(cks): expand 04-microservice-vulnerabilities to full recipes`.

### Task 14: Expand 05-supply-chain-security.md

**Files:**
- Modify: `cks/study-notes/05-supply-chain-security.md` (161 lines; target 300 to 400 lines)

- [ ] **Step 1: Write 8 recipes** (research §3 rows 3, 10, 11, 25, 29):
  1. Minimal base images: multi-stage Dockerfile example (build stage, `FROM gcr.io/distroless/static` or `alpine`), `USER 1001`, pinned tags, no `latest`, no secrets in `ENV`, `podman build -t app:1 .` and `podman run --rm app:1 id` to prove non-root. Drill Q27.
  2. Find the issues in a Dockerfile and a manifest: checklist table (`USER root`, `:latest`, `ADD` of remote URLs, `apt-get` without `--no-install-recommends`, hard-coded credentials; manifest `privileged: true`, `hostNetwork`, `hostPID`, `allowPrivilegeEscalation`, missing `runAsNonRoot`, secret values in `env`); the rule "only change what the task asks". Drill Q27, Q15.
  3. Trivy: `trivy image --severity HIGH,CRITICAL --ignore-unfixed nginx:1.19`, `-f json -o /opt/course/<n>/report.json`, list images per namespace `kubectl get pods -n <ns> -o custom-columns=POD:.metadata.name,IMG:.spec.containers[*].image`, delete the pod or scale the deployment as instructed, run scans in a second terminal. Drill Q13.
  4. kubesec and kube-linter: `kubesec scan pod.yaml` reading `score` and `advise`, `kube-linter lint deploy.yaml`, fix the flagged fields. Drill Q15.
  5. SBOM with bom: `bom generate --image registry.k8s.io/kube-apiserver:v1.35.0 --format json -o /opt/course/<n>/sbom.json`, `bom document outline sbom.json`, `bom document query sbom.json 'purl:pkg:apk/*'`; mention syft and grype. Drill Q38.
  6. Sign and verify artifacts: `cosign verify --key cosign.pub registry/app:1`, `cosign sign --key cosign.key`, digest pinning `image@sha256:…` and `kubectl get pod -o jsonpath='{.status.containerStatuses[*].imageID}'`. Drill Killercoda "Image Use Digest".
  7. ImagePolicyWebhook end to end: `AdmissionConfiguration` YAML with `imagePolicy.kubeConfigFile`, `allowTTL`, `denyTTL`, `defaultAllow: false`; the webhook kubeconfig with `clusters[].cluster.server: https://image-bouncer.default.svc:1323/image_policy` and `certificate-authority`; apiserver flags `--admission-control-config-file=/etc/kubernetes/admission-controllers/admission-config.yaml` and `--enable-admission-plugins=NodeRestriction,ImagePolicyWebhook`; hostPath volume and mount for `/etc/kubernetes/admission-controllers`; test `kubectl run test --image=nginx:latest` denied. Drill Q14, Q21.
  8. Permitted registries with Kyverno or Gatekeeper (cross-reference 04 recipes 2 and 3) and `imagePullPolicy: Always` note. Drill Q11.
- [ ] **Step 2: `## What the exam asks`** (ImagePolicyWebhook 12, Trivy 9, static analysis 8, SBOM and kubesec 5, cosign 1).
- [ ] **Step 3: Quick reference and Memorise** (Trivy flags, kubesec command, bom syntax, AdmissionConfiguration skeleton, the three apiserver pieces of ImagePolicyWebhook). No diagram.
- [ ] **Step 4: Standard verification** (8 recipes) and commit `docs(cks): expand 05-supply-chain-security to full recipes`.

### Task 15: Expand 06-monitoring-logging-runtime.md

**Files:**
- Modify: `cks/study-notes/06-monitoring-logging-runtime.md` (146 lines; target 350 to 450 lines)

- [ ] **Step 1: Write 7 recipes** (research §3 rows 1, 2, 16, 20):
  1. Falco rule anatomy and override: `/etc/falco/falco_rules.yaml`, `/etc/falco/falco_rules.local.yaml`, rule fields (`rule`, `desc`, `condition`, `output`, `priority`, `tags`), override by re-declaring the same rule name in the local file, macros and lists, `falco --list | grep container`, `falco -L`. Drill Q16.
  2. Falco output format task: rewrite `output` to `%evt.time,%container.id,%container.name,%user.name`, enable `file_output` in `/etc/falco/falco.yaml` with `filename: /var/log/falco.log`, `json_output`, reload with `kill -1 $(cat /var/run/falco.pid)` or `systemctl restart falco`, read `journalctl -u falco -f`, write the required lines to `/opt/course/<n>/falco.log`. Drill Q19.
  3. Map an alert to a pod and stop it: `crictl ps | grep <container-id>`, `crictl inspect <id> | grep -A2 io.kubernetes.pod`, `kubectl get pods -A -o wide`, `kubectl scale deploy <name> --replicas=0`. Drill Q31.
  4. Audit logging setup: policy structure with first-match ordering, four levels, `omitStages`, worked policy (secrets at `RequestResponse` in namespace `prod`, `Metadata` for `configmaps`, `None` for `get/list/watch`, catch-all `Metadata`), apiserver flags `--audit-policy-file`, `--audit-log-path=/var/log/kubernetes/audit/audit.log`, `--audit-log-maxage=30`, `--audit-log-maxbackup=10`, `--audit-log-maxsize=100`, two hostPath volumes (policy `File`, log dir `DirectoryOrCreate`), verify `tail -f` shows JSON lines and `/readyz` is ok. Drill Q17, Q32.
  5. Audit log forensics without jq: `grep '"verb":"delete"' audit.log | grep secrets`, `grep -o '"user":{"username":"[^"]*"' audit.log | sort | uniq -c`, `yq -p json '.user.username' <<< "$line"`, find who read a secret and from which IP, write findings to `/opt/course/<n>/`. Drill Q20.
  6. Behavioural analytics and attack phases: table of phases (reconnaissance, initial access, execution, persistence, privilege escalation, lateral movement, exfiltration) with the Kubernetes signal for each (audit verbs, Falco rules such as shell in container and write below etc, NetworkPolicy denials, unexpected `exec`), and the evidence commands. No drill (concept).
  7. Immutability at runtime: `readOnlyRootFilesystem: true` plus `emptyDir` for `/tmp` and `/var/cache/nginx`, no `privileged`, drop capabilities, verify `kubectl exec … -- touch /x` fails while the app runs; delete pods that store data or use privileged configs. Drill Q18.
- [ ] **Step 2: One mermaid diagram** (`flowchart LR`) of the audit pipeline: API request, apiserver audit stage, policy first-match, log backend file, grep or yq analysis. Place under `## What the exam asks`.
- [ ] **Step 3: `## What the exam asks`** (Falco 15, audit 13, immutability 6, strace 5).
- [ ] **Step 4: Quick reference and Memorise** (Falco paths and output fields, reload signal, audit flags and levels, `crictl` mapping commands).
- [ ] **Step 5: Standard verification** (7 recipes) and commit `docs(cks): expand 06-monitoring-logging-runtime to full recipes`.

### Task 16: Study-notes README

**Files:**
- Modify: `cks/study-notes/README.md`

- [ ] **Step 1: Rewrite** the table to seven rows (00 to 06) with weight, recipe count, and drill question ids (Q ids per the question bank in `2026-09-06-cks-cli-plan.md` §"Question bank"), update the version text to "Kubernetes v1.35 environment, curriculum v1.34", replace the `00-daily-schedule.md` link with `../study-plan/00-calendar.md`, keep the "How to use them" steps.
- [ ] **Step 2: Verify** `bash scripts/check-docs.sh cks/study-notes` prints `ALL OK` (the calendar link will fail until Task 19; run this step again after Task 19 and before the PR).
- [ ] **Step 3: Commit** `docs(cks): update study-notes README`.

### Task 17: Cheatsheet and Anki deck

**Files:**
- Create: `cks/cheatsheets/cks-exam-cheatsheet.md`
- Create: `cks/cheatsheets/cks-anki-deck.txt`

- [ ] **Step 1: Write the cheatsheet** with TOC and sections: `## Shell setup` (the first-two-minutes block from 00), `## Paths to memorise` (apiserver manifest, kubelet config, seccomp dir, AppArmor dir, Falco files, audit policy path, etcd pki, admission config dir), `## Commands with no docs in the exam` (Trivy, kube-bench, AppArmor tools, kubesec, crictl, etcdctl, sha512sum, strace, yq usage), `## Doc page titles`, `## Verification one-liners per task family` (one command per row: RBAC, NetworkPolicy, PSA, AppArmor, seccomp, gVisor, encryption, audit, Falco, Ingress TLS, immutability), `## Recovery` (apiserver crash sequence), `## Time plan` (16 tasks, 6 to 8 min each, flag at 10, last 15 min verify).
- [ ] **Step 2: Write the Anki deck** in the le-linux format:

```
#separator:tab
#html:true
#tags column:3
#deck:CKS
Path of the kube-apiserver static pod manifest	/etc/kubernetes/manifests/kube-apiserver.yaml	cks::paths
```
  Produce about 120 rows: 20 paths, 25 flags, 40 commands, 35 traps and concepts, drawn only from the `## Memorise` sections of notes 00 to 06 (every Memorise bullet becomes at least one card). Use `<br>` for line breaks inside a field. Tags `cks::paths`, `cks::flags`, `cks::commands`, `cks::traps`.
- [ ] **Step 3: Verify**

```bash
bash scripts/check-docs.sh cks/cheatsheets
awk -F'\t' 'NR>4 && NF!=3 {bad++} END {print "bad-rows=" bad+0}' cks/cheatsheets/cks-anki-deck.txt
grep -vc '^#' cks/cheatsheets/cks-anki-deck.txt
```
Expected: `ALL OK`, `bad-rows=0`, a count of at least 110.
- [ ] **Step 4: Commit** `docs(cks): add exam cheatsheet and Anki deck`.

### Task 18: Real-exam compilation

**Files:**
- Create: `cks/practice-tests/exam-questions/cks-real-exam-questions.md`

- [ ] **Step 1: Write the compilation** from `docs/research/2026-09-06-cks-exam-research.md` §2 and §3: header with method and date; TOC; per domain a table with columns `#`, `Task type`, `Frequency (n sources)`, `Phrasing as remembered`, `Starting state`, `Gotchas`, `Drill` (Q ids); all 30 task types from research §3 placed under their domain; a `## Frequency tiers` section (tier 1 at 10 or more sources, tier 2 at 6 to 9, tier 3 below); `## Sources` list with every URL from research §2 in date order; `## Not on the current exam` (dashboard, PSP).
- [ ] **Step 2: Verify** `bash scripts/check-docs.sh cks/practice-tests` prints `ALL OK`, and `grep -c '^| [0-9]' cks/practice-tests/exam-questions/cks-real-exam-questions.md` prints 30.
- [ ] **Step 3: Commit** `docs(cks): add real-exam task compilation from 28 candidate reports`.

### Task 19: Re-dated study plan

**Files:**
- Modify: `cks/study-plan/README.md`
- Create: `cks/study-plan/00-calendar.md`; delete `cks/study-plan/00-daily-schedule.md` (`git rm`)
- Modify: `cks/study-plan/01-domain-checklists.md`, `02-resources.md`, `03-exam-day-playbook.md`
- Modify: `docs/superpowers/specs/2026-09-06-cks-lfcs-prep-design.md` §5 (foundation ends 8 Nov, drills start 9 Nov)

- [ ] **Step 1: Write `00-calendar.md`** as a weekend-by-weekend schedule with checkboxes. Weekday rule: 15 minutes of Anki daily. Weekends are 3 h Saturday plus 3 h Sunday until 1 Nov, then 10 to 12 h per week. Content per weekend:

| Weekend | Focus | Notes and drills |
|---|---|---|
| Before 26 Sep | Setup | book exam for Sat 12 Dec, KodeKloud and Killercoda accounts, Anki import, `cks/lab-setup` minikube profile, clone repo on Killercoda once |
| 26 to 27 Sep | Exam environment, Cluster Setup part 1 | notes 00 and 01 recipes 1 to 3 and 6; Q1, Q3, Q24 on minikube; KodeKloud Cluster Setup lessons |
| 3 to 4 Oct | Runtime Security | note 06 recipes 1 to 5; Q16, Q17, Q19, Q20 on Killercoda; KodeKloud Monitoring section |
| 10 to 11 Oct | Cluster Hardening | note 02; Q4, Q5, Q29 on minikube; Q6, Q23 on Killercoda |
| 17 to 18 Oct | System Hardening | note 03; Q7, Q8, Q30, Q34 on Killercoda; Q41, Q42 |
| 24 to 25 Oct | Microservice Vulnerabilities | note 04; Q9, Q11, Q36 on minikube; Q10, Q12, Q25, Q26, Q28 on Killercoda |
| 31 Oct to 1 Nov | Supply Chain | note 05; Q13, Q15, Q27 on minikube; Q14, Q21, Q38 on Killercoda |
| 7 to 8 Nov | Foundation close-out | note 01 recipes 4, 5, 7; Q2, Q22, Q33; upgrade Q39, CSR Q40, Cilium and Istio Q35, Q44; first re-score of checklists |
| 9 to 15 Nov | Drills week 1 | all questions interleaved and timed, random mode; KodeKloud mock 1; repo mock 1 on Sat 14 Nov |
| 16 to 22 Nov | Drills week 2 | weak-area loop; KodeKloud mock 2; repo mock 2 on Sat 21 Nov; apiserver crash drill |
| 23 to 29 Nov | Drills week 3 | KodeKloud mock 3; killer.sh session 1 on Sat 28 Nov, review on Sun 29 Nov |
| 30 Nov to 6 Dec | Simulation | gap drills from session 1; repo mock 3 on Sat 5 Dec |
| 7 to 12 Dec | Exam week | killer.sh session 2 on Wed 9 Dec; light review Thu and Fri; exam Sat 12 Dec |

  Each weekend entry lists: KodeKloud lessons to watch, note recipes to type out, questions to run with the lab tier, Anki cards to add, and a Sunday close-out line ("close everything, re-type the commands from memory").
- [ ] **Step 2: Update `README.md`**: parameters table (start 26 Sep 2026, exam Sat 12 Dec 2026, weekend hours, KodeKloud, killer.sh dates, minikube plus Killercoda), the phases table with dates, keep the six principles and the daily ritual adapted to weekends, "How to use these files" pointing at `00-calendar.md`.
- [ ] **Step 3: Update `01-domain-checklists.md`**: keep the `[ ]`, `[~]`, `[x]` legend; add missing items (CSR, kubeadm upgrade, host hardening tasks, strace, CiliumNetworkPolicy and encryption, Istio PeerAuthentication, bom, cosign, ImagePolicyWebhook end to end, audit forensics, apiserver crash recovery, Falco output format and crictl mapping, TLS ciphers); add a drill column with Q ids on every line; re-score dates 8 Nov, 29 Nov, after each killer.sh session.
- [ ] **Step 4: Update `02-resources.md`**: KodeKloud CKS course sections mapped to notes 01 to 06; the 42 Killercoda scenario names mapped to domains (from research §4); verified allowed docs and the not-allowed list; the doc page titles; lab section replaced by a pointer to `../lab-setup/README.md`; remove all bookmark advice.
- [ ] **Step 5: Update `03-exam-day-playbook.md`**: PSI facts (no bookmarks, INSERT disabled, `Ctrl+Alt+W`, one monitor, arrive 30 minutes early), hosts and `base`, `yq` not `jq`, the first-two-minutes block, ordering strategy (scan all, high weight first, flag at 10 minutes, last 15 minutes verify), verification one-liners per task family, recovery procedures for apiserver and kubelet, top 15 lessons refreshed from research §2.1 and §5.4.
- [ ] **Step 6: Update the spec calendar rows** so foundation reads `Sat 26 Sep to Sun 8 Nov` and drills `Mon 9 Nov to Sun 29 Nov`, keeping the mock and killer.sh dates.
- [ ] **Step 7: Verify**

```bash
git rm -q cks/study-plan/00-daily-schedule.md
grep -rn '00-daily-schedule' cks docs README.md CLAUDE.md || echo "no stale references"
python3 scripts/generate_toc.py --inject cks/study-plan
bash scripts/check-docs.sh cks/study-plan cks/study-notes docs/superpowers
```
Expected: `no stale references`, `check-docs: ALL OK`.
- [ ] **Step 8: Commit** `docs(cks): re-date study plan to 26 Sep to 12 Dec 2026 with weekend calendar`.

### Task 20: Lab-setup guide and CKS README

**Files:**
- Create: `cks/lab-setup/README.md`
- Modify: `cks/README.md`

- [ ] **Step 1: Write `lab-setup/README.md`** with sections: `## Disk space first` (`docker system df`, `docker system prune -a`, `minikube delete -p cka-multinode`, target 15 GB free), `## Tier 1: minikube` with

```bash
minikube start -p cks --driver=docker --nodes=2 --cpus=2 --memory=3g --cni=calico --kubernetes-version=v1.35.0
minikube addons enable ingress -p cks
kubectl config use-context cks
kubectl get nodes -o wide
```
  Kyverno install (`kubectl create -f https://github.com/kyverno/kyverno/releases/latest/download/install.yaml`), Gatekeeper alternative, `minikube stop -p cks`; `## Tier 2: Killercoda` (open Killer Shell CKS playground, `git clone https://github.com/SanjeevMurthy/le-kubernetes && cd le-kubernetes/cks/practice-cli`, `sudo bash tools/install-tools.sh`, `./cks`, the one-hour limit and which questions to run there); `## KodeKloud labs` (which lessons carry labs for node-level topics); `## Which questions run where` table generated from the needs tags (fill after Part 2 Task "registry"; leave the table header and a note until then); `## Optional: single-node kubeadm in the LFCS VM` pointer to `../../lfcs/lab-setup/`.
- [ ] **Step 2: Refresh `cks/README.md`**: exam facts from spec §2 (v1.35, 15 to 20 tasks, 67%, allowed docs summary), the folder map with the new folders (`lab-setup`, `cheatsheets`, `practice-tests/exam-questions`, `mock-exams`), quick start for the CLI, links to the calendar and playbook, the "practice only, never production" warning.
- [ ] **Step 3: Verify** `python3 scripts/generate_toc.py --inject cks/README.md cks/lab-setup/README.md && bash scripts/check-docs.sh cks` prints `ALL OK` (links to `mock-exams/` and `tools/install-tools.sh` may not resolve until Part 2; write those as plain text with a "Part 2" note until then, never as broken links).
- [ ] **Step 4: Commit** `docs(cks): add lab-setup guide and refresh README`.

### Task 21: Phase 1 gate and PR

- [ ] **Step 1: Full verification**

```bash
bash scripts/check-docs.sh; echo "exit=$?"
for f in cks/study-notes/0[1-6]-*.md; do printf '%s recipes=%s memorise=%s\n' "$f" "$(grep -c '^## Recipe' "$f")" "$(grep -c '^## Memorise' "$f")"; done
```
Expected: `ALL OK`; recipes 8, 7, 7, 9, 8, 7; memorise 1 for each.

- [ ] **Step 2: Coverage check** against the curriculum bullets in spec §2: every bullet of the six domains appears in `01-domain-checklists.md` with at least one recipe reference and one Q id. Fix gaps before the PR.

- [ ] **Step 3: Push and open the PR**

```bash
git push origin cks
gh pr create --base main --head cks --title "CKS kit part 1: tooling, verifier fixes, recipe notes, dated plan" --body-file - <<'EOF'
## Summary
- scripts/: link, TOC, mermaid, and shell checks (`scripts/check-docs.sh`)
- fixes for six verifiers that grepped compact JSON (CKA v2 q17, q18; CKS q01, q14, q15, q18)
- cks/study-notes: new 00-exam-environment; 01 to 06 rewritten as exam-task recipes with TOCs
- cks/cheatsheets, cks/practice-tests/exam-questions, cks/lab-setup: new
- cks/study-plan: dated calendar 26 Sep to 12 Dec 2026

## Verification
- `bash scripts/check-docs.sh` -> ALL OK
- curriculum coverage recorded in cks/study-plan/01-domain-checklists.md

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01VDFGGfnXyAR8hsizcKsJzb
EOF
```

---

## Self-review against the spec

- §2 facts: Task 9 (00 note), Task 19 (README and playbook), Task 20 (README).
- §4 layout for docs: Tasks 9 to 20 create every `cks/` document folder except `mock-exams/` and the CLI, which are Part 2.
- §5 calendar: Task 19 (with the 8 Nov foundation adjustment mirrored into the spec).
- §6 lab tiers: Task 20.
- §9 notes, cheatsheets, compilation, plan files: Tasks 9 to 19.
- §10 tooling: Tasks 2 to 5.
- §11 hygiene in scope: Task 1 (gitignore), Tasks 6 and 7 (verifiers); README and CLAUDE.md root updates are in the LFCS plan Phase 5.
- §12 Phase 0 and 1 acceptance: Tasks 8 and 21.
- Placeholder scan: no TBD or "similar to"; every note task lists its recipes and commands; the lab-setup "which questions run where" table is explicitly deferred to Part 2 with a note, not a placeholder.
- Name consistency: `scripts/check-docs.sh`, `scripts/check-links.py`, `scripts/generate_toc.py`, `scripts/check-mermaid.sh`, `cks/study-plan/00-calendar.md`, `cks/lab-setup/README.md` are used with the same names throughout and in Part 2.
