#!/bin/bash
# Q24 metadata endpoint: run a workload in a namespace with no policies at all,
# so every address including 169.254.169.254 is currently reachable from it.
set -e
source "$(dirname "$0")/../../lib/env.sh"

NS=metadata-lab

kubectl create namespace "$NS" 2>/dev/null || true

# Start from an empty policy set so a rerun really resets the scenario.
kubectl delete networkpolicy --all -n "$NS" >/dev/null 2>&1 || true
kubectl delete pod np-meta-check -n "$NS" --ignore-not-found >/dev/null 2>&1 || true

kubectl apply -n "$NS" -f - >/dev/null <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata: {name: app}
spec:
  replicas: 1
  selector: {matchLabels: {app: app}}
  template:
    metadata: {labels: {app: app}}
    spec:
      containers:
      - name: app
        image: nginx:1.27
EOF

kubectl -n "$NS" rollout status deploy/app --timeout=120s >/dev/null 2>&1 \
  || echo "warning: deployment app is not ready yet"

echo "Setup complete."
echo "  Namespace:   $NS"
echo "  Workload:    deployment app, one replica, pod label app=app"
echo "  Policies:    none, so the pods can currently reach every address,"
echo "               including the metadata service at 169.254.169.254"
echo "  CNI:         $(detect_cni) (NetworkPolicy is only enforced by Calico or Cilium)"
echo "  Deliverable: NetworkPolicy metadata-deny in namespace $NS"
