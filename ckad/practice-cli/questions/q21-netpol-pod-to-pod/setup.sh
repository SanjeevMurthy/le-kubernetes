#!/bin/bash
set -e
# Q21 — NetworkPolicy Pod-to-Pod: Setup

# Clean prior state
kubectl delete namespace app-ns --ignore-not-found &>/dev/null || true
while kubectl get namespace app-ns &>/dev/null 2>&1; do sleep 1; done

# Create namespace
kubectl create namespace app-ns &>/dev/null

# Create api-pod
kubectl apply -f - &>/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: api-pod
  namespace: app-ns
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
  namespace: app-ns
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
