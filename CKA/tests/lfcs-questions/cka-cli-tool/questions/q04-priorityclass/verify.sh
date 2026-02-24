#!/bin/bash
# Q5 — PriorityClass: Verify
PASS=0; FAIL=0

echo "🔍 Checking PriorityClass 'high-priority' exists..."
if kubectl get priorityclass high-priority &>/dev/null; then
  echo "  ✅ PriorityClass exists"
  ((PASS++))
else
  echo "  ❌ PriorityClass 'high-priority' not found"
  ((FAIL++))
fi

echo "🔍 Checking PriorityClass value is one less than highest user-defined..."
# Get the highest user-defined PC value (exclude system-* and high-priority itself)
HIGHEST=$(kubectl get priorityclasses -o jsonpath='{range .items[*]}{.metadata.name} {.value}{"\n"}{end}' \
  | grep -v "^system-" | grep -v "^high-priority " | sort -k2 -n | tail -1 | awk '{print $2}')
HP_VAL=$(kubectl get priorityclass high-priority -o jsonpath='{.value}' 2>/dev/null || echo "0")

if [[ -n "$HIGHEST" ]] && [[ "$HIGHEST" -gt 0 ]]; then
  EXPECTED=$((HIGHEST - 1))
  if [[ "$HP_VAL" == "$EXPECTED" ]]; then
    echo "  ✅ PriorityClass value: $HP_VAL (= $HIGHEST - 1)"
    ((PASS++))
  else
    echo "  ❌ PriorityClass value: $HP_VAL (expected: $EXPECTED = highest($HIGHEST) - 1)"
    ((FAIL++))
  fi
else
  # Fallback: just check it has a positive value
  if [[ "$HP_VAL" -gt 0 ]]; then
    echo "  ✅ PriorityClass value: $HP_VAL (could not determine highest — accepting positive value)"
    ((PASS++))
  else
    echo "  ❌ PriorityClass value: $HP_VAL (expected positive value)"
    ((FAIL++))
  fi
fi

echo "🔍 Checking deployment uses high-priority..."
PC=$(kubectl get deployment busybox-logger -n priority -o jsonpath='{.spec.template.spec.priorityClassName}' 2>/dev/null || echo "")
if [[ "$PC" == "high-priority" ]]; then
  echo "  ✅ Deployment uses high-priority"
  ((PASS++))
else
  echo "  ❌ Deployment priority class: '$PC' (expected: high-priority)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
