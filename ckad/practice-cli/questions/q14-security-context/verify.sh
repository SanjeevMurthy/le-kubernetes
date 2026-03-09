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

echo "Checking pod securityContext runAsGroup=3000..."
RUN_AS_GROUP=$(kubectl get pod "$POD" -o jsonpath='{.spec.securityContext.runAsGroup}' 2>/dev/null)
if [[ "$RUN_AS_GROUP" == "3000" ]]; then
  echo "  PASS: runAsGroup is 3000"
  ((PASS++))
else
  echo "  FAIL: runAsGroup is '$RUN_AS_GROUP', expected '3000'"
  ((FAIL++))
fi

echo "Checking pod securityContext fsGroup=2000..."
FS_GROUP=$(kubectl get pod "$POD" -o jsonpath='{.spec.securityContext.fsGroup}' 2>/dev/null)
if [[ "$FS_GROUP" == "2000" ]]; then
  echo "  PASS: fsGroup is 2000"
  ((PASS++))
else
  echo "  FAIL: fsGroup is '$FS_GROUP', expected '2000'"
  ((FAIL++))
fi

echo "Checking container capabilities add NET_BIND_SERVICE..."
CAP_ADD=$(kubectl get pod "$POD" -o jsonpath='{.spec.containers[0].securityContext.capabilities.add[*]}' 2>/dev/null)
if [[ "$CAP_ADD" == *"NET_BIND_SERVICE"* ]]; then
  echo "  PASS: Capability NET_BIND_SERVICE is added"
  ((PASS++))
else
  echo "  FAIL: Capabilities add is '$CAP_ADD', expected 'NET_BIND_SERVICE'"
  ((FAIL++))
fi

echo "Checking container capabilities drop ALL..."
CAP_DROP=$(kubectl get pod "$POD" -o jsonpath='{.spec.containers[0].securityContext.capabilities.drop[*]}' 2>/dev/null)
if [[ "$CAP_DROP" == *"ALL"* ]]; then
  echo "  PASS: Capability ALL is dropped"
  ((PASS++))
else
  echo "  FAIL: Capabilities drop is '$CAP_DROP', expected 'ALL'"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
