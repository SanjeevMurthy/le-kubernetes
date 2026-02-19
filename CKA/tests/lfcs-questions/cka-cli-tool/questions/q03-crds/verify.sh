#!/bin/bash
# Q3 — CRDs: Verify
PASS=0; FAIL=0
echo "🔍 Checking /root/resources.yaml exists..."
if [[ -f /root/resources.yaml ]]; then echo "  ✅ File exists"; ((PASS++)); else echo "  ❌ Not found"; ((FAIL++)); fi
echo "🔍 Checking /root/subject.yaml exists..."
if [[ -f /root/subject.yaml ]]; then echo "  ✅ File exists"; ((PASS++)); else echo "  ❌ Not found"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"; [[ $FAIL -eq 0 ]]
