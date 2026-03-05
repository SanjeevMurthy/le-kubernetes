#!/bin/bash
# Q2 — CNI Installation and Configuration - Calico: Verify
PASS=0; FAIL=0

echo "Checking Calico pods are running..."
CALICO_PODS=$(kubectl get pods -A --no-headers 2>/dev/null | grep -cE "calico.*(Running|READY)" || true)
if [[ "$CALICO_PODS" -ge 1 ]]; then
  echo "  PASS: $CALICO_PODS Calico pod(s) found running"
  ((PASS++))
else
  echo "  FAIL: No running Calico pods found in any namespace"
  ((FAIL++))
fi

echo "Checking all nodes are Ready..."
NOT_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -cv "Ready" || true)
if [[ "$NOT_READY" -eq 0 ]]; then
  echo "  PASS: All nodes are Ready"
  ((PASS++))
else
  echo "  FAIL: $NOT_READY node(s) are not Ready"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
