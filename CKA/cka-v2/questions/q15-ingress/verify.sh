#!/bin/bash
# Q15 — Create an Ingress Resource: Verify
PASS=0; FAIL=0

echo "Checking Ingress 'app-ingress' exists in echo-app namespace..."
if kubectl get ingress app-ingress -n echo-app &>/dev/null; then
  echo "  PASS: Ingress app-ingress exists"
  ((PASS++))
else
  echo "  FAIL: Ingress app-ingress not found in echo-app namespace"
  ((FAIL++))
fi

echo "Checking Ingress has host rule for myapp.example.com..."
HOST=$(kubectl get ingress app-ingress -n echo-app -o jsonpath='{.spec.rules[*].host}' 2>/dev/null)
if [[ "$HOST" == *"myapp.example.com"* ]]; then
  echo "  PASS: Host rule for myapp.example.com found"
  ((PASS++))
else
  echo "  FAIL: Host is '$HOST', expected 'myapp.example.com'"
  ((FAIL++))
fi

echo "Checking Ingress has path /api with pathType Prefix..."
PATH_VAL=$(kubectl get ingress app-ingress -n echo-app -o jsonpath='{.spec.rules[0].http.paths[0].path}' 2>/dev/null)
PATH_TYPE=$(kubectl get ingress app-ingress -n echo-app -o jsonpath='{.spec.rules[0].http.paths[0].pathType}' 2>/dev/null)
if [[ "$PATH_VAL" == "/api" && "$PATH_TYPE" == "Prefix" ]]; then
  echo "  PASS: Path /api with pathType Prefix found"
  ((PASS++))
else
  echo "  FAIL: Path is '$PATH_VAL' (type '$PATH_TYPE'), expected '/api' with 'Prefix'"
  ((FAIL++))
fi

echo "Checking backend service is api-service on port 8080..."
SVC_NAME=$(kubectl get ingress app-ingress -n echo-app -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null)
SVC_PORT=$(kubectl get ingress app-ingress -n echo-app -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.port.number}' 2>/dev/null)
if [[ "$SVC_NAME" == "api-service" && "$SVC_PORT" == "8080" ]]; then
  echo "  PASS: Backend is api-service on port 8080"
  ((PASS++))
else
  echo "  FAIL: Backend is '$SVC_NAME:$SVC_PORT', expected 'api-service:8080'"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
