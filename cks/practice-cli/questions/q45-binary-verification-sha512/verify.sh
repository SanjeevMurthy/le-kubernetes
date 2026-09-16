#!/bin/bash
# Q45 binary verification: verify. Naming the right file is half the answer;
# the other half is that the three good binaries were left alone. A candidate
# who deletes everything, or who rewrites checksums.txt until it agrees, has
# not done the task.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

DIR="$COURSE_DIR/45"
BIN="$DIR/binaries"
EXPECTED_FILE="$CKS_STATE_DIR/backup/q45/expected"

if [[ ! -s "$EXPECTED_FILE" ]]; then
  echo "  FAIL: this question has not been set up (run [S] first)"
  echo ""
  echo "Results: 0 passed, 1 failed"
  exit 1
fi
BAD=$(cat "$EXPECTED_FILE")

echo "Checking the published list was not touched..."
# Precondition. If checksums.txt is gone or rewritten, every check below is
# measuring the candidate's own file rather than the release record.
check "$BIN/checksums.txt still exists" test -s "$BIN/checksums.txt"
check_eq "checksums.txt still lists all four binaries" 4 \
  "$(grep -c . "$BIN/checksums.txt" 2>/dev/null || echo 0)"

echo "Checking the tampered binary is gone..."
check_not "binaries/$BAD has been deleted" test -e "$BIN/$BAD"

echo "Checking the three good binaries survived..."
for f in kubectl kubeadm kubelet kube-proxy; do
  [[ "$f" == "$BAD" ]] && continue
  if [[ ! -f "$BIN/$f" ]]; then
    echo "  FAIL: binaries/$f was deleted, and its checksum matched"; FAIL=$((FAIL + 1))
    continue
  fi
  want=$(awk -v n="$f" '$2 == n {print $1}' "$BIN/checksums.txt" 2>/dev/null)
  got=$(sha512sum "$BIN/$f" 2>/dev/null | cut -d' ' -f1)
  if [[ -n "$want" && "$want" == "$got" ]]; then
    echo "  PASS: binaries/$f is intact and still matches its published hash"; PASS=$((PASS + 1))
  else
    echo "  FAIL: binaries/$f no longer matches its published hash"; FAIL=$((FAIL + 1))
  fi
done

echo "Checking the deliverable..."
check "$DIR/tampered exists and is not empty" test -s "$DIR/tampered"
# Read one line and strip any path the candidate may have written, so that
# "binaries/kubelet" is not marked wrong for a reason the task did not ask about.
ANSWER=$(head -1 "$DIR/tampered" 2>/dev/null | tr -d '[:space:]')
ANSWER=${ANSWER##*/}
check_eq "the file named in $DIR/tampered is the one that failed" "$BAD" "${ANSWER:-<empty>}"
check_eq "$DIR/tampered holds exactly one line" 1 \
  "$(grep -c . "$DIR/tampered" 2>/dev/null || echo 0)"

summary
