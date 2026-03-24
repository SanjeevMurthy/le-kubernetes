#!/bin/bash
set -e
# Q20 — Fix NetworkPolicy Labels: Setup

# Clean prior state
kubectl delete namespace network-demo --ignore-not-found &>/dev/null || true
while kubectl get namespace network-demo &>/dev/null 2>&1; do sleep 1; done

# Create namespace
kubectl create namespace network-demo &>/dev/null

# Create frontend pod with WRONG labels (role=wrong-frontend instead of role=frontend)
kubectl apply -f - &>/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: network-demo
  labels:
    app: frontend
    role: wrong-frontend
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
EOF

# Create backend pod with WRONG labels (role=wrong-backend instead of role=backend)
kubectl apply -f - &>/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: backend
  namespace: network-demo
  labels:
    app: backend
    role: wrong-backend
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
EOF

# Create database pod with WRONG labels (role=wrong-db instead of role=db)
kubectl apply -f - &>/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: database
  namespace: network-demo
  labels:
    app: database
    role: wrong-db
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
EOF

# Create deny-all NetworkPolicy
kubectl apply -f - &>/dev/null <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: network-demo
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# Create NetworkPolicy: allow-frontend-to-backend (uses role= labels)
kubectl apply -f - &>/dev/null <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: network-demo
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

# Create NetworkPolicy: allow-backend-to-db (uses role= labels)
kubectl apply -f - &>/dev/null <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-db
  namespace: network-demo
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: backend
    ports:
    - protocol: TCP
      port: 80
EOF

echo "Setup complete."
