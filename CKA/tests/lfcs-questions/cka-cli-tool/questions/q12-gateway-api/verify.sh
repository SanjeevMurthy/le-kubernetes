#!/bin/bash
# Q13 — Gateway API: Verify
PASS=0; FAIL=0

echo "🔍 Checking Gateway 'web-gateway' exists..."
if kubectl get gateway web-gateway &>/dev/null; then
  echo "  ✅ Gateway exists"
  ((PASS++))
else
  echo "  ❌ Gateway 'web-gateway' not found"
  ((FAIL++))
fi

echo "🔍 Checking Gateway uses nginx-class..."
GW_CLASS=$(kubectl get gateway web-gateway -o jsonpath='{.spec.gatewayClassName}' 2>/dev/null || echo "")
if [[ "$GW_CLASS" == "nginx-class" ]]; then
  echo "  ✅ GatewayClass: nginx-class"
  ((PASS++))
else
  echo "  ❌ GatewayClass: '$GW_CLASS' (expected: nginx-class)"
  ((FAIL++))
fi

echo "🔍 Checking Gateway has HTTPS listener with TLS..."
GW_PROTO=$(kubectl get gateway web-gateway -o jsonpath='{.spec.listeners[0].protocol}' 2>/dev/null || echo "")
GW_TLS=$(kubectl get gateway web-gateway -o jsonpath='{.spec.listeners[0].tls.certificateRefs[0].name}' 2>/dev/null || echo "")
if [[ "$GW_PROTO" == "HTTPS" ]] && [[ "$GW_TLS" == "web-tls" ]]; then
  echo "  ✅ HTTPS listener with web-tls certificate"
  ((PASS++))
else
  echo "  ❌ Protocol: '$GW_PROTO', TLS secret: '$GW_TLS' (expected: HTTPS, web-tls)"
  ((FAIL++))
fi

echo "🔍 Checking HTTPRoute 'web-route' exists..."
if kubectl get httproute web-route &>/dev/null; then
  echo "  ✅ HTTPRoute exists"
  ((PASS++))
else
  echo "  ❌ HTTPRoute 'web-route' not found"
  ((FAIL++))
fi

echo "🔍 Checking HTTPRoute references web-gateway..."
PARENT=$(kubectl get httproute web-route -o jsonpath='{.spec.parentRefs[0].name}' 2>/dev/null || echo "")
if [[ "$PARENT" == "web-gateway" ]]; then
  echo "  ✅ HTTPRoute references web-gateway"
  ((PASS++))
else
  echo "  ❌ Parent ref: '$PARENT' (expected: web-gateway)"
  ((FAIL++))
fi

echo "🔍 Checking HTTPRoute backend is web-service..."
BACKEND=$(kubectl get httproute web-route -o jsonpath='{.spec.rules[0].backendRefs[0].name}' 2>/dev/null || echo "")
if [[ "$BACKEND" == "web-service" ]]; then
  echo "  ✅ Backend: web-service"
  ((PASS++))
else
  echo "  ❌ Backend: '$BACKEND' (expected: web-service)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
