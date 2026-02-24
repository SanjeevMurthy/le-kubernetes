#!/bin/bash
# Q9 — Sidecar: Verify
PASS=0; FAIL=0

echo "🔍 Checking sidecar container exists in deployment..."
CONTAINERS=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[*].name}' 2>/dev/null || echo "")
if echo "$CONTAINERS" | grep -q "sidecar"; then
  echo "  ✅ Sidecar container found"
  ((PASS++))
else
  echo "  ❌ No sidecar container in deployment"
  ((FAIL++))
fi

echo "🔍 Checking shared emptyDir volume exists..."
HAS_EMPTYDIR=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.volumes}' 2>/dev/null | grep -c "emptyDir" || echo "0")
if [[ "$HAS_EMPTYDIR" -gt 0 ]]; then
  echo "  ✅ Shared emptyDir volume found"
  ((PASS++))
else
  echo "  ❌ No emptyDir volume found in deployment"
  ((FAIL++))
fi

echo "🔍 Checking pods show 2/2 ready..."
READY=$(kubectl get pods -l app=wordpress --no-headers 2>/dev/null | head -1 | awk '{print $2}')
if [[ "$READY" == "2/2" ]]; then
  echo "  ✅ 2/2 containers ready"
  ((PASS++))
else
  echo "  ❌ Ready: $READY (expected: 2/2)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
