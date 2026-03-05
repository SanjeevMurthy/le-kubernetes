#!/bin/bash
set -e
# Q20 — Control Plane Troubleshooting: Setup

sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak

sudo sed -i 's/:2379/:2380/g' /etc/kubernetes/manifests/kube-apiserver.yaml

sleep 5

kubectl get nodes 2>/dev/null || true
