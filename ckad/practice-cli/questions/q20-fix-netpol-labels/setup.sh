#!/bin/bash
set -e
# Q20 — Fix NetworkPolicy Labels: Setup

# Clean prior state
kubectl delete namespace netpol-test --ignore-not-found &>/dev/null || true
while kubectl get namespace netpol-test &>/dev/null 2>&1; do sleep 1; done

# Create namespace
kubectl create namespace netpol-test &>/dev/null

# Create web pod with wrong labels (tier=frontend instead of role=frontend)
kubectl apply -f - &>/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: web
  namespace: netpol-test
  labels:
    app: web
    tier: frontend
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
EOF

# Create api pod with wrong labels (tier=backend instead of role=backend)
kubectl apply -f - &>/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: api
  namespace: netpol-test
  labels:
    app: api
    tier: backend
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
EOF

# Create NetworkPolicy that uses role= labels (pods don't match yet)
kubectl apply -f - &>/dev/null <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-to-api
  namespace: netpol-test
spec:
  podSelector:
    matchLabels:
      role: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 80
EOF

echo "Setup complete."
