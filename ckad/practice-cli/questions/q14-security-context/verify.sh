#!/bin/bash
# Q14 — Security Context Configuration: Verify
PASS=0; FAIL=0

echo "Checking Deployment secure-app exists..."
if kubectl get deployment secure-app &>/dev/null; then
  echo "  PASS: Deployment secure-app exists"
  ((PASS++))
else
  echo "  FAIL: Deployment secure-app not found"
  ((FAIL++))
fi

# Get the pod name from the deployment
POD=$(kubectl get pods -l app=secure-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [[ -z "$POD" ]]; then
  POD=$(kubectl get pods --selector="$(kubectl get deployment secure-app -o jsonpath='{.spec.selector.matchLabels}' 2>/dev/null | tr -d '{}' | sed 's/:/=/g; s/"//g')" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
fi

echo "Checking pod securityContext runAsUser=1000..."
RUN_AS_USER=$(kubectl get pod "$POD" -o jsonpath='{.spec.securityContext.runAsUser}' 2>/dev/null)
if [[ "$RUN_AS_USER" == "1000" ]]; then
  echo "  PASS: runAsUser is 1000"
  ((PASS++))
else
  echo "  FAIL: runAsUser is '$RUN_AS_USER', expected '1000'"
  ((FAIL++))
fi

echo "Checking container capabilities add NET_ADMIN..."
CAP_ADD=$(kubectl get pod "$POD" -o jsonpath='{.spec.containers[0].securityContext.capabilities.add[*]}' 2>/dev/null)
if [[ "$CAP_ADD" == *"NET_ADMIN"* ]]; then
  echo "  PASS: Capability NET_ADMIN is added"
  ((PASS++))
else
  echo "  FAIL: Capabilities add is '$CAP_ADD', expected 'NET_ADMIN'"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
