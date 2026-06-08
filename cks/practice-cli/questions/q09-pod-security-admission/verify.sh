#!/bin/bash
# Q9 — Verify
PASS=0; FAIL=0
echo "Checking enforce=restricted label..."
E=$(kubectl get ns payments -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)
if [[ "$E" == "restricted" ]]; then echo "  PASS: enforce=restricted"; ((PASS++)); else echo "  FAIL: enforce label is '$E'"; ((FAIL++)); fi
echo "Checking a privileged pod is rejected..."
OUT=$(kubectl run psa-test --image=nginx --restart=Never -n payments --overrides='{"spec":{"containers":[{"name":"psa-test","image":"nginx","securityContext":{"privileged":true}}]}}' 2>&1 || true)
kubectl delete pod psa-test -n payments --ignore-not-found &>/dev/null
if echo "$OUT" | grep -qi 'forbidden\|violat'; then echo "  PASS: privileged pod rejected"; ((PASS++)); else echo "  FAIL: privileged pod was not rejected"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
