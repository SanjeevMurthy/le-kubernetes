#!/bin/bash
set -e
# Q15 — Static analysis + manifest hardening: Setup (creates an INSECURE workload)
kubectl create namespace appsec 2>/dev/null || true
kubectl apply -n appsec -f - &>/dev/null <<'EOF'
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
      - name: c
        image: nginx
EOF
echo "Setup complete: insecure deployment 'app' in 'appsec'. Scan with kubesec and harden the spec:"
echo "  readOnlyRootFilesystem, allowPrivilegeEscalation:false, capabilities.drop:[ALL], runAsNonRoot."
