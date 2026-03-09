#!/bin/bash
# Q4 — RBAC for Custom Resources: Verify
PASS=0; FAIL=0

echo "🔍 Checking Role 'school-admin' exists..."
if kubectl get role school-admin &>/dev/null; then
  echo "  ✅ Role 'school-admin' exists"
  ((PASS++))
else
  echo "  ❌ Role 'school-admin' not found"
  ((FAIL++))
fi

echo "🔍 Checking RoleBinding 'school-admin-binding' exists..."
if kubectl get rolebinding school-admin-binding &>/dev/null; then
  echo "  ✅ RoleBinding exists"
  ((PASS++))
else
  echo "  ❌ RoleBinding 'school-admin-binding' not found"
  ((FAIL++))
fi

echo "🔍 Checking jane can create students..."
if kubectl auth can-i create students.school.example.com --as=jane 2>/dev/null | grep -q "yes"; then
  echo "  ✅ jane can create students"
  ((PASS++))
else
  echo "  ❌ jane cannot create students"
  ((FAIL++))
fi

echo "🔍 Checking jane can delete classes..."
if kubectl auth can-i delete classes.school.example.com --as=jane 2>/dev/null | grep -q "yes"; then
  echo "  ✅ jane can delete classes"
  ((PASS++))
else
  echo "  ❌ jane cannot delete classes"
  ((FAIL++))
fi

echo "🔍 Checking jane cannot create pods (should be denied)..."
if kubectl auth can-i create pods --as=jane 2>/dev/null | grep -q "no"; then
  echo "  ✅ jane correctly cannot create pods"
  ((PASS++))
else
  echo "  ❌ jane can create pods (unexpected — Role may be too broad)"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
