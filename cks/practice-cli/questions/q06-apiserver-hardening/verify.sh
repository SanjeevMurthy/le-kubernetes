#!/bin/bash
# Q6 apiserver hardening: the three flags must be corrected AND the API server
# must be serving with anonymous access actually refused.
source "$(dirname "$0")/../../lib/checks.sh"; source "$(dirname "$0")/../../lib/env.sh"

echo "Checking the kube-apiserver flags..."
check_file_has "--anonymous-auth=false" '--anonymous-auth=false' "$KAS_MANIFEST"
check_file_has "--authorization-mode is Node,RBAC" '--authorization-mode=(Node,RBAC|RBAC,Node)' "$KAS_MANIFEST"
check_file_has "--profiling=false" '--profiling=false' "$KAS_MANIFEST"
check_not "no AlwaysAllow authorizer left" \
  bash -c '! test -f "$1" || grep -q -- "--authorization-mode=.*AlwaysAllow" "$1"' _ "$KAS_MANIFEST"

echo "Checking the API server came back..."
check "kube-apiserver reports readyz ok" bash -c 'curl -sk --max-time 5 https://127.0.0.1:6443/readyz | grep -q ok'
check "authenticated kubectl calls still work" kubectl get --raw=/version

echo "Checking anonymous requests are refused (effect test)..."
code=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 5 https://127.0.0.1:6443/api 2>/dev/null)
if [[ "$code" == "401" || "$code" == "403" ]]; then
  echo "  PASS: anonymous GET /api refused with HTTP $code"; PASS=$((PASS + 1))
else
  echo "  FAIL: anonymous GET /api returned HTTP '$code' (expected 401 or 403)"; FAIL=$((FAIL + 1))
fi

summary
