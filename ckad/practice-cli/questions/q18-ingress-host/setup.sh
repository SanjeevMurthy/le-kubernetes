#!/bin/bash
set -e
# Q18 — Create Ingress with Host Rule: Setup

# Clean prior state
kubectl delete ingress webapp-ingress &>/dev/null || true
kubectl delete service webapp-svc &>/dev/null || true
kubectl delete deployment webapp &>/dev/null || true

# Create deployment
kubectl apply -f - &>/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  labels:
    app: webapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

# Create ClusterIP service on port 8080
kubectl apply -f - &>/dev/null <<EOF
apiVersion: v1
kind: Service
metadata:
  name: webapp-svc
spec:
  type: ClusterIP
  selector:
    app: webapp
  ports:
  - port: 8080
    targetPort: 80
EOF

# Warn if no ingress controller is detected
if ! kubectl get pods -A -l app.kubernetes.io/component=controller --no-headers 2>/dev/null | grep -q .; then
  echo "WARNING: No ingress controller detected. The Ingress resource will be created but may not be functional without one."
fi
