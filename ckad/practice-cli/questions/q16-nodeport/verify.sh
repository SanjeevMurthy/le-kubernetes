#!/bin/bash
# Q16 — Create NodePort Service: Verify
PASS=0; FAIL=0

echo "Checking for a NodePort service targeting app=api..."
SVC_NAME=""
for svc in $(kubectl get svc --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null); do
  SVC_TYPE=$(kubectl get svc "$svc" -o jsonpath='{.spec.type}' 2>/dev/null)
  SVC_SEL=$(kubectl get svc "$svc" -o jsonpath='{.spec.selector.app}' 2>/dev/null)
  if [[ "$SVC_TYPE" == "NodePort" && "$SVC_SEL" == "api" ]]; then
    SVC_NAME="$svc"
    break
  fi
done

if [[ -n "$SVC_NAME" ]]; then
  echo "  PASS: NodePort service '$SVC_NAME' found targeting app=api"
  ((PASS++))
else
  echo "  FAIL: No NodePort service found targeting app=api"
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

echo "Checking service targetPort is 9090..."
if [[ -n "$SVC_NAME" ]]; then
  TGT_PORT=$(kubectl get svc "$SVC_NAME" -o jsonpath='{.spec.ports[0].targetPort}' 2>/dev/null)
  if [[ "$TGT_PORT" == "9090" ]]; then
    echo "  PASS: Service targetPort is 9090"
    ((PASS++))
  else
    echo "  FAIL: Service targetPort is '$TGT_PORT', expected '9090'"
    ((FAIL++))
  fi
else
  echo "  FAIL: No service to check targetPort"
  ((FAIL++))
fi

echo "Checking /root/nodeport-output.txt exists..."
if [[ -f /root/nodeport-output.txt ]]; then
  echo "  PASS: /root/nodeport-output.txt exists"
  ((PASS++))
else
  echo "  FAIL: /root/nodeport-output.txt not found"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
