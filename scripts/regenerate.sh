#!/usr/bin/env bash
# Rebuild every generated artefact in both practice kits.
#
# Run this after adding, renaming or editing any question. Several files are
# derived from the question folders and will drift silently otherwise: the
# registry the CLI reads, the guide people read, the mock papers, the lab
# tables, and the "(planned)" markers scattered through the notes.
#
# Every generator refuses to write when its inputs look wrong, so a half-written
# question stops the run rather than producing a broken artefact.
#
# Usage: bash scripts/regenerate.sh [cks|lfcs]
set -o pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

kits=("$@")
if [[ ${#kits[@]} -eq 0 ]]; then kits=(cks lfcs); fi
status=0

for kit in "${kits[@]}"; do
  cli="$kit/practice-cli"
  [[ -d "$cli" ]] || { echo "no such kit: $kit"; status=1; continue; }
  printf '\n== %s ==\n' "$kit"

  bash "$cli/tools/build-registry.sh" || status=1
  bash "$cli/tools/build-guide.sh"    || status=1

  for n in 1 2 3; do
    [[ -f "$kit/mock-exams/mock-$n.set" ]] || continue
    bash "$cli/tools/build-mock.sh" "$n" || status=1
  done
done

printf '\n== lab tables ==\n'
python3 scripts/build-lab-table.py || status=1

printf '\n== planned markers ==\n'
python3 scripts/refresh-planned-markers.py --write | tail -1 || status=1

printf '\n== tables of contents ==\n'
python3 scripts/generate_toc.py --inject "${kits[@]}" | tail -1 || status=1

printf '\n'
if [[ $status -eq 0 ]]; then
  echo "regenerate: done. Now run: bash scripts/check-docs.sh"
else
  echo "regenerate: FAILURES (see above)"
fi
exit $status
