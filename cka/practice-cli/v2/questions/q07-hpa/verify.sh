#!/bin/bash
# Q7 — Create HPA: Verify
PASS=0; FAIL=0

echo "Checking HPA exists targeting web-app..."
if kubectl get hpa web-app -n default &>/dev/null; then
  echo "  PASS: HPA exists"
  ((PASS++))
else
  echo "  FAIL: HPA not found in default namespace"
  ((FAIL++))
fi

echo "Checking HPA targets web-app deployment..."
TARGET=$(kubectl get hpa web-app -n default -o jsonpath='{.spec.scaleTargetRef.name}' 2>/dev/null || echo "")
if [[ "$TARGET" == "web-app" ]]; then
  echo "  PASS: HPA targets web-app"
  ((PASS++))
else
  echo "  FAIL: HPA target is '$TARGET' (expected: web-app)"
  ((FAIL++))
fi

echo "Checking min replicas = 1, max replicas = 4..."
MIN=$(kubectl get hpa web-app -n default -o jsonpath='{.spec.minReplicas}' 2>/dev/null || echo "0")
MAX=$(kubectl get hpa web-app -n default -o jsonpath='{.spec.maxReplicas}' 2>/dev/null || echo "0")
if [[ "$MIN" == "1" && "$MAX" == "4" ]]; then
  echo "  PASS: Min=1, Max=4"
  ((PASS++))
else
  echo "  FAIL: Min=$MIN, Max=$MAX (expected: Min=1, Max=4)"
  ((FAIL++))
fi

echo "Checking CPU target is 50%..."
CPU=$(kubectl get hpa web-app -n default -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}' 2>/dev/null || echo "0")
if [[ "$CPU" == "50" ]]; then
  echo "  PASS: CPU target is 50%"
  ((PASS++))
else
  echo "  FAIL: CPU target is $CPU% (expected: 50%)"
  ((FAIL++))
fi

echo "Checking web-app deployment has resource requests..."
CPU_REQ=$(kubectl get deployment web-app -n default -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null || echo "")
if [[ -n "$CPU_REQ" ]]; then
  echo "  PASS: Deployment has CPU request ($CPU_REQ)"
  ((PASS++))
else
  echo "  FAIL: Deployment has no CPU resource request"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
