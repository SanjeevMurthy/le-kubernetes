#!/bin/bash
# Q15 — StorageClass: Verify
PASS=0; FAIL=0
echo "🔍 Checking StorageClass local-storage exists..."
if kubectl get sc local-storage &>/dev/null; then echo "  ✅ Exists"; ((PASS++)); else echo "  ❌ Not found"; ((FAIL++)); fi
echo "🔍 Checking local-storage is default..."
DEF=$(kubectl get sc local-storage -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}' 2>/dev/null || echo "")
if [[ "$DEF" == "true" ]]; then echo "  ✅ Is default"; ((PASS++)); else echo "  ❌ Not default"; ((FAIL++)); fi
echo "🔍 Checking only one default SC..."
NUM_DEF=$(kubectl get sc -o jsonpath='{range .items[*]}{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}{"\n"}{end}' 2>/dev/null | grep -c "true")
if [[ "$NUM_DEF" == "1" ]]; then echo "  ✅ Only 1 default"; ((PASS++)); else echo "  ❌ $NUM_DEF defaults"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"; [[ $FAIL -eq 0 ]]
