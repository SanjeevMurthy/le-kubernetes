#!/bin/bash
# Q18 immutable containers: a deployment with a fully writable root filesystem.
set -e
source "$(dirname "$0")/../../lib/env.sh"

NS=immutable-lab

kubectl create namespace "$NS" 2>/dev/null || true

# Replace the deployment on every run so the scenario starts mutable again.
kubectl -n "$NS" delete deployment api --ignore-not-found >/dev/null 2>&1 || true
kubectl apply -n "$NS" -f - >/dev/null <<'EOF'
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

kubectl -n "$NS" rollout status deploy/api --timeout=120s >/dev/null 2>&1 || echo "warning: deployment api is not ready yet"

echo "Setup complete: namespace '$NS' runs deployment 'api' (nginx) with a writable root filesystem;"
echo "'kubectl exec deploy/api -n $NS -- touch /etc/probe' succeeds today."
echo "The pod must still be Running when you are done, and nginx writes to /var/cache/nginx and /var/run as well as /tmp."
