#!/bin/bash
# Q4 — PVC Mount: Verify
PASS=0; FAIL=0

echo "Checking PVC task-pvc exists..."
if kubectl get pvc task-pvc &>/dev/null; then
  echo "  PASS: PVC task-pvc exists"
  ((PASS++))
else
  echo "  FAIL: PVC task-pvc not found"
  ((FAIL++))
fi

echo "Checking PVC task-pvc is Bound..."
PVC_STATUS=$(kubectl get pvc task-pvc -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
if [[ "$PVC_STATUS" == "Bound" ]]; then
  echo "  PASS: PVC is Bound"
  ((PASS++))
else
  echo "  FAIL: PVC status is '$PVC_STATUS' (expected: Bound)"
  ((FAIL++))
fi

echo "Checking Pod task-pod exists..."
if kubectl get pod task-pod &>/dev/null; then
  echo "  PASS: Pod task-pod exists"
  ((PASS++))
else
  echo "  FAIL: Pod task-pod not found"
  ((FAIL++))
fi

echo "Checking Pod task-pod is Running..."
POD_STATUS=$(kubectl get pod task-pod -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
if [[ "$POD_STATUS" == "Running" ]]; then
  echo "  PASS: Pod task-pod is Running"
  ((PASS++))
else
  echo "  FAIL: Pod task-pod status is '$POD_STATUS' (expected: Running)"
  ((FAIL++))
fi

echo "Checking Pod has volumeMount at /data..."
MOUNT_PATH=$(kubectl get pod task-pod -o jsonpath='{.spec.containers[0].volumeMounts[*].mountPath}' 2>/dev/null || echo "")
PVC_CLAIM=$(kubectl get pod task-pod -o jsonpath='{.spec.volumes[*].persistentVolumeClaim.claimName}' 2>/dev/null || echo "")
if echo "$MOUNT_PATH" | grep -q "/data" && echo "$PVC_CLAIM" | grep -q "task-pvc"; then
  echo "  PASS: Pod mounts task-pvc at /data"
  ((PASS++))
else
  echo "  FAIL: Pod mount path is '$MOUNT_PATH' with claim '$PVC_CLAIM' (expected: /data with task-pvc)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
