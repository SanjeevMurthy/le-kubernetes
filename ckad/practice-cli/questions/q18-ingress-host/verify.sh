#!/bin/bash
# Q18 — Create Ingress with Host Rule: Verify
PASS=0; FAIL=0

echo "Checking Ingress webapp-ingress exists..."
if kubectl get ingress webapp-ingress &>/dev/null; then
  echo "  PASS: Ingress webapp-ingress exists"
  ((PASS++))
else
  echo "  FAIL: Ingress webapp-ingress not found"
  ((FAIL++))
fi

echo "Checking Ingress host is webapp.example.com..."
HOST=$(kubectl get ingress webapp-ingress -o jsonpath='{.spec.rules[0].host}' 2>/dev/null)
if [[ "$HOST" == "webapp.example.com" ]]; then
  echo "  PASS: Host is webapp.example.com"
  ((PASS++))
else
  echo "  FAIL: Host is '$HOST', expected 'webapp.example.com'"
  ((FAIL++))
fi

echo "Checking Ingress path is /..."
PATH_VAL=$(kubectl get ingress webapp-ingress -o jsonpath='{.spec.rules[0].http.paths[0].path}' 2>/dev/null)
if [[ "$PATH_VAL" == "/" ]]; then
  echo "  PASS: Path is /"
  ((PASS++))
else
  echo "  FAIL: Path is '$PATH_VAL', expected '/'"
  ((FAIL++))
fi

echo "Checking backend service name is webapp-svc..."
SVC_NAME=$(kubectl get ingress webapp-ingress -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null)
if [[ "$SVC_NAME" == "webapp-svc" ]]; then
  echo "  PASS: Backend service is webapp-svc"
  ((PASS++))
else
  echo "  FAIL: Backend service is '$SVC_NAME', expected 'webapp-svc'"
  ((FAIL++))
fi

echo "Checking backend service port is 8080..."
SVC_PORT=$(kubectl get ingress webapp-ingress -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.port.number}' 2>/dev/null)
if [[ "$SVC_PORT" == "8080" ]]; then
  echo "  PASS: Backend service port is 8080"
  ((PASS++))
else
  echo "  FAIL: Backend service port is '$SVC_PORT', expected '8080'"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
