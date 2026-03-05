#!/bin/bash
# Q11 — NGINX ConfigMap TLS Configuration: Verify
PASS=0; FAIL=0

echo "Checking ConfigMap nginx-config exists in nginx-tls namespace..."
if kubectl get cm nginx-config -n nginx-tls &>/dev/null; then
  echo "  PASS: ConfigMap nginx-config exists"
  ((PASS++))
else
  echo "  FAIL: ConfigMap nginx-config not found in nginx-tls namespace"
  ((FAIL++))
fi

echo "Checking ConfigMap contains TLSv1.2 in ssl_protocols..."
PROTO=$(kubectl get cm nginx-config -n nginx-tls -o yaml 2>/dev/null | grep ssl_protocols || echo "")
if echo "$PROTO" | grep -q "TLSv1.2"; then
  echo "  PASS: TLSv1.2 present in ssl_protocols"
  ((PASS++))
else
  echo "  FAIL: TLSv1.2 not found in ssl_protocols"
  ((FAIL++))
fi

echo "Checking ConfigMap contains TLSv1.3 in ssl_protocols..."
if echo "$PROTO" | grep -q "TLSv1.3"; then
  echo "  PASS: TLSv1.3 present in ssl_protocols"
  ((PASS++))
else
  echo "  FAIL: TLSv1.3 not found in ssl_protocols"
  ((FAIL++))
fi

echo "Checking deployment nginx-tls exists and pods are running..."
if kubectl get deployment nginx-tls -n nginx-tls &>/dev/null; then
  READY=$(kubectl get deployment nginx-tls -n nginx-tls -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
  if [[ "$READY" -ge 1 ]]; then
    echo "  PASS: Deployment nginx-tls is running ($READY ready replicas)"
    ((PASS++))
  else
    echo "  FAIL: Deployment nginx-tls has no ready replicas"
    ((FAIL++))
  fi
else
  echo "  FAIL: Deployment nginx-tls not found"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
