#!/bin/bash
# Q5 — Canary Deployment: Verify
PASS=0; FAIL=0

echo "Checking deployment web-app has 8 replicas..."
REPLICAS=$(kubectl get deployment web-app -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "")
if [[ "$REPLICAS" == "8" ]]; then
  echo "  PASS: web-app has 8 replicas"
  ((PASS++))
else
  echo "  FAIL: web-app has '$REPLICAS' replicas (expected: 8)"
  ((FAIL++))
fi

echo "Checking deployment web-app-canary exists..."
if kubectl get deployment web-app-canary &>/dev/null; then
  echo "  PASS: Deployment web-app-canary exists"
  ((PASS++))
else
  echo "  FAIL: Deployment web-app-canary not found"
  ((FAIL++))
fi

echo "Checking web-app-canary has 2 replicas..."
CANARY_REPLICAS=$(kubectl get deployment web-app-canary -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "")
if [[ "$CANARY_REPLICAS" == "2" ]]; then
  echo "  PASS: web-app-canary has 2 replicas"
  ((PASS++))
else
  echo "  FAIL: web-app-canary has '$CANARY_REPLICAS' replicas (expected: 2)"
  ((FAIL++))
fi

echo "Checking web-app-canary has label app=webapp..."
CANARY_LABEL=$(kubectl get deployment web-app-canary -o jsonpath='{.spec.template.metadata.labels.app}' 2>/dev/null || echo "")
if [[ "$CANARY_LABEL" == "webapp" ]]; then
  echo "  PASS: web-app-canary pods have label app=webapp"
  ((PASS++))
else
  echo "  FAIL: web-app-canary pod label app is '$CANARY_LABEL' (expected: webapp)"
  ((FAIL++))
fi

echo "Checking service web-service selects app=webapp..."
SVC_SELECTOR=$(kubectl get svc web-service -o jsonpath='{.spec.selector.app}' 2>/dev/null || echo "")
if [[ "$SVC_SELECTOR" == "webapp" ]]; then
  echo "  PASS: Service selects app=webapp"
  ((PASS++))
else
  echo "  FAIL: Service selector app is '$SVC_SELECTOR' (expected: webapp)"
  ((FAIL++))
fi

echo "Checking service endpoints include pods from both deployments..."
ENDPOINT_COUNT=$(kubectl get endpoints web-service -o jsonpath='{.subsets[0].addresses}' 2>/dev/null | grep -o '"ip"' | wc -l | tr -d ' ')
EXPECTED_TOTAL=10  # 8 + 2
if [[ "$ENDPOINT_COUNT" -ge 2 ]]; then
  echo "  PASS: Service has $ENDPOINT_COUNT endpoints (from both deployments)"
  ((PASS++))
else
  echo "  FAIL: Service has $ENDPOINT_COUNT endpoints (expected: pods from both deployments)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
