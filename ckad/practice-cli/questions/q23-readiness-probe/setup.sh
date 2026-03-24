#!/bin/bash
set -e
# Q23 — Readiness Probe: Setup

# Clean prior state
kubectl delete deployment api-deploy --ignore-not-found &>/dev/null || true

# Create deployment without probes
kubectl apply -f - &>/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-deploy
  template:
    metadata:
      labels:
        app: api-deploy
    spec:
      containers:
      - name: api
        image: nginx
        ports:
        - containerPort: 8080
EOF

echo "Setup complete."
