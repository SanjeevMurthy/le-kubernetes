#!/bin/bash
# Q3 — CRDs: Verify
PASS=0; FAIL=0

echo "🔍 Checking /root/resources.yaml exists..."
if [[ -f /root/resources.yaml ]]; then
  echo "  ✅ File exists"
  ((PASS++))
else
  echo "  ❌ /root/resources.yaml not found"
  ((FAIL++))
fi

echo "🔍 Checking /root/resources.yaml contains cert-manager CRDs..."
if grep -q "cert-manager" /root/resources.yaml 2>/dev/null; then
  echo "  ✅ Contains cert-manager CRD entries"
  ((PASS++))
else
  echo "  ❌ No cert-manager CRDs found in file"
  ((FAIL++))
fi

echo "🔍 Checking /root/subject.yaml exists..."
if [[ -f /root/subject.yaml ]]; then
  echo "  ✅ File exists"
  ((PASS++))
else
  echo "  ❌ /root/subject.yaml not found"
  ((FAIL++))
fi

echo "🔍 Checking /root/subject.yaml contains field documentation..."
if grep -qi "subject\|FIELD\|DESCRIPTION\|KIND" /root/subject.yaml 2>/dev/null; then
  echo "  ✅ Contains field documentation content"
  ((PASS++))
else
  echo "  ❌ File does not appear to contain kubectl explain output"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
