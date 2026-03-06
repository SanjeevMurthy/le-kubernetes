#!/bin/bash
# Q18 — Create StorageClass and Set as Default: Verify
PASS=0; FAIL=0

echo "Checking StorageClass 'fast-storage' exists..."
if kubectl get storageclass fast-storage &>/dev/null; then
  echo "  PASS: StorageClass fast-storage exists"
  ((PASS++))
else
  echo "  FAIL: StorageClass fast-storage not found"
  ((FAIL++))
fi

echo "Checking provisioner is kubernetes.io/no-provisioner..."
PROVISIONER=$(kubectl get storageclass fast-storage -o jsonpath='{.provisioner}' 2>/dev/null)
if [[ "$PROVISIONER" == "kubernetes.io/no-provisioner" ]]; then
  echo "  PASS: Provisioner is kubernetes.io/no-provisioner"
  ((PASS++))
else
  echo "  FAIL: Provisioner is '$PROVISIONER', expected 'kubernetes.io/no-provisioner'"
  ((FAIL++))
fi

echo "Checking volumeBindingMode is WaitForFirstConsumer..."
BIND_MODE=$(kubectl get storageclass fast-storage -o jsonpath='{.volumeBindingMode}' 2>/dev/null)
if [[ "$BIND_MODE" == "WaitForFirstConsumer" ]]; then
  echo "  PASS: volumeBindingMode is WaitForFirstConsumer"
  ((PASS++))
else
  echo "  FAIL: volumeBindingMode is '$BIND_MODE', expected 'WaitForFirstConsumer'"
  ((FAIL++))
fi

echo "Checking fast-storage is marked as default..."
IS_DEFAULT=$(kubectl get storageclass fast-storage -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}' 2>/dev/null)
if [[ "$IS_DEFAULT" == "true" ]]; then
  echo "  PASS: fast-storage is marked as default"
  ((PASS++))
else
  echo "  FAIL: fast-storage is not marked as default (annotation='$IS_DEFAULT')"
  ((FAIL++))
fi

echo "Checking only one default StorageClass exists..."
DEFAULT_COUNT=$(kubectl get storageclass -o json 2>/dev/null | grep -c '"storageclass.kubernetes.io/is-default-class":"true"' || true)
if [[ "$DEFAULT_COUNT" -eq 1 ]]; then
  echo "  PASS: Exactly one default StorageClass exists"
  ((PASS++))
else
  echo "  FAIL: Found $DEFAULT_COUNT default StorageClasses, expected 1"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
