#!/bin/bash
# Q20 audit forensics: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

ANS="$COURSE_DIR/20/answer.txt"
EXPECT="$CKS_STATE_DIR/q20.answer"

if [[ ! -f "$EXPECT" ]]; then
  echo "  FAIL: no expected answer recorded. Run setup first."
  echo ""; echo "Results: 0 passed, 1 failed"; exit 1
fi

field() { grep -m1 "^$1=" "$2" 2>/dev/null | cut -d= -f2- | tr -d ' \r'; }

echo "Checking the deliverable exists..."
check "answer.txt written to $COURSE_DIR/20" test -f "$ANS"

for k in user ip time gets; do
  echo "Checking $k..."
  check_eq "$k is correct" "$(field "$k" "$EXPECT")" "$(field "$k" "$ANS")"
done

summary
