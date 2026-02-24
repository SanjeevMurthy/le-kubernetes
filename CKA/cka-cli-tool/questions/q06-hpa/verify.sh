#!/bin/bash
# Q6 — HPA: Verify
PASS=0; FAIL=0

echo "🔍 Checking HPA 'apache-server' exists in 'autoscale' namespace..."
if kubectl get hpa apache-server -n autoscale &>/dev/null; then
  echo "  ✅ HPA exists"
  ((PASS++))
else
  echo "  ❌ HPA 'apache-server' not found in 'autoscale' namespace"
  ((FAIL++))
fi

echo "🔍 Checking HPA targets apache-deployment..."
TARGET=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.scaleTargetRef.name}' 2>/dev/null || echo "")
if [[ "$TARGET" == "apache-deployment" ]]; then
  echo "  ✅ Targets apache-deployment"
  ((PASS++))
else
  echo "  ❌ Target: '$TARGET' (expected: apache-deployment)"
  ((FAIL++))
fi

echo "🔍 Checking min/max replicas..."
MIN=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.minReplicas}' 2>/dev/null || echo "0")
MAX=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.maxReplicas}' 2>/dev/null || echo "0")
if [[ "$MIN" == "1" && "$MAX" == "4" ]]; then
  echo "  ✅ Min=1, Max=4"
  ((PASS++))
else
  echo "  ❌ Min=$MIN, Max=$MAX (expected: Min=1, Max=4)"
  ((FAIL++))
fi

echo "🔍 Checking CPU target is 50%..."
CPU=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}' 2>/dev/null || echo "0")
if [[ "$CPU" == "50" ]]; then
  echo "  ✅ CPU target: 50%"
  ((PASS++))
else
  echo "  ❌ CPU target: $CPU% (expected: 50%)"
  ((FAIL++))
fi

echo "🔍 Checking downscale stabilization window..."
STAB=$(kubectl get hpa apache-server -n autoscale -o jsonpath='{.spec.behavior.scaleDown.stabilizationWindowSeconds}' 2>/dev/null || echo "0")
if [[ "$STAB" == "30" ]]; then
  echo "  ✅ Downscale stabilization: 30s"
  ((PASS++))
else
  echo "  ❌ Stabilization: ${STAB}s (expected: 30s)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
