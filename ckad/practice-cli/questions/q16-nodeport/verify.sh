#!/bin/bash
# Q16 — Create NodePort Service: Verify
PASS=0; FAIL=0

echo "Checking for a NodePort service targeting app=api-server..."
SVC_NAME=""
for svc in $(kubectl get svc --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null); do
  SVC_TYPE=$(kubectl get svc "$svc" -o jsonpath='{.spec.type}' 2>/dev/null)
  SVC_SEL=$(kubectl get svc "$svc" -o jsonpath='{.spec.selector.app}' 2>/dev/null)
  if [[ "$SVC_TYPE" == "NodePort" && "$SVC_SEL" == "api-server" ]]; then
    SVC_NAME="$svc"
    break
  fi
done

if [[ -n "$SVC_NAME" ]]; then
  echo "  PASS: NodePort service '$SVC_NAME' found targeting app=api-server"
  ((PASS++))
else
  echo "  FAIL: No NodePort service found targeting app=api-server"
  ((FAIL++))
fi

echo "Checking service type is NodePort..."
if [[ -n "$SVC_NAME" ]]; then
  SVC_TYPE=$(kubectl get svc "$SVC_NAME" -o jsonpath='{.spec.type}' 2>/dev/null)
  if [[ "$SVC_TYPE" == "NodePort" ]]; then
    echo "  PASS: Service type is NodePort"
    ((PASS++))
  else
    echo "  FAIL: Service type is '$SVC_TYPE', expected 'NodePort'"
    ((FAIL++))
  fi
else
  echo "  FAIL: No service to check type"
  ((FAIL++))
fi

echo "Checking service port is 9090..."
if [[ -n "$SVC_NAME" ]]; then
  SVC_PORT=$(kubectl get svc "$SVC_NAME" -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
  if [[ "$SVC_PORT" == "9090" ]]; then
    echo "  PASS: Service port is 9090"
    ((PASS++))
  else
    echo "  FAIL: Service port is '$SVC_PORT', expected '9090'"
    ((FAIL++))
  fi
else
  echo "  FAIL: No service to check port"
  ((FAIL++))
fi

echo "Checking NodePort is 30090..."
if [[ -n "$SVC_NAME" ]]; then
  NODE_PORT=$(kubectl get svc "$SVC_NAME" -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
  if [[ "$NODE_PORT" == "30090" ]]; then
    echo "  PASS: NodePort is 30090"
    ((PASS++))
  else
    echo "  FAIL: NodePort is '$NODE_PORT', expected '30090'"
    ((FAIL++))
  fi
else
  echo "  FAIL: No service to check nodePort"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
