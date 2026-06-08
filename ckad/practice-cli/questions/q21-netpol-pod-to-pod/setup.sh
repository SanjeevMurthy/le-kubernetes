#!/bin/bash
set -e
# Q21 — NetworkPolicy Pod-to-Pod: Setup

# Clean prior state
kubectl delete namespace backend --ignore-not-found &>/dev/null || true
while kubectl get namespace backend &>/dev/null 2>&1; do sleep 1; done

# Create namespace
kubectl create namespace backend &>/dev/null

# Create api-pod
kubectl apply -f - &>/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: api-pod
  namespace: backend
  labels:
    app: api
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
EOF

# Create database-pod
kubectl apply -f - &>/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: database-pod
  namespace: backend
  labels:
    app: database
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 5432
EOF

echo "Setup complete."
