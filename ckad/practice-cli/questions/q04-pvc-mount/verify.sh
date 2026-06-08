#!/bin/bash
# Q4 — PVC Mount: Verify
PASS=0; FAIL=0

echo "Checking PVC data-pvc exists..."
if kubectl get pvc data-pvc &>/dev/null; then
  echo "  PASS: PVC data-pvc exists"
  ((PASS++))
else
  echo "  FAIL: PVC data-pvc not found"
  ((FAIL++))
fi

echo "Checking PVC data-pvc is Bound..."
PVC_STATUS=$(kubectl get pvc data-pvc -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
if [[ "$PVC_STATUS" == "Bound" ]]; then
  echo "  PASS: PVC is Bound"
  ((PASS++))
else
  echo "  FAIL: PVC status is '$PVC_STATUS' (expected: Bound)"
  ((FAIL++))
fi

echo "Checking Pod data-pod exists..."
if kubectl get pod data-pod &>/dev/null; then
  echo "  PASS: Pod data-pod exists"
  ((PASS++))
else
  echo "  FAIL: Pod data-pod not found"
  ((FAIL++))
fi

echo "Checking Pod data-pod is Running..."
POD_STATUS=$(kubectl get pod data-pod -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
if [[ "$POD_STATUS" == "Running" ]]; then
  echo "  PASS: Pod data-pod is Running"
  ((PASS++))
else
  echo "  FAIL: Pod data-pod status is '$POD_STATUS' (expected: Running)"
  ((FAIL++))
fi

echo "Checking Pod has volumeMount at /data..."
MOUNT_PATH=$(kubectl get pod data-pod -o jsonpath='{.spec.containers[0].volumeMounts[*].mountPath}' 2>/dev/null || echo "")
PVC_CLAIM=$(kubectl get pod data-pod -o jsonpath='{.spec.volumes[*].persistentVolumeClaim.claimName}' 2>/dev/null || echo "")
if echo "$MOUNT_PATH" | grep -q "/data" && echo "$PVC_CLAIM" | grep -q "data-pvc"; then
  echo "  PASS: Pod mounts data-pvc at /data"
  ((PASS++))
else
  echo "  FAIL: Pod mount path is '$MOUNT_PATH' with claim '$PVC_CLAIM' (expected: /data with data-pvc)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
