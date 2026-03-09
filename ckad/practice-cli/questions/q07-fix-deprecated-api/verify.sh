#!/bin/bash
# Q7 — Fix Deprecated API Version: Verify
PASS=0; FAIL=0

echo "Checking deployment broken-app exists..."
if kubectl get deployment broken-app &>/dev/null; then
  echo "  PASS: Deployment broken-app exists"
  ((PASS++))
else
  echo "  FAIL: Deployment broken-app not found"
  ((FAIL++))
fi

echo "Checking deployment is available..."
AVAILABLE=$(kubectl get deployment broken-app -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "0")
if [[ "$AVAILABLE" -ge 1 ]]; then
  echo "  PASS: Deployment has $AVAILABLE available replica(s)"
  ((PASS++))
else
  echo "  FAIL: Deployment has $AVAILABLE available replicas (expected: >= 1)"
  ((FAIL++))
fi

echo "Checking API version is apps/v1..."
API_VERSION=$(kubectl get deployment broken-app -o jsonpath='{.apiVersion}' 2>/dev/null || echo "")
if [[ "$API_VERSION" == "apps/v1" ]]; then
  echo "  PASS: API version is apps/v1"
  ((PASS++))
else
  echo "  FAIL: API version is '$API_VERSION' (expected: apps/v1)"
  ((FAIL++))
fi

echo "Checking selector.matchLabels is set..."
MATCH_LABELS=$(kubectl get deployment broken-app -o jsonpath='{.spec.selector.matchLabels}' 2>/dev/null || echo "")
if [[ -n "$MATCH_LABELS" && "$MATCH_LABELS" != "{}" ]]; then
  echo "  PASS: selector.matchLabels is configured"
  ((PASS++))
else
  echo "  FAIL: selector.matchLabels is missing or empty (expected: non-empty)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
