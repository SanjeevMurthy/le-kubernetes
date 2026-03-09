#!/bin/bash
# Q16 — MariaDB PV: Verify
PASS=0; FAIL=0
echo "🔍 Checking PVC mariadb is Bound..."
STATUS=$(kubectl get pvc mariadb -n mariadb -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
if [[ "$STATUS" == "Bound" ]]; then echo "  ✅ PVC Bound"; ((PASS++)); else echo "  ❌ PVC: $STATUS"; ((FAIL++)); fi
echo "🔍 Checking MariaDB deployment is running..."
READY=$(kubectl get deployment mariadb -n mariadb -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
if [[ "$READY" -ge 1 ]]; then echo "  ✅ Running ($READY replicas)"; ((PASS++)); else echo "  ❌ Ready: $READY"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"; [[ $FAIL -eq 0 ]]
