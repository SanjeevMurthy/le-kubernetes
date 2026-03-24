#!/bin/bash
# Q19 — Fix Ingress Backend: Verify
PASS=0; FAIL=0

echo "Checking Ingress 'api-ingress' exists..."
if kubectl get ingress api-ingress &>/dev/null; then
  echo "  PASS: Ingress api-ingress exists"
  ((PASS++))
else
  echo "  FAIL: Ingress api-ingress not found"
  ((FAIL++))
fi

echo "Checking backend service name is 'store-svc'..."
SVC_NAME=$(kubectl get ingress api-ingress -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null)
if [[ "$SVC_NAME" == "store-svc" ]]; then
  echo "  PASS: Backend service name is store-svc"
  ((PASS++))
else
  echo "  FAIL: Backend service name is '$SVC_NAME', expected 'store-svc'"
  ((FAIL++))
fi

echo "Checking backend service port is 80..."
SVC_PORT=$(kubectl get ingress api-ingress -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.port.number}' 2>/dev/null)
if [[ "$SVC_PORT" == "80" ]]; then
  echo "  PASS: Backend service port is 80"
  ((PASS++))
else
  echo "  FAIL: Backend service port is '$SVC_PORT', expected '80'"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
