#!/bin/bash
# Q10 — Taints and Tolerations: Verify
PASS=0; FAIL=0

echo "🔍 Checking taint on node01..."
TAINT=$(kubectl describe node node01 2>/dev/null | grep "PERMISSION=granted:NoSchedule" || echo "")
if [[ -n "$TAINT" ]]; then
  echo "  ✅ Taint PERMISSION=granted:NoSchedule exists on node01"
  ((PASS++))
else
  echo "  ❌ Taint not found on node01"
  ((FAIL++))
fi

echo "🔍 Checking a running pod exists on node01..."
POD_ON_NODE=$(kubectl get pods -o wide --no-headers --field-selector=status.phase=Running 2>/dev/null | awk '{print $1, $7}' | grep node01 | head -1 || echo "")
if [[ -n "$POD_ON_NODE" ]]; then
  POD_NAME=$(echo "$POD_ON_NODE" | awk '{print $1}')
  echo "  ✅ Pod '$POD_NAME' is running on node01"
  ((PASS++))

  echo "🔍 Checking pod has the correct toleration..."
  TOLERATION=$(kubectl get pod "$POD_NAME" -o jsonpath='{.spec.tolerations}' 2>/dev/null || echo "")
  if echo "$TOLERATION" | grep -q "PERMISSION"; then
    echo "  ✅ Pod has PERMISSION toleration"
    ((PASS++))
  else
    echo "  ❌ Pod is on node01 but does not have PERMISSION toleration"
    ((FAIL++))
  fi
else
  echo "  ❌ No running pod found on node01"
  ((FAIL++))
  echo "  (skipping toleration check)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
