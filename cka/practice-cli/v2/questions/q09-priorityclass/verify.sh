#!/bin/bash
# Q9 — PriorityClass Creation and Assignment: Verify
PASS=0; FAIL=0

echo "Checking PriorityClass 'high-priority' exists..."
if kubectl get priorityclass high-priority &>/dev/null; then
  echo "  PASS: PriorityClass high-priority exists"
  ((PASS++))
else
  echo "  FAIL: PriorityClass high-priority not found"
  ((FAIL++))
fi

echo "Checking PriorityClass value is 1000000..."
VALUE=$(kubectl get priorityclass high-priority -o jsonpath='{.value}' 2>/dev/null || echo "0")
if [[ "$VALUE" == "1000000" ]]; then
  echo "  PASS: Value is 1000000"
  ((PASS++))
else
  echo "  FAIL: Value is $VALUE (expected: 1000000)"
  ((FAIL++))
fi

echo "Checking globalDefault is false..."
GLOBAL=$(kubectl get priorityclass high-priority -o jsonpath='{.globalDefault}' 2>/dev/null || echo "")
if [[ "$GLOBAL" == "false" || -z "$GLOBAL" ]]; then
  echo "  PASS: globalDefault is false"
  ((PASS++))
else
  echo "  FAIL: globalDefault is $GLOBAL (expected: false)"
  ((FAIL++))
fi

echo "Checking deployment critical-app uses priorityClassName: high-priority..."
PC=$(kubectl get deployment critical-app -n production -o jsonpath='{.spec.template.spec.priorityClassName}' 2>/dev/null || echo "")
if [[ "$PC" == "high-priority" ]]; then
  echo "  PASS: Deployment uses priorityClassName high-priority"
  ((PASS++))
else
  echo "  FAIL: priorityClassName is '$PC' (expected: high-priority)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
