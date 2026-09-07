#!/bin/bash
# Q02 process and I/O: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

ANS="$COURSE_DIR/2/pid.txt"
REAL=$(pgrep -f 'lfcs-reader' | head -1)

echo "Checking the scenario is still live..."
check "the reader process is still running" test -n "$REAL"
if [[ -z "$REAL" ]]; then
  echo "  The reader is gone, so the remaining checks cannot mean anything. Run setup again."
  summary
  exit $?
fi

echo "Checking the deliverable..."
check "pid.txt exists at $COURSE_DIR/2" test -f "$ANS"
check_eq "pid.txt holds the reader PID" "$REAL" "$(tr -dc '0-9' < "$ANS" 2>/dev/null)"

echo "Checking the priority..."
check_eq "the reader now runs at nice 15" "15" "$(ps -o ni= -p "$REAL" 2>/dev/null | tr -d ' ')"

echo ""
echo "Note: a nice value set with renice lives only as long as the process."
echo "The persistent form is Nice= inside a systemd unit, which Q10 covers."

summary
