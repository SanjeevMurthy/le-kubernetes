#!/bin/bash
set -e
# Q22 — NetworkPolicy CIDR Egress: Setup

# Clean prior state
kubectl delete namespace web --ignore-not-found &>/dev/null || true
while kubectl get namespace web &>/dev/null 2>&1; do sleep 1; done

# Create namespace
kubectl create namespace web &>/dev/null

# Create frontend pod
kubectl apply -f - &>/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: web
  labels:
    app: frontend
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
EOF

echo "Setup complete."
