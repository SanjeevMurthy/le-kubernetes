#!/bin/bash
# Q12 — Ingress: Verify
PASS=0; FAIL=0

echo "🔍 Checking service 'echo-service' exists..."
if kubectl get svc echo-service -n echo-sound &>/dev/null; then
  echo "  ✅ Service exists"
  ((PASS++))
else
  echo "  ❌ Service 'echo-service' not found"
  ((FAIL++))
fi

echo "🔍 Checking service type is NodePort..."
SVC_TYPE=$(kubectl get svc echo-service -n echo-sound -o jsonpath='{.spec.type}' 2>/dev/null || echo "")
if [[ "$SVC_TYPE" == "NodePort" ]]; then
  echo "  ✅ Service type: NodePort"
  ((PASS++))
else
  echo "  ❌ Service type: '$SVC_TYPE' (expected: NodePort)"
  ((FAIL++))
fi

echo "🔍 Checking service port is 8080..."
SVC_PORT=$(kubectl get svc echo-service -n echo-sound -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "")
if [[ "$SVC_PORT" == "8080" ]]; then
  echo "  ✅ Service port: 8080"
  ((PASS++))
else
  echo "  ❌ Service port: '$SVC_PORT' (expected: 8080)"
  ((FAIL++))
fi

echo "🔍 Checking ingress 'echo' exists..."
if kubectl get ingress echo -n echo-sound &>/dev/null; then
  echo "  ✅ Ingress exists"
  ((PASS++))
else
  echo "  ❌ Ingress 'echo' not found"
  ((FAIL++))
fi

echo "🔍 Checking ingress host is example.org..."
HOST=$(kubectl get ingress echo -n echo-sound -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "")
if [[ "$HOST" == "example.org" ]]; then
  echo "  ✅ Host: example.org"
  ((PASS++))
else
  echo "  ❌ Host: '$HOST' (expected: example.org)"
  ((FAIL++))
fi

echo "🔍 Checking ingress path is /echo..."
PATH_VAL=$(kubectl get ingress echo -n echo-sound -o jsonpath='{.spec.rules[0].http.paths[0].path}' 2>/dev/null || echo "")
if [[ "$PATH_VAL" == "/echo" ]]; then
  echo "  ✅ Path: /echo"
  ((PASS++))
else
  echo "  ❌ Path: '$PATH_VAL' (expected: /echo)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
