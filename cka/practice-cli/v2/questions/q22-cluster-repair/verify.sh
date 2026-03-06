#!/bin/bash
# Q22 — General Cluster Troubleshooting - Broken Cluster Repair: Verify
PASS=0; FAIL=0

echo "Checking all nodes are Ready..."
NOT_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c "NotReady" || true)
TOTAL_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [[ "$TOTAL_NODES" -gt 0 && "$NOT_READY" -eq 0 ]]; then
  echo "  PASS: All $TOTAL_NODES node(s) are Ready"
  ((PASS++))
else
  echo "  FAIL: $NOT_READY node(s) are NotReady out of $TOTAL_NODES"
  ((FAIL++))
fi

echo "Checking all nodes show Ready in status..."
READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready" || true)
if [[ "$READY_NODES" -eq "$TOTAL_NODES" ]]; then
  echo "  PASS: $READY_NODES/$TOTAL_NODES nodes in Ready state"
  ((PASS++))
else
  echo "  FAIL: Only $READY_NODES/$TOTAL_NODES nodes in Ready state"
  ((FAIL++))
fi

echo "Checking system pods are running on all nodes..."
FAILED_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -v -E "Running|Completed" | wc -l | tr -d ' ')
if [[ "$FAILED_PODS" -eq 0 ]]; then
  echo "  PASS: All kube-system pods are Running/Completed"
  ((PASS++))
else
  echo "  FAIL: $FAILED_PODS kube-system pod(s) not in Running/Completed state"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
