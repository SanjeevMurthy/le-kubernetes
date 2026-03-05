#!/bin/bash
# Q14 — Gateway API Migration with TLS: Verify
PASS=0; FAIL=0

echo "Checking Gateway 'web-gateway' exists..."
if kubectl get gateway web-gateway &>/dev/null; then
  echo "  PASS: Gateway web-gateway exists"
  ((PASS++))
else
  echo "  FAIL: Gateway web-gateway not found"
  ((FAIL++))
fi

echo "Checking Gateway uses gatewayClassName: nginx-class..."
GW_CLASS=$(kubectl get gateway web-gateway -o jsonpath='{.spec.gatewayClassName}' 2>/dev/null)
if [[ "$GW_CLASS" == "nginx-class" ]]; then
  echo "  PASS: Gateway uses gatewayClassName nginx-class"
  ((PASS++))
else
  echo "  FAIL: Gateway gatewayClassName is '$GW_CLASS', expected 'nginx-class'"
  ((FAIL++))
fi

echo "Checking Gateway has HTTPS listener with web-tls certificate..."
LISTENER_PROTO=$(kubectl get gateway web-gateway -o jsonpath='{.spec.listeners[*].protocol}' 2>/dev/null)
TLS_REF=$(kubectl get gateway web-gateway -o jsonpath='{.spec.listeners[*].tls.certificateRefs[*].name}' 2>/dev/null)
if echo "$LISTENER_PROTO" | grep -qi "https" && echo "$TLS_REF" | grep -q "web-tls"; then
  echo "  PASS: Gateway has HTTPS listener with web-tls certificate"
  ((PASS++))
else
  echo "  FAIL: Gateway missing HTTPS listener or web-tls certificate (protocol='$LISTENER_PROTO', tlsRef='$TLS_REF')"
  ((FAIL++))
fi

echo "Checking HTTPRoute 'web-route' exists..."
if kubectl get httproute web-route &>/dev/null; then
  echo "  PASS: HTTPRoute web-route exists"
  ((PASS++))
else
  echo "  FAIL: HTTPRoute web-route not found"
  ((FAIL++))
fi

echo "Checking HTTPRoute references web-gateway..."
PARENT_REF=$(kubectl get httproute web-route -o jsonpath='{.spec.parentRefs[*].name}' 2>/dev/null)
if echo "$PARENT_REF" | grep -q "web-gateway"; then
  echo "  PASS: HTTPRoute references web-gateway"
  ((PASS++))
else
  echo "  FAIL: HTTPRoute parentRef is '$PARENT_REF', expected 'web-gateway'"
  ((FAIL++))
fi

echo "Checking HTTPRoute backend is web-service..."
BACKEND=$(kubectl get httproute web-route -o jsonpath='{.spec.rules[*].backendRefs[*].name}' 2>/dev/null)
if echo "$BACKEND" | grep -q "web-service"; then
  echo "  PASS: HTTPRoute backend is web-service"
  ((PASS++))
else
  echo "  FAIL: HTTPRoute backend is '$BACKEND', expected 'web-service'"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
