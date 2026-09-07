#!/bin/bash
# Q39 kubeadm patch upgrade: verify. The graded facts are the two package
# versions on the worker, and that the node came back into service afterwards.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

TARGET_FILE="$CKS_STATE_DIR/q39.target"

if [[ ! -f "$TARGET_FILE" ]]; then
  echo "  FAIL: no target version recorded. Run setup first."
  echo ""
  echo "Results: 0 passed, 1 failed"
  exit 1
fi

TARGET=$(tr -d ' \r\n' < "$TARGET_FILE")
W=$(worker_node)

OUT=$(on_worker bash -s <<'REMOTE'
echo "KUBELET=$(kubelet --version 2>/dev/null | awk '{print $2}' | tr -d 'v')"
KV=$(kubectl version --client -o yaml 2>/dev/null | grep -m1 'gitVersion' | awk '{print $2}')
[ -n "$KV" ] || KV=$(kubectl version --client --short 2>/dev/null | awk '{print $NF}')
echo "KUBECTL=$(echo "$KV" | tr -d 'v')"
REMOTE
) || true

field() { printf '%s\n' "$OUT" | grep -m1 "^$1=" | cut -d= -f2-; }

echo "Checking the packages on ${W:-the worker} (target $TARGET)..."
check_eq "kubelet on the worker is at $TARGET" "$TARGET" "$(field KUBELET)"
check_eq "kubectl on the worker is at $TARGET" "$TARGET" "$(field KUBECTL)"

echo "Checking the node came back into service..."
check_eq "the API server sees the node at v$TARGET" "v$TARGET" \
  "$(kjp node "$W" "" '{.status.nodeInfo.kubeletVersion}')"
check_eq "node $W is Ready" "True" \
  "$(kjp node "$W" "" '{.status.conditions[?(@.type=="Ready")].status}')"
check_eq "node $W is schedulable again (not cordoned)" "" \
  "$(kjp node "$W" "" '{.spec.unschedulable}')"

summary
