#!/bin/bash
# Q21 — NetworkPolicy Pod-to-Pod: Verify
PASS=0; FAIL=0

echo "Checking a NetworkPolicy exists in app-ns namespace..."
NETPOL_COUNT=$(kubectl get networkpolicy -n app-ns --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [[ "$NETPOL_COUNT" -ge 1 ]]; then
  echo "  PASS: NetworkPolicy found in app-ns"
  ((PASS++))
else
  echo "  FAIL: No NetworkPolicy found in app-ns namespace"
  ((FAIL++))
fi

# Get the first NetworkPolicy name
NETPOL_NAME=$(kubectl get networkpolicy -n app-ns --no-headers -o custom-columns=':metadata.name' 2>/dev/null | head -1 | tr -d ' ')

echo "Checking NetworkPolicy targets pods with app=database..."
POD_SEL=$(kubectl get networkpolicy "$NETPOL_NAME" -n app-ns -o jsonpath='{.spec.podSelector.matchLabels.app}' 2>/dev/null)
if [[ "$POD_SEL" == "database" ]]; then
  echo "  PASS: podSelector targets app=database"
  ((PASS++))
else
  echo "  FAIL: podSelector app is '$POD_SEL', expected 'database'"
  ((FAIL++))
fi

echo "Checking ingress allows from pods with app=api..."
API_MATCH=$(kubectl get networkpolicy "$NETPOL_NAME" -n app-ns \
  -o jsonpath='{.spec.ingress[*].from[*].podSelector.matchLabels.app}' 2>/dev/null || true)
if echo "$API_MATCH" | grep -q "api"; then
  echo "  PASS: Ingress allows from podSelector app=api"
  ((PASS++))
else
  echo "  FAIL: Ingress does not allow from podSelector app=api (got '$API_MATCH')"
  ((FAIL++))
fi

echo "Checking ingress allows on port 5432..."
PORT_MATCH=$(kubectl get networkpolicy "$NETPOL_NAME" -n app-ns \
  -o jsonpath='{.spec.ingress[*].ports[*].port}' 2>/dev/null || true)
if echo "$PORT_MATCH" | grep -q "5432"; then
  echo "  PASS: Port 5432 is specified in ingress rules"
  ((PASS++))
else
  echo "  FAIL: Port 5432 not found in ingress rules (got '$PORT_MATCH')"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
