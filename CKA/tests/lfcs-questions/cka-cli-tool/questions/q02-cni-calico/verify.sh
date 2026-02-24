#!/bin/bash
# Q2 — CNI Calico: Verify
PASS=0; FAIL=0

echo "🔍 Checking Calico pods in calico-system..."
CALICO=$(kubectl get pods -n calico-system --no-headers 2>/dev/null | grep -c "Running" || echo "0")
if [[ "$CALICO" -gt 0 ]]; then echo "  ✅ $CALICO Calico pods running"; ((PASS++)); else echo "  ❌ No Calico pods running"; ((FAIL++)); fi

echo "🔍 Checking all nodes are Ready..."
NOT_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -cv "Ready" || echo "0")
if [[ "$NOT_READY" == "0" ]]; then echo "  ✅ All nodes Ready"; ((PASS++)); else echo "  ❌ $NOT_READY nodes not Ready"; ((FAIL++)); fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
