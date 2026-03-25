#!/bin/bash
set -e
# Q5 — Canary Deployment: Setup

# Clean prior state
kubectl delete deployment web-app-canary --ignore-not-found &>/dev/null || true
kubectl delete deployment web-app --ignore-not-found &>/dev/null || true
kubectl delete svc web-service --ignore-not-found &>/dev/null || true

# Create Deployment web-app with 5 replicas
cat <<EOF | kubectl apply -f - &>/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: default
spec:
  replicas: 5
  selector:
    matchLabels:
      app: webapp
      version: v1
  template:
    metadata:
      labels:
        app: webapp
        version: v1
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
EOF

# Create Service selecting app=webapp
cat <<EOF | kubectl apply -f - &>/dev/null
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: default
spec:
  selector:
    app: webapp
  ports:
  - port: 80
    targetPort: 80
EOF

# Wait for deployment rollout
kubectl rollout status deployment web-app --timeout=60s &>/dev/null

echo "Setup complete. Deployment web-app (5 replicas) and Service web-service created."
