#!/bin/bash
# Q8 — Add Sidecar Log Container: Verify
PASS=0; FAIL=0

echo "Checking deployment exists in logging namespace..."
if kubectl get deployment app-deployment -n logging &>/dev/null; then
  echo "  PASS: Deployment app-deployment exists"
  ((PASS++))
else
  echo "  FAIL: Deployment app-deployment not found in logging namespace"
  ((FAIL++))
fi

echo "Checking pod has 2 containers..."
CONTAINER_COUNT=$(kubectl get deployment app-deployment -n logging -o jsonpath='{.spec.template.spec.containers}' 2>/dev/null | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
if [[ "$CONTAINER_COUNT" == "2" ]]; then
  echo "  PASS: Pod spec has 2 containers"
  ((PASS++))
else
  echo "  FAIL: Pod spec has $CONTAINER_COUNT containers (expected: 2)"
  ((FAIL++))
fi

echo "Checking emptyDir volume exists..."
HAS_EMPTYDIR=$(kubectl get deployment app-deployment -n logging -o jsonpath='{.spec.template.spec.volumes}' 2>/dev/null | grep -c "emptyDir" || true)
if [[ "$HAS_EMPTYDIR" -gt 0 ]]; then
  echo "  PASS: emptyDir volume found"
  ((PASS++))
else
  echo "  FAIL: No emptyDir volume found in deployment"
  ((FAIL++))
fi

echo "Checking both containers mount the shared volume..."
MOUNT_COUNT=$(kubectl get deployment app-deployment -n logging -o json 2>/dev/null | python3 -c "
import sys, json
spec = json.load(sys.stdin)
containers = spec['spec']['template']['spec']['containers']
count = 0
for c in containers:
    mounts = c.get('volumeMounts', [])
    if len(mounts) > 0:
        count += 1
print(count)
" 2>/dev/null || echo "0")
if [[ "$MOUNT_COUNT" == "2" ]]; then
  echo "  PASS: Both containers have volume mounts"
  ((PASS++))
else
  echo "  FAIL: $MOUNT_COUNT containers have volume mounts (expected: 2)"
  ((FAIL++))
fi

echo "Checking pods show 2/2 ready..."
READY=$(kubectl get pods -n logging -l app=app-deployment --no-headers 2>/dev/null | head -1 | awk '{print $2}')
if [[ "$READY" == "2/2" ]]; then
  echo "  PASS: 2/2 containers ready"
  ((PASS++))
else
  echo "  FAIL: Ready status is '$READY' (expected: 2/2)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
