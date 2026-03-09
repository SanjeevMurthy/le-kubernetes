#!/bin/bash
# Q20 — Control Plane Troubleshooting: Cleanup

if [[ -f /root/kube-apiserver.yaml.bak ]]; then
  sudo cp /root/kube-apiserver.yaml.bak /etc/kubernetes/manifests/kube-apiserver.yaml
  echo "Restored kube-apiserver manifest from backup. Waiting for API server to recover..."
  sleep 10
  for i in $(seq 1 30); do
    if kubectl get nodes &>/dev/null; then
      echo "API server is back up."
      break
    fi
    sleep 2
  done
  sudo rm -f /root/kube-apiserver.yaml.bak
else
  echo "No backup found; nothing to restore."
fi
