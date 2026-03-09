#!/bin/bash
set -e
# Q17 — Fix Service Selector Mismatch: Setup

# Clean prior state
kubectl delete service backend-svc &>/dev/null || true
kubectl delete deployment backend &>/dev/null || true

# Create deployment with labels app=backend, tier=api
kubectl apply -f - &>/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  labels:
    app: backend
    tier: api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
      tier: api
  template:
    metadata:
      labels:
        app: backend
        tier: api
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

# Create service with WRONG selector (app=backend-app instead of app=backend)
kubectl apply -f - &>/dev/null <<EOF
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
spec:
  selector:
    app: backend-app
  ports:
  - port: 80
    targetPort: 80
EOF
