#!/bin/bash
# Q34 find and permissions: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

DIR="$COURSE_DIR/34"
STATE="$LFCS_STATE_DIR/q34"
FOUND="$DIR/found"
SUID="$DIR/suid.txt"
SH="$DIR/shared"

echo "Checking the scenario is still in place..."
check "the tree to search is present at $DIR/data" test -d "$DIR/data"
check "the expected file list recorded by setup is present" test -s "$STATE/modes"
if [[ ! -s "$STATE/modes" ]]; then
  echo "  Setup did not record the expected files, so nothing below can be graded. Run setup again."
  summary
  exit $?
fi

echo "Checking the copied files..."
GOT=$(ls -1 "$FOUND" 2>/dev/null | sort | tr '\n' ' ')
EXP=$(awk '{print $1}' "$STATE/modes" | sort | tr '\n' ' ')
check_eq "found/ holds exactly the files owned by auditor and larger than 1 MiB" "$EXP" "$GOT"

while read -r name mode owner; do
  [[ -z "$name" ]] && continue
  check_eq "$name keeps its original mode $mode" "$mode" "$(stat -c %a "$FOUND/$name" 2>/dev/null)"
  check_eq "$name keeps its original owner $owner" "$owner" "$(stat -c %U "$FOUND/$name" 2>/dev/null)"
  SRC=$(find "$DIR/data" -type f -name "$name" -print -quit 2>/dev/null)
  check_eq "$name keeps its original modification time" \
    "$(stat -c %Y "$SRC" 2>/dev/null)" "$(stat -c %Y "$FOUND/$name" 2>/dev/null)"
done < "$STATE/modes"

echo "Checking the SUID report..."
check "suid.txt exists at $SUID" test -s "$SUID"
EXPN=$(find /usr/bin -type f -perm -4000 2>/dev/null | wc -l | tr -d ' ')
GOTN=$(grep -c . "$SUID" 2>/dev/null)
GOTN=${GOTN:-0}
check_contains "suid.txt lists /usr/bin/passwd" "/usr/bin/passwd" "$(cat "$SUID" 2>/dev/null)"
check_eq "suid.txt holds one line per SUID binary under /usr/bin" "$EXPN" "$GOTN"

echo "Checking the shared directory..."
check_eq "shared is mode 3775" "3775" "$(stat -c %a "$SH" 2>/dev/null)"
check_eq "shared shows SGID and the sticky bit" "drwxrwsr-t" "$(stat -c %A "$SH" 2>/dev/null)"
check_eq "shared belongs to group devs" "devs" "$(stat -c %G "$SH" 2>/dev/null)"

PROBE="$SH/.lfcs-probe"
rm -f "$PROBE"
runuser -u auditor -- touch "$PROBE" >/dev/null 2>&1
check "auditor can create a file inside shared" test -f "$PROBE"
check_eq "a file auditor creates inside shared inherits group devs" "devs" \
  "$(stat -c %G "$PROBE" 2>/dev/null)"
rm -f "$PROBE"

echo ""
echo "Note: this task has no configuration file to persist. The copies, the report"
echo "and the mode bits on disk are the whole deliverable."

summary
