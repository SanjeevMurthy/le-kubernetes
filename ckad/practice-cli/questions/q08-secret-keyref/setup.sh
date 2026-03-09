#!/bin/bash
set -e
# Q8 — Secret KeyRef Migration: Setup

# Clean prior state
kubectl delete deployment db-app &>/dev/null || true
kubectl delete secret db-credentials &>/dev/null || true

# Create deployment with hardcoded env vars
cat <<EOF | kubectl apply -f - &>/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db-app
  template:
    metadata:
      labels:
        app: db-app
    spec:
      containers:
      - name: db-app
        image: busybox:stable
        command: ["/bin/sh", "-c", "while true; do echo connected; sleep 60; done"]
        env:
        - name: DB_USER
          value: "admin"
        - name: DB_PASS
          value: "supersecret"
EOF

echo "Setup complete. Deployment db-app created with hardcoded env vars."
