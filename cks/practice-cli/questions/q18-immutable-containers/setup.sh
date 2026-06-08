#!/bin/bash
set -e
# Q18 — Immutable containers: Setup (creates a mutable workload)
kubectl create namespace prod 2>/dev/null || true
kubectl apply -n prod -f - &>/dev/null <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata: {name: api}
spec:
  replicas: 1
  selector: {matchLabels: {app: api}}
  template:
    metadata: {labels: {app: api}}
    spec:
      containers:
      - name: c
        image: nginx
EOF
echo "Setup complete: deployment 'api' in 'prod' (writable root FS)."
echo "Harden it: readOnlyRootFilesystem:true, allowPrivilegeEscalation:false, and an emptyDir at /tmp."
