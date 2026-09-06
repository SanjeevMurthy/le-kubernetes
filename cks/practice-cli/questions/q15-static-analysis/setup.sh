#!/bin/bash
# Q15 static analysis: write the insecure manifest the candidate has to harden,
# and apply it so there is a live object to grade too.
set -e
source "$(dirname "$0")/../../lib/env.sh"

NS=appsec
D=$(course_dir 15)
M="$D/deploy.yaml"

kubectl create namespace "$NS" 2>/dev/null || true

# Rewrite the manifest on every run: it is the starting state, not the answer.
cat > "$M" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: appsec
spec:
  replicas: 1
  selector:
    matchLabels: {app: app}
  template:
    metadata:
      labels: {app: app}
    spec:
      containers:
      - name: c
        image: nginx:1.27
EOF

kubectl apply -f "$M" >/dev/null

echo "Setup complete: the insecure manifest is at $M and has been applied,"
echo "so deployment 'app' in namespace '$NS' runs with no securityContext at all."
echo "Harden that file and reapply it; both the file and the live Deployment are graded."
