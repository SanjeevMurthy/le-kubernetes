#!/bin/bash
# Q10 — NodePort: Verify
set -e
PASS=0; FAIL=0

echo "🔍 Checking deployment has containerPort 80..."
PORT=$(kubectl get deployment nodeport-deployment -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}' 2>/dev/null || echo "")
if [[ "$PORT" == "80" ]]; then
  echo "  ✅ Container port 80 configured"
  ((PASS++))
else
  echo "  ❌ Container port: '$PORT' (expected: 80)"
  ((FAIL++))
fi

echo "🔍 Checking service 'nodeport-service' exists with NodePort..."
SVC_TYPE=$(kubectl get svc nodeport-service -o jsonpath='{.spec.type}' 2>/dev/null || echo "")
if [[ "$SVC_TYPE" == "NodePort" ]]; then
  echo "  ✅ Service type: NodePort"
  ((PASS++))
else
  echo "  ❌ Service type: '$SVC_TYPE' (expected: NodePort)"
  ((FAIL++))
fi

echo "🔍 Checking NodePort is 30080..."
NP=$(kubectl get svc nodeport-service -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "")
if [[ "$NP" == "30080" ]]; then
  echo "  ✅ NodePort: 30080"
  ((PASS++))
else
  echo "  ❌ NodePort: '$NP' (expected: 30080)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
