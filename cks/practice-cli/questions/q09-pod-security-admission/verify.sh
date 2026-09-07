#!/bin/bash
# Q9 Pod Security Admission: verify.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

NS=payments

echo "Checking the namespace labels..."
check_eq "pod-security.kubernetes.io/enforce is restricted" "restricted" \
  "$(kjp namespace "$NS" "" '{.metadata.labels.pod-security\.kubernetes\.io/enforce}')"

echo "Checking admission is actually live (control, then the real test)..."
# Control: a compliant pod must be admitted. Without it, a missing namespace or a
# broken API server would make the privileged pod "fail to create" and the check
# below would report a false PASS.
kubectl delete pod psa-ok psa-test -n "$NS" --ignore-not-found >/dev/null 2>&1
OK=$(kubectl run psa-ok --image=nginx --restart=Never -n "$NS" --dry-run=server \
  --overrides='{"spec":{"containers":[{"name":"psa-ok","image":"nginx","securityContext":{"runAsNonRoot":true,"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"seccompProfile":{"type":"RuntimeDefault"}}}]}}' 2>&1)
if [[ $? -eq 0 ]]; then
  echo "  PASS: a compliant pod is still admitted"
  PASS=$((PASS + 1))
else
  echo "  FAIL: even a compliant pod was refused, so this namespace cannot be graded"
  echo "        $(echo "$OK" | head -1)"
  FAIL=$((FAIL + 1))
fi

OUT=$(kubectl run psa-test --image=nginx --restart=Never -n "$NS" --dry-run=server \
  --overrides='{"spec":{"containers":[{"name":"psa-test","image":"nginx","securityContext":{"privileged":true}}]}}' 2>&1)
if [[ $? -eq 0 ]]; then
  echo "  FAIL: a privileged pod was admitted, so restricted is not being enforced"
  FAIL=$((FAIL + 1))
elif echo "$OUT" | grep -qiE 'forbidden|violat|privileged'; then
  echo "  PASS: the privileged pod was rejected by Pod Security Admission"
  PASS=$((PASS + 1))
else
  echo "  FAIL: the pod was refused, but not by Pod Security Admission:"
  echo "        $(echo "$OUT" | head -1)"
  FAIL=$((FAIL + 1))
fi

kubectl delete pod psa-ok psa-test -n "$NS" --ignore-not-found >/dev/null 2>&1
summary
