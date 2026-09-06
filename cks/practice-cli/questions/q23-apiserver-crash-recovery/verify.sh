#!/bin/bash
# Q23 apiserver crash recovery: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

echo "Checking the flag on the static pod manifest..."
check_not "no --authorization-modes is left in the manifest" \
  bash -c '! test -f "$1" || grep -q -- "--authorization-modes=" "$1"' _ "$KAS_MANIFEST"
check_file_has "the flag is spelled --authorization-mode" '--authorization-mode=' "$KAS_MANIFEST"

MODE=$(grep -oE -- '--authorization-mode=[^ ]*' "$KAS_MANIFEST" 2>/dev/null | head -1 | cut -d= -f2)
check_contains "Node is still an authorization mode" Node "$MODE"
check_contains "RBAC is still an authorization mode" RBAC "$MODE"

echo "Checking the API server came back..."
check "kube-apiserver reports readyz ok" \
  bash -c 'curl -sk --max-time 5 https://127.0.0.1:6443/readyz | grep -q ok'
check "kubectl get nodes works again" kubectl get nodes

POD=$(kubectl get pods -n kube-system -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null \
  | grep '^kube-apiserver-' | head -1)
check_pod_running "static pod ${POD:-<missing>} is Running" "$POD" kube-system

summary
