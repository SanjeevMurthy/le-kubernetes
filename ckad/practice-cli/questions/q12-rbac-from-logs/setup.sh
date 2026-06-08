#!/bin/bash
set -e
# Q12 — RBAC from Pod Logs: Setup

# Clean prior state
kubectl delete namespace audit &>/dev/null || true

# Wait for namespace deletion to complete
echo "Waiting for clean state..."
while kubectl get namespace audit &>/dev/null 2>&1; do
  sleep 2
done

# Create namespace
kubectl create namespace audit &>/dev/null

# Create Pod using the default ServiceAccount (no RBAC permissions)
cat <<EOF | kubectl apply -f - &>/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: log-collector
  namespace: audit
spec:
  containers:
  - name: log-collector
    image: bitnami/kubectl:latest
    command: ["/bin/sh", "-c", "while true; do echo 'Attempting to list pods...'; kubectl get pods -n audit 2>&1 || true; sleep 30; done"]
EOF

echo "Setup complete. Pod log-collector created in namespace audit using default serviceAccount."
echo "The pod will fail to list pods due to missing RBAC permissions."
