#!/bin/bash
# Q7 — Resources: Verify
PASS=0; FAIL=0
echo "🔍 Checking wordpress deployment has 3 running replicas..."
READY=$(kubectl get deployment wordpress -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
if [[ "$READY" == "3" ]]; then echo "  ✅ 3 replicas running"; ((PASS++)); else echo "  ❌ Ready: $READY (expected: 3)"; ((FAIL++)); fi
echo "🔍 Checking no Pending pods..."
PENDING=$(kubectl get pods -l app=wordpress --no-headers 2>/dev/null | grep -c "Pending" || true)
if [[ "$PENDING" == "0" ]]; then echo "  ✅ No pending pods"; ((PASS++)); else echo "  ❌ $PENDING pods pending"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"; [[ $FAIL -eq 0 ]]
