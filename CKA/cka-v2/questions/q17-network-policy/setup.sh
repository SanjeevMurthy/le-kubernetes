#!/bin/bash
set -e
# Q17 — Network Policy Configuration: Setup

# Create namespaces
kubectl create namespace production &>/dev/null
kubectl label namespace production env=production &>/dev/null
kubectl create namespace monitoring &>/dev/null

# Create frontend deployment in production
kubectl apply -f - &>/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: production
spec:
  replicas: 1
  selector:
    matchLabels:
      role: frontend
  template:
    metadata:
      labels:
        role: frontend
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

# Create frontend service in production
kubectl expose deployment frontend -n production --port=80 --target-port=80 &>/dev/null

# Create backend deployment in production
kubectl apply -f - &>/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: production
spec:
  replicas: 1
  selector:
    matchLabels:
      role: backend
  template:
    metadata:
      labels:
        role: backend
    spec:
      containers:
      - name: nginx
        image: nginx
EOF

# Create monitoring deployment in monitoring namespace
kubectl create deployment monitoring --image=nginx -n monitoring &>/dev/null
