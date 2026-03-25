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

echo "Checking pod logs show successful API response (no 403 Forbidden)..."
# Wait a moment for fresh logs with the new SA
sleep 12
LOGS=$(kubectl logs metrics-pod -n monitoring --tail=20 2>/dev/null)
if echo "$LOGS" | grep -q '"kind":"PodList"'; then
  echo "  PASS: Pod can successfully list pods via the K8s API"
  ((PASS++))
elif echo "$LOGS" | grep -q 'Forbidden'; then
  echo "  FAIL: Pod logs still show 403 Forbidden — wrong ServiceAccount?"
  ((FAIL++))
else
  echo "  FAIL: Could not confirm API access from pod logs"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
