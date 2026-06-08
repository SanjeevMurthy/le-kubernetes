#!/bin/bash
# Q4 — Verify (graded on effective permissions)
PASS=0; FAIL=0
SA=system:serviceaccount:build:ci

chk() { # desc expected verb res
  local d="$1" exp="$2" verb="$3" res="$4"
  local got; got=$(kubectl auth can-i "$verb" "$res" --as="$SA" -n build 2>/dev/null)
  if [[ "$got" == "$exp" ]]; then echo "  PASS: $d ($got)"; ((PASS++)); else echo "  FAIL: $d expected $exp got '$got'"; ((FAIL++)); fi
}

echo "Checking effective RBAC for build:ci..."
chk "can list pods"        yes list   pods
chk "can get pods/log"     yes get    pods/log
chk "cannot delete pods"   no  delete pods
chk "cannot get secrets"   no  get    secrets
chk "is NOT cluster-admin" no  '*'    '*'

echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
