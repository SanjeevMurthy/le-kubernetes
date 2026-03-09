#!/bin/bash
# Q6 — Rolling Update and Rollback: Verify
PASS=0; FAIL=0

echo "Checking deployment app-v1 exists..."
if kubectl get deployment app-v1 &>/dev/null; then
  echo "  PASS: Deployment app-v1 exists"
  ((PASS++))
else
  echo "  FAIL: Deployment app-v1 not found"
  ((FAIL++))
fi

echo "Checking current image is nginx:1.20 (rolled back)..."
IMAGE=$(kubectl get deployment app-v1 -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "")
if [[ "$IMAGE" == "nginx:1.20" ]]; then
  echo "  PASS: Current image is nginx:1.20"
  ((PASS++))
else
  echo "  FAIL: Current image is '$IMAGE' (expected: nginx:1.20)"
  ((FAIL++))
fi

echo "Checking rollout history has 2+ revisions..."
REVISION_COUNT=$(kubectl rollout history deployment app-v1 2>/dev/null | grep -c '^[0-9]' || echo "0")
if [[ "$REVISION_COUNT" -ge 2 ]]; then
  echo "  PASS: Rollout history has $REVISION_COUNT revisions"
  ((PASS++))
else
  echo "  FAIL: Rollout history has $REVISION_COUNT revisions (expected: 2+)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
