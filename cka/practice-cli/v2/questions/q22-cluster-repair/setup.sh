#!/bin/bash
set -e
# Q22 — General Cluster Troubleshooting - Broken Cluster Repair: Setup

sudo mkdir -p /root/cluster-repair

# Detect worker nodes (nodes without the control-plane taint/label)
WORKER_NODE=$(kubectl get nodes --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null | while read NODE; do
  IS_CP=$(kubectl get node "$NODE" -o jsonpath='{.metadata.labels.node-role\.kubernetes\.io/control-plane}' 2>/dev/null || true)
  if [[ -z "$IS_CP" ]]; then
    echo "$NODE"
    break
  fi
done)

if [[ -n "$WORKER_NODE" ]]; then
  # Multi-node cluster: stop kubelet on the worker
  echo "$WORKER_NODE" | sudo tee /root/cluster-repair/affected-node.txt >/dev/null
  ssh "$WORKER_NODE" "sudo systemctl stop kubelet" 2>/dev/null || true
  sleep 10
else
  # Single-node cluster: create simulation files
  cat <<'EOF' | sudo tee /root/cluster-repair/scenario.txt >/dev/null
Worker node node01 shows NotReady status. The kubelet service has stopped.

SSH to the node, diagnose the issue, and restore it to Ready status.

Diagnostic steps:
  1. Check node status: kubectl get nodes
  2. SSH to the affected node: ssh node01
  3. Check kubelet status: sudo systemctl status kubelet
  4. Check kubelet logs: sudo journalctl -u kubelet --no-pager -n 50
  5. Fix and restart kubelet: sudo systemctl start kubelet
  6. Verify node is Ready: kubectl get nodes
EOF

  cat <<'EOF' | sudo tee /root/cluster-repair/commands.txt >/dev/null
# Diagnostic commands:
kubectl get nodes
kubectl describe node node01
ssh node01
sudo systemctl status kubelet
sudo journalctl -u kubelet --no-pager -n 50
sudo systemctl start kubelet
sudo systemctl enable kubelet
EOF
fi
