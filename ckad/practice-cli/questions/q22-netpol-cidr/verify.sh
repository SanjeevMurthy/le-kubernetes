#!/bin/bash
# Q22 — NetworkPolicy CIDR Egress: Verify
PASS=0; FAIL=0

echo "Checking a NetworkPolicy exists in cidr-ns namespace..."
NETPOL_COUNT=$(kubectl get networkpolicy -n cidr-ns --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [[ "$NETPOL_COUNT" -ge 1 ]]; then
  echo "  PASS: NetworkPolicy found in cidr-ns"
  ((PASS++))
else
  echo "  FAIL: No NetworkPolicy found in cidr-ns namespace"
  ((FAIL++))
fi

# Get the first NetworkPolicy name
NETPOL_NAME=$(kubectl get networkpolicy -n cidr-ns --no-headers -o custom-columns=':metadata.name' 2>/dev/null | head -1 | tr -d ' ')
NETPOL_JSON=$(kubectl get networkpolicy "$NETPOL_NAME" -n cidr-ns -o json 2>/dev/null)

echo "Checking NetworkPolicy has egress rule with ipBlock.cidr..."
CIDR_MATCH=$(kubectl get networkpolicy "$NETPOL_NAME" -n cidr-ns \
  -o jsonpath='{.spec.egress[*].to[*].ipBlock.cidr}' 2>/dev/null || true)
if [[ -n "$CIDR_MATCH" ]]; then
  echo "  PASS: Egress rule with ipBlock.cidr found ($CIDR_MATCH)"
  ((PASS++))
else
  echo "  FAIL: No ipBlock.cidr found in NetworkPolicy"
  ((FAIL++))
fi

echo "Checking NetworkPolicy has ipBlock.except list..."
EXCEPT_MATCH=$(kubectl get networkpolicy "$NETPOL_NAME" -n cidr-ns \
  -o jsonpath='{.spec.egress[*].to[*].ipBlock.except}' 2>/dev/null || true)
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
