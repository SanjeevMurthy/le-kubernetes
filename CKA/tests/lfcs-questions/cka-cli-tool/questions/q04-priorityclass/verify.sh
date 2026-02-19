#!/bin/bash
# Q4 — PriorityClass: Verify
set -e
PASS=0; FAIL=0

echo "🔍 Checking PriorityClass 'high-priority' exists..."
if kubectl get priorityclass high-priority &>/dev/null; then
  echo "  ✅ PriorityClass exists"
  ((PASS++))
else
  echo "  ❌ PriorityClass 'high-priority' not found"
  ((FAIL++))
fi

echo "🔍 Checking PriorityClass value is one less than highest..."
HIGHEST=$(kubectl get priorityclasses -o jsonpath='{range .items[*]}{.metadata.name} {.value}{"\n"}{end}' | grep -v system- | sort -k2 -n | tail -1 | awk '{print $2}')
HP_VAL=$(kubectl get priorityclass high-priority -o jsonpath='{.value}' 2>/dev/null || echo "0")
EXPECTED=$((HIGHEST > HP_VAL ? HIGHEST : HP_VAL))
if [[ "$HP_VAL" -gt 0 ]]; then
  echo "  ✅ PriorityClass value: $HP_VAL"
  ((PASS++))
else
  echo "  ❌ PriorityClass value seems wrong: $HP_VAL"
  ((FAIL++))
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
