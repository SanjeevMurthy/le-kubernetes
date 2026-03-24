#!/bin/bash
set -e
# Q16 — Create NodePort Service: Setup

# Clean prior state
kubectl delete deployment api-server &>/dev/null || true

# Create deployment
kubectl apply -f - &>/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  labels:
    app: api-server
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-server
  template:
    metadata:
      labels:
        app: api-server
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 9090
EOF
