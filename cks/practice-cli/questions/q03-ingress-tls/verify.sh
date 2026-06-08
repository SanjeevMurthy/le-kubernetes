#!/bin/bash
# Q3 — Verify
PASS=0; FAIL=0

echo "Checking TLS secret 'web-tls' (type kubernetes.io/tls)..."
TYPE=$(kubectl get secret web-tls -n prod -o jsonpath='{.type}' 2>/dev/null)
if [[ "$TYPE" == "kubernetes.io/tls" ]]; then
  echo "  PASS: web-tls is a kubernetes.io/tls secret"; ((PASS++))
else
  echo "  FAIL: secret web-tls missing or wrong type ('$TYPE')"; ((FAIL++))
fi

echo "Checking Ingress 'web-ingress' references secret web-tls..."
SEC=$(kubectl get ingress web-ingress -n prod -o jsonpath='{.spec.tls[0].secretName}' 2>/dev/null)
if [[ "$SEC" == "web-tls" ]]; then
  echo "  PASS: ingress tls.secretName is web-tls"; ((PASS++))
else
  echo "  FAIL: ingress tls.secretName is '$SEC' (expected web-tls)"; ((FAIL++))
fi

echo "Checking Ingress host secure.example.com..."
if kubectl get ingress web-ingress -n prod -o json 2>/dev/null | grep -q 'secure.example.com'; then
  echo "  PASS: host secure.example.com configured"; ((PASS++))
else
  echo "  FAIL: host secure.example.com not found on ingress"; ((FAIL++))
fi

echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
