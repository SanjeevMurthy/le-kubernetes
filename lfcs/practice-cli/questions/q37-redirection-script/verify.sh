#!/bin/bash
# Q37 redirection: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

DIR="$COURSE_DIR/37"
SCRIPT="$DIR/report.sh"

echo "Checking the script itself..."
check "report.sh exists at $SCRIPT" test -f "$SCRIPT"
check "report.sh is executable" test -x "$SCRIPT"
check_file_has "report.sh starts with the bash shebang" '^#!/bin/bash' "$SCRIPT"
check "report.sh parses cleanly with bash -n" bash -n "$SCRIPT"

if [[ ! -x "$SCRIPT" ]]; then
  echo "  The script cannot be run, so the remaining checks cannot mean anything."
  summary
  exit $?
fi

echo "Running the script from another directory..."
rm -f "$DIR/report.txt" "$DIR/errors.txt"
rm -rf "$DIR/missing"
RUNDIR=$(mktemp -d)
OUT=$(cd "$RUNDIR" && "$SCRIPT" 2>"$RUNDIR/term.err")
TERMERR=$(cat "$RUNDIR/term.err" 2>/dev/null)

check_eq "it prints DONE on standard output and nothing else" "DONE" "$(printf '%s' "$OUT" | tr -d '\n')"
check_eq "nothing reaches the terminal on standard error" "" "$TERMERR"

echo "Checking the report file..."
check "report.txt was created" test -s "$DIR/report.txt"
check_file_has "report.txt carries the df -h header" '^Filesystem' "$DIR/report.txt"
check_file_has "report.txt carries the free -m output" '^Mem:' "$DIR/report.txt"
LAST=$(tail -n 1 "$DIR/report.txt" 2>/dev/null)
check "the last line of report.txt is a date ('$LAST')" date -d "$LAST"

echo "Checking the error file..."
check "errors.txt was created" test -f "$DIR/errors.txt"
check_file_has "the failed listing's message landed in errors.txt" \
  'No such file or directory' "$DIR/errors.txt"
check_not "the error message did not also land in report.txt" \
  grep -q 'No such file or directory' "$DIR/report.txt"

rm -rf "$RUNDIR"

echo ""
echo "Note: this task has no configuration file to persist. The script and the two"
echo "files it writes are the whole deliverable."

summary
