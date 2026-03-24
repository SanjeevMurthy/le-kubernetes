#!/bin/bash
set -e
# Q19 — Fix Ingress Backend: Setup

# Clean prior state
kubectl delete ingress store-ingress --ignore-not-found &>/dev/null || true
kubectl delete service store-svc --ignore-not-found &>/dev/null || true
kubectl delete deployment store-app --ignore-not-found &>/dev/null || true

# Create deployment
kubectl create deployment store-app --image=nginx --replicas=2 &>/dev/null

# Create service
kubectl expose deployment store-app --name=store-svc --port=80 --target-port=80 &>/dev/null

# Create Ingress with wrong backend service name and wrong port
kubectl apply -f - &>/dev/null <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: store-ingress
spec:
  rules:
  - host: store.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: store-service
            port:
              number: 8080
EOF

echo "Setup complete."
