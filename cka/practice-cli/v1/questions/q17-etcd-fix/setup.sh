#!/bin/bash
# Q18 — Fix kube-apiserver After Cluster Migration (etcd Port Fix): Setup
set -e

echo "Backing up kube-apiserver manifest..."
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak

echo "Simulating migration issue — changing etcd client port from 2379 to 2380..."
sudo sed -i 's/:2379/:2380/g' /etc/kubernetes/manifests/kube-apiserver.yaml

echo "Waiting for kube-apiserver to detect the change..."
sleep 5

echo ""
echo "Checking kube-apiserver container status..."
KAPISERVER_ID=$(sudo crictl ps -a 2>/dev/null | grep kube-apiserver | awk '{print $1}' | head -n 1)
if [ -n "$KAPISERVER_ID" ]; then
  sudo crictl logs "$KAPISERVER_ID" 2>&1 | tail -n 5 || true
else
  echo "kube-apiserver container not found yet"
fi

echo ""
kubectl get nodes 2>/dev/null || echo "As expected, API server is down due to misconfigured etcd port."
echo ""
echo "Your task:"
echo "  Diagnose and fix the kube-apiserver to restore cluster access"
