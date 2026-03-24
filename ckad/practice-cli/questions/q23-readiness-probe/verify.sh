#!/bin/bash
# Q23 — Readiness Probe: Verify
PASS=0; FAIL=0

echo "Checking deployment 'api-deploy' exists..."
if kubectl get deployment api-deploy &>/dev/null; then
  echo "  PASS: Deployment api-deploy exists"
  ((PASS++))
else
  echo "  FAIL: Deployment api-deploy not found"
  ((FAIL++))
fi

echo "Checking readinessProbe is configured with httpGet..."
PROBE_PATH=$(kubectl get deployment api-deploy -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null)
PROBE_PORT=$(kubectl get deployment api-deploy -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}' 2>/dev/null)
if [[ "$PROBE_PATH" == "/ready" && "$PROBE_PORT" == "8080" ]]; then
  echo "  PASS: readinessProbe httpGet on port 8080 path /ready"
  ((PASS++))
else
  echo "  FAIL: readinessProbe httpGet is path='$PROBE_PATH' port='$PROBE_PORT', expected path='/ready' port='8080'"
  ((FAIL++))
fi

echo "Checking initialDelaySeconds is 5..."
INITIAL_DELAY=$(kubectl get deployment api-deploy -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.initialDelaySeconds}' 2>/dev/null)
if [[ "$INITIAL_DELAY" == "5" ]]; then
  echo "  PASS: initialDelaySeconds is 5"
  ((PASS++))
else
  echo "  FAIL: initialDelaySeconds is '$INITIAL_DELAY', expected '5'"
  ((FAIL++))
fi

echo "Checking periodSeconds is 10..."
PERIOD=$(kubectl get deployment api-deploy -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.periodSeconds}' 2>/dev/null)
if [[ "$PERIOD" == "10" ]]; then
  echo "  PASS: periodSeconds is 10"
  ((PASS++))
else
  echo "  FAIL: periodSeconds is '$PERIOD', expected '10'"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
