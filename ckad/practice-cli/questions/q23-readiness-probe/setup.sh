#!/bin/bash
set -e
# Q23 — Readiness Probe: Setup

# Clean prior state
kubectl delete deployment health-app --ignore-not-found &>/dev/null || true

# Create deployment without probes
kubectl apply -f - &>/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: health-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: health-app
  template:
    metadata:
      labels:
        app: health-app
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

echo "Setup complete."
