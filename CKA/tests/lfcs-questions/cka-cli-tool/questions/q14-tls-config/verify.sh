#!/bin/bash
# Q14 — TLS Config: Verify
PASS=0; FAIL=0

echo "🔍 Checking ConfigMap has TLSv1.2..."
PROTO=$(kubectl get cm nginx-config -n nginx-static -o yaml 2>/dev/null | grep ssl_protocols || echo "")
if echo "$PROTO" | grep -q "TLSv1.2"; then
  echo "  ✅ TLSv1.2 present in ssl_protocols"
  ((PASS++))
else
  echo "  ❌ TLSv1.2 not found in ssl_protocols"
  ((FAIL++))
fi

echo "🔍 Checking ConfigMap still has TLSv1.3..."
if echo "$PROTO" | grep -q "TLSv1.3"; then
  echo "  ✅ TLSv1.3 still present"
  ((PASS++))
else
  echo "  ❌ TLSv1.3 missing from ssl_protocols"
  ((FAIL++))
fi

echo "🔍 Checking ConfigMap is immutable..."
IMM=$(kubectl get cm nginx-config -n nginx-static -o jsonpath='{.immutable}' 2>/dev/null || echo "")
if [[ "$IMM" == "true" ]]; then
  echo "  ✅ ConfigMap is immutable"
  ((PASS++))
else
  echo "  ❌ immutable=$IMM (expected: true)"
  ((FAIL++))
fi

echo "🔍 Checking /etc/hosts has ckaquestion.k8s.local..."
if grep -q "ckaquestion.k8s.local" /etc/hosts 2>/dev/null; then
  echo "  ✅ /etc/hosts entry exists"
  ((PASS++))
else
  echo "  ❌ ckaquestion.k8s.local not in /etc/hosts"
  ((FAIL++))
fi

echo "🔍 Checking nginx-service exists..."
if kubectl get svc nginx-service -n nginx-static &>/dev/null; then
  echo "  ✅ Service nginx-service exists"
  ((PASS++))
else
  echo "  ❌ Service nginx-service not found"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
