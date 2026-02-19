#!/bin/bash
# Q12 — Gateway API: Verify
PASS=0; FAIL=0
echo "🔍 Checking Gateway web-gateway exists..."
if kubectl get gateway web-gateway &>/dev/null; then echo "  ✅ Gateway exists"; ((PASS++)); else echo "  ❌ Not found"; ((FAIL++)); fi
echo "🔍 Checking HTTPRoute web-route exists..."
if kubectl get httproute web-route &>/dev/null; then echo "  ✅ HTTPRoute exists"; ((PASS++)); else echo "  ❌ Not found"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"; [[ $FAIL -eq 0 ]]
