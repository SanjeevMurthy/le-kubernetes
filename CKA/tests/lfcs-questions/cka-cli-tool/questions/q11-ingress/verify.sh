#!/bin/bash
# Q11 — Ingress: Verify
PASS=0; FAIL=0
echo "🔍 Checking service echo-service exists..."
if kubectl get svc echo-service -n echo-sound &>/dev/null; then echo "  ✅ Service exists"; ((PASS++)); else echo "  ❌ Not found"; ((FAIL++)); fi
echo "🔍 Checking ingress echo exists..."
if kubectl get ingress echo -n echo-sound &>/dev/null; then echo "  ✅ Ingress exists"; ((PASS++)); else echo "  ❌ Not found"; ((FAIL++)); fi
echo "🔍 Checking ingress host is example.org..."
HOST=$(kubectl get ingress echo -n echo-sound -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "")
if [[ "$HOST" == "example.org" ]]; then echo "  ✅ Host: example.org"; ((PASS++)); else echo "  ❌ Host: $HOST"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"; [[ $FAIL -eq 0 ]]
