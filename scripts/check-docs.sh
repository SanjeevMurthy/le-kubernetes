#!/usr/bin/env bash
# Repo documentation and script checks: bash -n, shellcheck, links and anchors, TOC, mermaid.
# Usage: scripts/check-docs.sh [PATH ...]
set -o pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

targets=("$@")
if [[ ${#targets[@]} -eq 0 ]]; then targets=(cks lfcs shared scripts README.md CLAUDE.md roadmap.md docs); fi
existing=()
for t in "${targets[@]}"; do [[ -e "$t" ]] && existing+=("$t"); done
if [[ ${#existing[@]} -eq 0 ]]; then echo "check-docs: no target paths exist"; exit 0; fi
status=0
step() { printf '\n== %s ==\n' "$1"; }

step "bash -n"
n=0; bad=0
while IFS= read -r f; do
  n=$(( n + 1 ))
  if ! bash -n "$f" 2>"$ROOT/.checkdocs.err"; then
    bad=$(( bad + 1 )); echo "SYNTAX: $f"; sed 's/^/    /' "$ROOT/.checkdocs.err"
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

step "library unit tests"
if [[ -x scripts/test-libs.sh || -f scripts/test-libs.sh ]]; then
  bash scripts/test-libs.sh | tail -1 || status=1
else
  echo "scripts/test-libs.sh not found - skipped"
fi

step "question references"
if [[ -f scripts/check-question-refs.py ]]; then
  python3 scripts/check-question-refs.py cks || status=1
  [[ -d lfcs ]] && { python3 scripts/check-question-refs.py lfcs || status=1; }
else
  echo "scripts/check-question-refs.py not found - skipped"
fi

step "persistence rule"
# LFCS scores a change that does not survive a reboot as zero. A verifier that
# only looks at the running system is therefore too generous, so each question
# must check persistence or be listed as exempt with a reason.
if [[ -f scripts/check-persistence.py && -d lfcs ]]; then
  python3 scripts/check-persistence.py || status=1
else
  echo "not applicable - skipped"
fi

step "lab tables"
# The "which questions run where" tables are derived from the question metas.
# A new or retagged question silently invalidates them, so the gate rebuilds
# them in memory and complains if the checked-in copy differs.
if [[ -f scripts/build-lab-table.py ]]; then
  kits=()
  for t in "${existing[@]}"; do [[ "$t" == cks || "$t" == lfcs ]] && kits+=("$t"); done
  if [[ ${#kits[@]} -gt 0 ]]; then
    python3 scripts/build-lab-table.py --check "${kits[@]}" || status=1
  else
    echo "no kit in scope - skipped"
  fi
else
  echo "scripts/build-lab-table.py not found - skipped"
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
