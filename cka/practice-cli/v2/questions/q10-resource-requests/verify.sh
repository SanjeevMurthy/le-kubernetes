#!/bin/bash
# Q10 — Resource Requests/Limits for Pending Pods: Verify
PASS=0; FAIL=0

echo "Checking deployment resource-app exists..."
if kubectl get deployment resource-app -n default &>/dev/null; then
  echo "  PASS: Deployment resource-app exists"
  ((PASS++))
else
  echo "  FAIL: Deployment resource-app not found"
  ((FAIL++))
fi

echo "Checking all 3 replicas are Running (not Pending)..."
RUNNING=$(kubectl get pods -n default -l app=resource-app --no-headers 2>/dev/null | grep -c "Running" || true)
if [[ "$RUNNING" -eq 3 ]]; then
  echo "  PASS: All 3 replicas are Running"
  ((PASS++))
else
  echo "  FAIL: $RUNNING pods Running (expected: 3)"
  ((FAIL++))
fi

echo "Checking deployment has resource requests set..."
CPU_REQ=$(kubectl get deployment resource-app -n default -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null || echo "")
MEM_REQ=$(kubectl get deployment resource-app -n default -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null || echo "")
if [[ -n "$CPU_REQ" && -n "$MEM_REQ" ]]; then
  echo "  PASS: Resource requests set (cpu=$CPU_REQ, memory=$MEM_REQ)"
  ((PASS++))
else
  echo "  FAIL: Resource requests not properly set (cpu=$CPU_REQ, memory=$MEM_REQ)"
  ((FAIL++))
fi

echo "Checking no Pending pods for this deployment..."
PENDING=$(kubectl get pods -n default -l app=resource-app --no-headers 2>/dev/null | grep -c "Pending" || true)
if [[ "$PENDING" -eq 0 ]]; then
  echo "  PASS: No Pending pods"
  ((PASS++))
else
  echo "  FAIL: $PENDING pods still Pending"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
