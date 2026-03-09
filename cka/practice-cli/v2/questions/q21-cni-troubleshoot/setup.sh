#!/bin/bash
set -e
# Q21 — CNI / Networking Troubleshooting: Setup

kubectl create namespace cni-debug --dry-run=client -o yaml | kubectl apply -f - &>/dev/null

cat <<EOF | kubectl apply -f - &>/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cni-test-app
  namespace: cni-debug
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cni-test
  template:
    metadata:
      labels:
        app: cni-test
    spec:
      containers:
      - name: nginx
        image: nginx:stable
        ports:
        - containerPort: 80
EOF

sudo mkdir -p /root/cni-troubleshoot

cat <<'EOF' | sudo tee /root/cni-troubleshoot/scenario.txt >/dev/null
A cluster was initialized with kubeadm using --pod-network-cidr=10.244.0.0/16
but Calico was installed with CIDR 192.168.0.0/16.
Pods are stuck in ContainerCreating due to the CIDR mismatch.

Diagnose and fix the CIDR mismatch so the pod network CIDR in
calico-custom-resources.yaml matches the cluster pod CIDR (10.244.0.0/16).

Steps:
  1. Check the cluster pod CIDR:
       kubectl cluster-info dump | grep -m1 cluster-cidr
       OR: cat /etc/kubernetes/manifests/kube-controller-manager.yaml | grep cluster-cidr
  2. Compare with the Calico CIDR in /root/cni-troubleshoot/calico-custom-resources.yaml
  3. Fix the CIDR in calico-custom-resources.yaml to match the cluster pod CIDR
  4. Ensure pods in the cni-debug namespace are Running
EOF

cat <<'EOF' | sudo tee /root/cni-troubleshoot/calico-custom-resources.yaml >/dev/null
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: 192.168.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
---
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
EOF

echo "10.244.0.0/16" | sudo tee /root/cni-troubleshoot/expected-cidr.txt >/dev/null
