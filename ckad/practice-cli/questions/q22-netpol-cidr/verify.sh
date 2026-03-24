#!/bin/bash
# Q22 — NetworkPolicy CIDR Ingress: Verify
PASS=0; FAIL=0

echo "Checking a NetworkPolicy exists in web namespace..."
NETPOL_COUNT=$(kubectl get networkpolicy -n web --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [[ "$NETPOL_COUNT" -ge 1 ]]; then
  echo "  PASS: NetworkPolicy found in web"
  ((PASS++))
else
  echo "  FAIL: No NetworkPolicy found in web namespace"
  ((FAIL++))
fi

# Get the first NetworkPolicy name
NETPOL_NAME=$(kubectl get networkpolicy -n web --no-headers -o custom-columns=':metadata.name' 2>/dev/null | head -1 | tr -d ' ')

echo "Checking NetworkPolicy has ingress rule with ipBlock.cidr..."
CIDR_MATCH=$(kubectl get networkpolicy "$NETPOL_NAME" -n web \
  -o jsonpath='{.spec.ingress[*].from[*].ipBlock.cidr}' 2>/dev/null || true)
if [[ -n "$CIDR_MATCH" ]]; then
  echo "  PASS: Ingress rule with ipBlock.cidr found ($CIDR_MATCH)"
  ((PASS++))
else
  echo "  FAIL: No ipBlock.cidr found in NetworkPolicy ingress rules"
  ((FAIL++))
fi

echo "Checking NetworkPolicy has ipBlock.except list..."
EXCEPT_MATCH=$(kubectl get networkpolicy "$NETPOL_NAME" -n web \
  -o jsonpath='{.spec.ingress[*].from[*].ipBlock.except}' 2>/dev/null || true)
if [[ -n "$EXCEPT_MATCH" ]]; then
  echo "  PASS: ipBlock.except list found"
  ((PASS++))
else
  echo "  FAIL: No ipBlock.except list found in NetworkPolicy"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
