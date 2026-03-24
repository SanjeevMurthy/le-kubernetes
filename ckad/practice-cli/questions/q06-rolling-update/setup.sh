#!/bin/bash
set -e
# Q6 — Rolling Update and Rollback: Setup

# Clean prior state
kubectl delete deployment app-v1 --ignore-not-found &>/dev/null || true

# Create Deployment app-v1 with image nginx:1.20 and record history
cat <<EOF | kubectl apply -f - &>/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-v1
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: app-v1
  template:
    metadata:
      labels:
        app: app-v1
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
EOF

# Wait for deployment rollout
kubectl rollout status deployment app-v1 --timeout=60s &>/dev/null

echo "Setup complete. Deployment app-v1 (3 replicas, nginx:1.20) created."
