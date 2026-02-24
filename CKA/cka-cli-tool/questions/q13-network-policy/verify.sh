#!/bin/bash
# Q14 — Network Policy: Verify
PASS=0; FAIL=0

echo "🔍 Checking NetworkPolicy exists in backend namespace..."
NP_COUNT=$(kubectl get networkpolicy -n backend --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [[ "$NP_COUNT" -gt 0 ]]; then
  echo "  ✅ NetworkPolicy deployed in backend namespace"
  ((PASS++))
else
  echo "  ❌ No NetworkPolicy found in backend namespace"
  ((FAIL++))
fi

echo "🔍 Checking the correct (least permissive) policy was applied..."
# The correct policy should be policy-z (AND logic with namespaceSelector + podSelector in same from entry)
NP_NAME=$(kubectl get networkpolicy -n backend --no-headers 2>/dev/null | awk '{print $1}' | head -1)
if [[ "$NP_NAME" == "policy-z" ]]; then
  echo "  ✅ Correct policy applied: policy-z (AND logic, least permissive)"
  ((PASS++))
elif [[ "$NP_NAME" == "policy-x" ]]; then
  echo "  ❌ policy-x applied — this allows ALL ingress (too permissive)"
  ((FAIL++))
elif [[ "$NP_NAME" == "policy-y" ]]; then
  echo "  ❌ policy-y applied — this uses OR logic (too permissive)"
  ((FAIL++))
else
  echo "  ⚠️  Custom policy '$NP_NAME' applied — checking if it uses AND logic..."
  # Check if the policy has both namespaceSelector and podSelector in the same from entry
  SPEC=$(kubectl get networkpolicy "$NP_NAME" -n backend -o jsonpath='{.spec.ingress[0].from[0]}' 2>/dev/null || echo "")
  if echo "$SPEC" | grep -q "namespaceSelector" && echo "$SPEC" | grep -q "podSelector"; then
    echo "  ✅ Policy uses AND logic (both selectors in same entry)"
    ((PASS++))
  else
    echo "  ❌ Policy does not use AND logic — may be too permissive"
    ((FAIL++))
  fi
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
