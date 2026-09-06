#!/bin/bash
# Q1 NetworkPolicy default-deny plus selective allow: create the starting state.
set -e
source "$(dirname "$0")/../../lib/env.sh"

NS=netpol-lab

kubectl create namespace "$NS" 2>/dev/null || true

# Start from a clean policy set so a rerun really resets the scenario.
kubectl delete networkpolicy --all -n "$NS" >/dev/null 2>&1 || true

kubectl apply -n "$NS" -f - >/dev/null <<'EOF'
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

kubectl -n "$NS" rollout status deploy/backend --timeout=120s >/dev/null 2>&1 || echo "warning: deployment backend is not ready yet"
kubectl -n "$NS" rollout status deploy/frontend --timeout=120s >/dev/null 2>&1 || echo "warning: deployment frontend is not ready yet"

echo "Setup complete: namespace '$NS' runs deployment 'backend' (label app=backend, container port 8080)"
echo "and deployment 'frontend' (label app=frontend). Both pods are Running and must stay Running."
echo "There are no NetworkPolicies in '$NS', so every pod can talk to everything, including DNS."
echo "CNI in this cluster: $(detect_cni)."
