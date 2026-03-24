#!/bin/bash
set -e
# Q8 — Secret KeyRef Migration: Setup

# Clean prior state
kubectl delete deployment api-server &>/dev/null || true
kubectl delete secret db-credentials &>/dev/null || true

# Create deployment with hardcoded env vars
cat <<EOF | kubectl apply -f - &>/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-server
  template:
    metadata:
      labels:
        app: api-server
    spec:
      containers:
      - name: api-server
        image: busybox:stable
        command: ["/bin/sh", "-c", "while true; do echo connected; sleep 60; done"]
        env:
        - name: DB_USER
          value: "admin"
        - name: DB_PASS
          value: "Secret123!"
EOF

echo "Setup complete. Deployment api-server created with hardcoded env vars."
