#!/bin/bash
# Q24 — CrashLoopBackOff Debug: Verify
PASS=0; FAIL=0

echo "Checking /root/error_events.txt exists..."
if [[ -f /root/error_events.txt ]]; then
  echo "  PASS: /root/error_events.txt exists"
  ((PASS++))
else
  echo "  FAIL: /root/error_events.txt not found"
  ((FAIL++))
fi

echo "Checking /root/error_events.txt is non-empty..."
if [[ -s /root/error_events.txt ]]; then
  LINES=$(wc -l < /root/error_events.txt | tr -d ' ')
  echo "  PASS: /root/error_events.txt is non-empty ($LINES lines)"
  ((PASS++))
else
  echo "  FAIL: /root/error_events.txt is empty"
  ((FAIL++))
fi

echo "Checking /root/error_events.txt contains event data..."
if grep -qi -e "crash-pod" -e "BackOff" -e "Events" /root/error_events.txt 2>/dev/null; then
  echo "  PASS: File contains event data for crash-pod"
  ((PASS++))
else
  ACTUAL=$(head -3 /root/error_events.txt 2>/dev/null)
  echo "  FAIL: File does not contain expected event data (first 3 lines: $ACTUAL)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
