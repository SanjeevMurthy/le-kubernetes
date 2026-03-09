#!/bin/bash
# Q17 — Fix Service Selector Mismatch: Verify
PASS=0; FAIL=0

echo "Checking service backend-svc has endpoints..."
ENDPOINTS=$(kubectl get endpoints backend-svc -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
if [[ -n "$ENDPOINTS" ]]; then
  echo "  PASS: Service backend-svc has endpoints ($ENDPOINTS)"
  ((PASS++))
else
  echo "  FAIL: Service backend-svc has no endpoints (empty), expected at least one"
  ((FAIL++))
fi

echo "Checking service selector matches deployment labels..."
SVC_SEL_APP=$(kubectl get svc backend-svc -o jsonpath='{.spec.selector.app}' 2>/dev/null)
DEP_LABEL_APP=$(kubectl get deployment backend -o jsonpath='{.spec.template.metadata.labels.app}' 2>/dev/null)
if [[ "$SVC_SEL_APP" == "$DEP_LABEL_APP" && -n "$SVC_SEL_APP" ]]; then
  echo "  PASS: Service selector app=$SVC_SEL_APP matches deployment label app=$DEP_LABEL_APP"
  ((PASS++))
else
  echo "  FAIL: Service selector app='$SVC_SEL_APP' does not match deployment label app='$DEP_LABEL_APP'"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
