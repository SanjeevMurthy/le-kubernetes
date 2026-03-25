#!/bin/bash
set -e
# Q23 — Readiness Probe: Setup
#
# Uses python http.server on port 8080 (not nginx, which only listens on 80).
# python3 -m http.server responds with 200 to ANY path, including /ready,
# so the readiness probe httpGet /ready:8080 will succeed once added.

# Clean prior state
kubectl delete deployment api-deploy --ignore-not-found &>/dev/null || true

# Create deployment without probes — app serves on port 8080
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
        image: python:3-alpine
        command: ["python3", "-m", "http.server", "8080"]
        ports:
        - containerPort: 8080
EOF

kubectl rollout status deployment api-deploy --timeout=90s &>/dev/null || true
echo "Setup complete."
