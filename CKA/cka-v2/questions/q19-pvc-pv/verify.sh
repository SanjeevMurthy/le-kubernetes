#!/bin/bash
# Q19 — Create PVC and Bind to Existing PV: Verify
PASS=0; FAIL=0

echo "Checking PVC 'data-pvc' exists..."
if kubectl get pvc data-pvc &>/dev/null; then
  echo "  PASS: PVC data-pvc exists"
  ((PASS++))
else
  echo "  FAIL: PVC data-pvc not found"
  ((FAIL++))
fi

echo "Checking PVC is Bound..."
PVC_STATUS=$(kubectl get pvc data-pvc -o jsonpath='{.status.phase}' 2>/dev/null)
if [[ "$PVC_STATUS" == "Bound" ]]; then
  echo "  PASS: PVC is Bound"
  ((PASS++))
else
  echo "  FAIL: PVC status is '$PVC_STATUS', expected 'Bound'"
  ((FAIL++))
fi

echo "Checking PVC is bound to data-pv..."
PVC_VOL=$(kubectl get pvc data-pvc -o jsonpath='{.spec.volumeName}' 2>/dev/null)
if [[ "$PVC_VOL" == "data-pv" ]]; then
  echo "  PASS: PVC is bound to data-pv"
  ((PASS++))
else
  echo "  FAIL: PVC is bound to '$PVC_VOL', expected 'data-pv'"
  ((FAIL++))
fi

echo "Checking Pod 'data-pod' exists and is Running..."
POD_STATUS=$(kubectl get pod data-pod -o jsonpath='{.status.phase}' 2>/dev/null)
if [[ "$POD_STATUS" == "Running" ]]; then
  echo "  PASS: Pod data-pod is Running"
  ((PASS++))
else
  echo "  FAIL: Pod data-pod status is '$POD_STATUS', expected 'Running'"
  ((FAIL++))
fi

echo "Checking Pod mounts PVC at /usr/share/nginx/html..."
MOUNT_PATH=$(kubectl get pod data-pod -o jsonpath='{.spec.containers[0].volumeMounts[?(@.name)].mountPath}' 2>/dev/null)
PVC_CLAIM=$(kubectl get pod data-pod -o jsonpath='{.spec.volumes[*].persistentVolumeClaim.claimName}' 2>/dev/null)
if echo "$MOUNT_PATH" | grep -q "/usr/share/nginx/html" && echo "$PVC_CLAIM" | grep -q "data-pvc"; then
  echo "  PASS: Pod mounts data-pvc at /usr/share/nginx/html"
  ((PASS++))
else
  echo "  FAIL: Pod mount path is '$MOUNT_PATH' with claim '$PVC_CLAIM', expected '/usr/share/nginx/html' with 'data-pvc'"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
