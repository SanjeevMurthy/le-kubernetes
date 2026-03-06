#!/bin/bash
# Q16 — Expose Deployment via NodePort: Verify
PASS=0; FAIL=0

echo "Checking for a NodePort service targeting frontend pods..."
# Find any service of type NodePort that selects app=frontend
SVC_NAME=""
for svc in $(kubectl get svc --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null); do
  SVC_TYPE=$(kubectl get svc "$svc" -o jsonpath='{.spec.type}' 2>/dev/null)
  SVC_SEL=$(kubectl get svc "$svc" -o jsonpath='{.spec.selector.app}' 2>/dev/null)
  if [[ "$SVC_TYPE" == "NodePort" && "$SVC_SEL" == "frontend" ]]; then
    SVC_NAME="$svc"
    break
  fi
done

if [[ -n "$SVC_NAME" ]]; then
  echo "  PASS: NodePort service '$SVC_NAME' found targeting app=frontend"
  ((PASS++))
else
  echo "  FAIL: No NodePort service found targeting app=frontend"
  ((FAIL++))
fi

echo "Checking service targets frontend pods (selector app=frontend)..."
if [[ -n "$SVC_NAME" ]]; then
  SELECTOR=$(kubectl get svc "$SVC_NAME" -o jsonpath='{.spec.selector.app}' 2>/dev/null)
  if [[ "$SELECTOR" == "frontend" ]]; then
    echo "  PASS: Service selector is app=frontend"
    ((PASS++))
  else
    echo "  FAIL: Service selector app is '$SELECTOR', expected 'frontend'"
    ((FAIL++))
  fi
else
  echo "  FAIL: No service to check selector"
  ((FAIL++))
fi

echo "Checking NodePort is 30080..."
if [[ -n "$SVC_NAME" ]]; then
  NODE_PORT=$(kubectl get svc "$SVC_NAME" -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
  if [[ "$NODE_PORT" == "30080" ]]; then
    echo "  PASS: NodePort is 30080"
    ((PASS++))
  else
    echo "  FAIL: NodePort is '$NODE_PORT', expected '30080'"
    ((FAIL++))
  fi
else
  echo "  FAIL: No service to check nodePort"
  ((FAIL++))
fi

echo "Checking service port is 80..."
if [[ -n "$SVC_NAME" ]]; then
  SVC_PORT=$(kubectl get svc "$SVC_NAME" -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
  if [[ "$SVC_PORT" == "80" ]]; then
    echo "  PASS: Service port is 80"
    ((PASS++))
  else
    echo "  FAIL: Service port is '$SVC_PORT', expected '80'"
    ((FAIL++))
  fi
else
  echo "  FAIL: No service to check port"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
