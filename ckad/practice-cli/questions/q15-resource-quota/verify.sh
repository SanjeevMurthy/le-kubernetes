#!/bin/bash
# Q15 — Create Pod Under Resource Quota: Verify
PASS=0; FAIL=0

echo "Checking Pod resource-pod exists in namespace prod..."
if kubectl get pod resource-pod -n prod &>/dev/null; then
  echo "  PASS: Pod resource-pod exists in namespace prod"
  ((PASS++))
else
  echo "  FAIL: Pod resource-pod not found in namespace prod"
  ((FAIL++))
fi

echo "Checking Pod resource-pod is Running..."
STATUS=$(kubectl get pod resource-pod -n prod -o jsonpath='{.status.phase}' 2>/dev/null)
if [[ "$STATUS" == "Running" ]]; then
  echo "  PASS: Pod is Running"
  ((PASS++))
else
  echo "  FAIL: Pod status is '$STATUS', expected 'Running'"
  ((FAIL++))
fi

echo "Checking Pod has resource requests set..."
CPU_REQ=$(kubectl get pod resource-pod -n prod -o jsonpath='{.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
MEM_REQ=$(kubectl get pod resource-pod -n prod -o jsonpath='{.spec.containers[0].resources.requests.memory}' 2>/dev/null)
if [[ -n "$CPU_REQ" && -n "$MEM_REQ" ]]; then
  echo "  PASS: Resource requests set (cpu=$CPU_REQ, memory=$MEM_REQ)"
  ((PASS++))
else
  echo "  FAIL: Resource requests missing (cpu='$CPU_REQ', memory='$MEM_REQ'), both must be set"
  ((FAIL++))
fi

echo "Checking Pod has resource limits set..."
CPU_LIM=$(kubectl get pod resource-pod -n prod -o jsonpath='{.spec.containers[0].resources.limits.cpu}' 2>/dev/null)
MEM_LIM=$(kubectl get pod resource-pod -n prod -o jsonpath='{.spec.containers[0].resources.limits.memory}' 2>/dev/null)
if [[ -n "$CPU_LIM" && -n "$MEM_LIM" ]]; then
  echo "  PASS: Resource limits set (cpu=$CPU_LIM, memory=$MEM_LIM)"
  ((PASS++))
else
  echo "  FAIL: Resource limits missing (cpu='$CPU_LIM', memory='$MEM_LIM'), both must be set"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
