#!/bin/bash
# Q2 kube-bench: both CIS findings must be remediated and the node still healthy.
source "$(dirname "$0")/../../lib/checks.sh"; source "$(dirname "$0")/../../lib/env.sh"
KUBELET_CONF=/var/lib/kubelet/config.yaml

echo "Checking CIS 1.2.1 — apiserver anonymous auth..."
check_file_has "kube-apiserver has --anonymous-auth=false" '--anonymous-auth=false' "$KAS_MANIFEST"
check_not "no --anonymous-auth=true left in the manifest" \
  bash -c '! test -f "$1" || grep -q -- "--anonymous-auth=true" "$1"' _ "$KAS_MANIFEST"

echo "Checking CIS 4.2.4 — kubelet read-only port..."
check_file_has "kubelet config has readOnlyPort: 0" '^readOnlyPort:[[:space:]]*0[[:space:]]*$' "$KUBELET_CONF"

echo "Checking the node is still healthy..."
check "kube-apiserver reports readyz ok" bash -c 'curl -sk --max-time 5 https://127.0.0.1:6443/readyz | grep -q ok'
check "kubelet service is active" systemctl is-active --quiet kubelet

echo "Checking the read-only port is really closed (effect test)..."
check_not "http://127.0.0.1:10255/pods no longer answers" bash -c 'curl -s --max-time 3 http://127.0.0.1:10255/pods'

echo "Re-running kube-bench for check 4.2.4 (effect test)..."
check "kube-bench run --targets node --check 4.2.4 reports PASS" \
  bash -c "kube-bench run --targets node --check 4.2.4 2>/dev/null | grep -q '\[PASS\]'"

summary
