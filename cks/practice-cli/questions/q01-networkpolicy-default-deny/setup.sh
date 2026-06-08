#!/bin/bash
set -e
# Q1 — NetworkPolicy default-deny + selective allow: Setup
kubectl create namespace prod 2>/dev/null || true
kubectl apply -n prod -f - &>/dev/null <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata: {name: backend}
spec:
  replicas: 1
  selector: {matchLabels: {app: backend}}
  template:
    metadata: {labels: {app: backend}}
    spec:
      containers: [{name: nginx, image: nginx, ports: [{containerPort: 8080}]}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: frontend}
spec:
  replicas: 1
  selector: {matchLabels: {app: frontend}}
  template:
    metadata: {labels: {app: frontend}}
    spec:
      containers: [{name: nginx, image: nginx}]
EOF
echo "Setup complete: namespace 'prod' with backend (app=backend) and frontend (app=frontend)."
