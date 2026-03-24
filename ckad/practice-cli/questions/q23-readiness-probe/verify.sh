#!/bin/bash
# Q23 — Readiness Probe: Verify
PASS=0; FAIL=0

echo "Checking deployment 'health-app' exists..."
if kubectl get deployment health-app &>/dev/null; then
  echo "  PASS: Deployment health-app exists"
  ((PASS++))
else
  echo "  FAIL: Deployment health-app not found"
  ((FAIL++))
fi

echo "Checking readinessProbe is configured with httpGet..."
PROBE_PATH=$(kubectl get deployment health-app -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null)
PROBE_PORT=$(kubectl get deployment health-app -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}' 2>/dev/null)
if [[ "$PROBE_PATH" == "/" && "$PROBE_PORT" == "80" ]]; then
  echo "  PASS: readinessProbe httpGet on port 80 path /"
  ((PASS++))
else
  echo "  FAIL: readinessProbe httpGet is path='$PROBE_PATH' port='$PROBE_PORT', expected path='/' port='80'"
  ((FAIL++))
fi

echo "Checking initialDelaySeconds is 5..."
INITIAL_DELAY=$(kubectl get deployment health-app -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.initialDelaySeconds}' 2>/dev/null)
if [[ "$INITIAL_DELAY" == "5" ]]; then
  echo "  PASS: initialDelaySeconds is 5"
  ((PASS++))
else
  echo "  FAIL: initialDelaySeconds is '$INITIAL_DELAY', expected '5'"
  ((FAIL++))
fi

echo "Checking periodSeconds is 10..."
PERIOD=$(kubectl get deployment health-app -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.periodSeconds}' 2>/dev/null)
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
