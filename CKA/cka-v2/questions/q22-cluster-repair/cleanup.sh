#!/bin/bash
# Q22 — General Cluster Troubleshooting - Broken Cluster Repair: Cleanup

# If a worker node's kubelet was stopped, restart it
if [[ -f /root/cluster-repair/affected-node.txt ]]; then
  WORKER_NODE=$(cat /root/cluster-repair/affected-node.txt)
  echo "Restarting kubelet on $WORKER_NODE..."
  ssh "$WORKER_NODE" "sudo systemctl start kubelet && sudo systemctl enable kubelet" 2>/dev/null || true
  echo "Waiting for node to become Ready..."
  for i in $(seq 1 30); do
    STATUS=$(kubectl get node "$WORKER_NODE" --no-headers 2>/dev/null | awk '{print $2}')
    if [[ "$STATUS" == "Ready" ]]; then
      echo "Node $WORKER_NODE is Ready."
      break
    fi
    sleep 2
  done
fi

sudo rm -rf /root/cluster-repair
echo "Cleaned up /root/cluster-repair."
