#!/bin/bash
# Q1 — Verify
PASS=0; FAIL=0
J=$(kubectl get networkpolicy -n prod -o json 2>/dev/null)

echo "Checking a default-deny policy (Ingress+Egress, empty podSelector)..."
if echo "$J" | grep -q '"Ingress"' && echo "$J" | grep -q '"Egress"' && echo "$J" | grep -q '"podSelector":{}'; then
  echo "  PASS: default-deny ingress+egress present"; ((PASS++))
else
  echo "  FAIL: no default-deny policy with empty podSelector and both policyTypes"; ((FAIL++))
fi

echo "Checking allow from frontend to backend on port 8080..."
if echo "$J" | grep -q '"app":"backend"' && echo "$J" | grep -q '"app":"frontend"' && echo "$J" | grep -q '"port":8080'; then
  echo "  PASS: backend accepts ingress from frontend on 8080"; ((PASS++))
else
  echo "  FAIL: missing allow rule (backend <- frontend :8080)"; ((FAIL++))
fi

echo "Checking DNS egress (port 53) is allowed..."
if echo "$J" | grep -q '"port":53'; then
  echo "  PASS: DNS egress (53) allowed"; ((PASS++))
else
  echo "  FAIL: no egress rule for port 53 — DNS would break"; ((FAIL++))
fi

echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
