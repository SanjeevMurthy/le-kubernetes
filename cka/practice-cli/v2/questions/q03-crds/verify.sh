#!/bin/bash
# Q3 — CRD Tasks - List, Query, Manage CRDs: Verify
PASS=0; FAIL=0

echo "Checking /root/resources.yaml exists..."
if [[ -f /root/resources.yaml ]]; then
  echo "  PASS: /root/resources.yaml exists"
  ((PASS++))
else
  echo "  FAIL: /root/resources.yaml not found"
  ((FAIL++))
fi

echo "Checking file contains cert-manager CRD definitions..."
if grep -q "cert-manager" /root/resources.yaml 2>/dev/null; then
  echo "  PASS: File contains cert-manager CRD references"
  ((PASS++))
else
  echo "  FAIL: No cert-manager CRD content found in file"
  ((FAIL++))
fi

echo "Checking file is valid YAML (contains apiVersion or CRD names)..."
if grep -qE "apiVersion|certificates\.cert-manager\.io|issuers\.cert-manager\.io" /root/resources.yaml 2>/dev/null; then
  echo "  PASS: File contains valid CRD content"
  ((PASS++))
else
  echo "  FAIL: File does not appear to contain valid CRD content"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
