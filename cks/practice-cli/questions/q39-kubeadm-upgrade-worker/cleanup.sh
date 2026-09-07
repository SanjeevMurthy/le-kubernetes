#!/bin/bash
# Q39 kubeadm patch upgrade: the upgrade itself is not undone. Downgrading a
# kubelet is riskier than the question is worth, so cleanup only makes sure the
# node is schedulable again and drops the recorded target.
source "$(dirname "$0")/../../lib/env.sh"
W=$(worker_node)
if [[ -n "$W" ]]; then
  kubectl uncordon "$W" >/dev/null 2>&1
fi
rm -f "$CKS_STATE_DIR/q39.target" "$CKS_STATE_DIR/q39.package"
echo "Cleanup complete. The kubelet keeps whatever version it now runs;"
echo "a cleanup should not downgrade a node."
