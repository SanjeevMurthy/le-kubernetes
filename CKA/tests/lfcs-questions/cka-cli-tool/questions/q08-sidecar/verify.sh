#!/bin/bash
# Q8 — Sidecar: Verify
PASS=0; FAIL=0
echo "🔍 Checking sidecar container exists in deployment..."
SC=$(kubectl get deployment wordpress -o jsonpath='{.spec.template.spec.containers[*].name}' 2>/dev/null || echo "")
if echo "$SC" | grep -q "sidecar"; then echo "  ✅ Sidecar container found"; ((PASS++)); else echo "  ❌ No sidecar container"; ((FAIL++)); fi
echo "🔍 Checking pods show 2/2 ready..."
READY=$(kubectl get pods -l app=wordpress --no-headers 2>/dev/null | head -1 | awk '{print $2}')
if [[ "$READY" == "2/2" ]]; then echo "  ✅ 2/2 containers ready"; ((PASS++)); else echo "  ❌ Ready: $READY"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"; [[ $FAIL -eq 0 ]]
