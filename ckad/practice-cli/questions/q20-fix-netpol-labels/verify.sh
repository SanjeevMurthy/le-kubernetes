#!/bin/bash
# Q20 — Fix NetworkPolicy Labels: Verify
PASS=0; FAIL=0

echo "Checking pod 'web' has label role=frontend..."
WEB_ROLE=$(kubectl get pod web -n netpol-test -o jsonpath='{.metadata.labels.role}' 2>/dev/null)
if [[ "$WEB_ROLE" == "frontend" ]]; then
  echo "  PASS: Pod web has label role=frontend"
  ((PASS++))
else
  echo "  FAIL: Pod web role label is '$WEB_ROLE', expected 'frontend'"
  ((FAIL++))
fi

echo "Checking pod 'api' has label role=backend..."
API_ROLE=$(kubectl get pod api -n netpol-test -o jsonpath='{.metadata.labels.role}' 2>/dev/null)
if [[ "$API_ROLE" == "backend" ]]; then
  echo "  PASS: Pod api has label role=backend"
  ((PASS++))
else
  echo "  FAIL: Pod api role label is '$API_ROLE', expected 'backend'"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
