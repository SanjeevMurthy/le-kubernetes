#!/bin/bash
# Q17 — Network Policy Configuration: Verify
PASS=0; FAIL=0

echo "Checking NetworkPolicy 'allow-frontend' exists in production namespace..."
if kubectl get networkpolicy allow-frontend -n production &>/dev/null; then
  echo "  PASS: NetworkPolicy allow-frontend exists"
  ((PASS++))
else
  echo "  FAIL: NetworkPolicy allow-frontend not found in production namespace"
  ((FAIL++))
fi

echo "Checking podSelector selects role=frontend..."
POD_SEL=$(kubectl get networkpolicy allow-frontend -n production -o jsonpath='{.spec.podSelector.matchLabels.role}' 2>/dev/null)
if [[ "$POD_SEL" == "frontend" ]]; then
  echo "  PASS: podSelector selects role=frontend"
  ((PASS++))
else
  echo "  FAIL: podSelector role is '$POD_SEL', expected 'frontend'"
  ((FAIL++))
fi

echo "Checking NetworkPolicy has ingress rules..."
INGRESS_RULES=$(kubectl get networkpolicy allow-frontend -n production -o jsonpath='{.spec.ingress}' 2>/dev/null)
if [[ -n "$INGRESS_RULES" && "$INGRESS_RULES" != "[]" ]]; then
  echo "  PASS: NetworkPolicy has ingress rules"
  ((PASS++))
else
  echo "  FAIL: NetworkPolicy has no ingress rules"
  ((FAIL++))
fi

echo "Checking ingress allows from podSelector role=backend..."
INGRESS_JSON=$(kubectl get networkpolicy allow-frontend -n production -o json 2>/dev/null)
BACKEND_MATCH=$(echo "$INGRESS_JSON" | grep -o '"role":"backend"' || true)
if [[ -n "$BACKEND_MATCH" ]]; then
  echo "  PASS: Ingress allows from podSelector role=backend"
  ((PASS++))
else
  echo "  FAIL: Ingress does not allow from podSelector role=backend"
  ((FAIL++))
fi

echo "Checking ingress allows from namespaceSelector monitoring..."
NS_MATCH=$(echo "$INGRESS_JSON" | grep -o '"kubernetes.io/metadata.name":"monitoring"' || true)
if [[ -n "$NS_MATCH" ]]; then
  echo "  PASS: Ingress allows from namespaceSelector monitoring"
  ((PASS++))
else
  echo "  FAIL: Ingress does not allow from namespaceSelector for monitoring namespace"
  ((FAIL++))
fi

echo "Checking port 80 is specified..."
PORT_MATCH=$(echo "$INGRESS_JSON" | grep -o '"port":80' || true)
if [[ -n "$PORT_MATCH" ]]; then
  echo "  PASS: Port 80 is specified in ingress rules"
  ((PASS++))
else
  echo "  FAIL: Port 80 not found in ingress rules"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
