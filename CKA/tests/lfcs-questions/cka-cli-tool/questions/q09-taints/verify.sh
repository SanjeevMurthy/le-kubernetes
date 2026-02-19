#!/bin/bash
# Q9 — Taints and Tolerations: Verify
set -e
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

echo "🔍 Checking pod with toleration is Running on node01..."
POD_NODE=$(kubectl get pods -o wide --no-headers 2>/dev/null | grep -i running | awk '{print $7}' | grep node01 || echo "")
if [[ -n "$POD_NODE" ]]; then
  echo "  ✅ Pod is running on node01"
  ((PASS++))
else
  echo "  ❌ No running pod found on node01"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
