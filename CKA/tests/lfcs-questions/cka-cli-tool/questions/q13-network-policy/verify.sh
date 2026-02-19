#!/bin/bash
# Q13 — Network Policy: Verify
PASS=0; FAIL=0
echo "🔍 Checking NetworkPolicy exists in backend namespace..."
NP=$(kubectl get networkpolicy -n backend --no-headers 2>/dev/null | wc -l)
if [[ "$NP" -gt 0 ]]; then echo "  ✅ NetworkPolicy deployed"; ((PASS++)); else echo "  ❌ No NetworkPolicy in backend"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"; [[ $FAIL -eq 0 ]]
