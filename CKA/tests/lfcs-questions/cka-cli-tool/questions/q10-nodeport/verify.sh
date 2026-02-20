#!/bin/bash
# Q11 — NodePort: Verify
set -e
PASS=0; FAIL=0
NS="relative"

echo "🔍 Checking deployment has containerPort 80 with name 'http'..."
PORT=$(kubectl get deployment nodeport-deployment -n $NS -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}' 2>/dev/null || echo "")
PORT_NAME=$(kubectl get deployment nodeport-deployment -n $NS -o jsonpath='{.spec.template.spec.containers[0].ports[0].name}' 2>/dev/null || echo "")
if [[ "$PORT" == "80" ]] && [[ "$PORT_NAME" == "http" ]]; then
  echo "  ✅ Container port 80, name=http"
  ((PASS++))
elif [[ "$PORT" == "80" ]]; then
  echo "  ⚠️  Container port 80 configured but name='$PORT_NAME' (expected: http)"
  ((PASS++))
else
  echo "  ❌ Container port: '$PORT' (expected: 80)"
  ((FAIL++))
fi

echo "🔍 Checking service 'nodeport-service' exists with NodePort type..."
SVC_TYPE=$(kubectl get svc nodeport-service -n $NS -o jsonpath='{.spec.type}' 2>/dev/null || echo "")
if [[ "$SVC_TYPE" == "NodePort" ]]; then
  echo "  ✅ Service type: NodePort"
  ((PASS++))
else
  echo "  ❌ Service type: '$SVC_TYPE' (expected: NodePort)"
  ((FAIL++))
fi

echo "🔍 Checking NodePort is 30080..."
NP=$(kubectl get svc nodeport-service -n $NS -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "")
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
