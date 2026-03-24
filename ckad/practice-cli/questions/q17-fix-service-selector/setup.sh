#!/bin/bash
set -e
# Q17 — Fix Service Selector Mismatch: Setup

# Clean prior state
kubectl delete service web-svc &>/dev/null || true
kubectl delete deployment web-app &>/dev/null || true

# Create deployment with labels app=webapp, tier=frontend
kubectl apply -f - &>/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: webapp
    tier: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
      tier: frontend
  template:
    metadata:
      labels:
        app: webapp
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

# Create service with WRONG selector (app=wrongapp instead of app=webapp)
kubectl apply -f - &>/dev/null <<EOF
apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  selector:
    app: wrongapp
  ports:
  - port: 80
    targetPort: 80
EOF
