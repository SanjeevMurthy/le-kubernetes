#!/bin/bash
# Q13 — Fix ServiceAccount Assignment: Verify
PASS=0; FAIL=0

echo "Checking pod metrics-pod uses serviceAccount monitor-sa..."
SA=$(kubectl get pod metrics-pod -n monitoring -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null)
if [[ "$SA" == "monitor-sa" ]]; then
  echo "  PASS: Pod uses serviceAccount monitor-sa"
  ((PASS++))
else
  echo "  FAIL: Pod serviceAccountName is '$SA', expected 'monitor-sa'"
  ((FAIL++))
fi

echo "Checking pod metrics-pod is Running..."
STATUS=$(kubectl get pod metrics-pod -n monitoring -o jsonpath='{.status.phase}' 2>/dev/null)
if [[ "$STATUS" == "Running" ]]; then
  echo "  PASS: Pod is Running"
  ((PASS++))
else
  echo "  FAIL: Pod status is '$STATUS', expected 'Running'"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
