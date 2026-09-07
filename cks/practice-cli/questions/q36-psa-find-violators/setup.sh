#!/bin/bash
# Q36 PSA violators: three pods in an unlabelled namespace, two of which would
# be rejected under the baseline standard.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_tool kubectl

NS=psa-lab

kubectl create namespace "$NS" 2>/dev/null || true

# A rerun has to start from an unlabelled namespace, otherwise the two offending
# pods below would be rejected by the admission plugin.
for k in enforce enforce-version audit audit-version warn warn-version; do
  kubectl label namespace "$NS" "pod-security.kubernetes.io/$k-" >/dev/null 2>&1 || true
done

kubectl delete pod priv hostpid clean -n "$NS" --ignore-not-found >/dev/null 2>&1 || true

kubectl apply -n "$NS" -f - >/dev/null <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: priv
  labels: {app: priv}
spec:
  containers:
  - name: c
    image: busybox:1.36
    command: ["sleep", "3600"]
    securityContext:
      privileged: true
---
apiVersion: v1
kind: Pod
metadata:
  name: hostpid
  labels: {app: hostpid}
spec:
  hostPID: true
  containers:
  - name: c
    image: busybox:1.36
    command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: clean
  labels: {app: clean}
spec:
  containers:
  - name: c
    image: busybox:1.36
    command: ["sleep", "3600"]
EOF

for p in priv hostpid clean; do
  kubectl wait --for=condition=Ready "pod/$p" -n "$NS" --timeout=90s >/dev/null 2>&1 \
    || echo "warning: pod $p is not Ready yet"
done

DIR=$(course_dir 36)
rm -f "$DIR/violators.txt"

echo "Setup complete."
echo "  Namespace:    $NS (no pod-security labels on it)"
echo "  Pods:         $(kubectl get pods -n "$NS" -o jsonpath='{range .items[*]}{.metadata.name}{" "}{end}')"
echo "  Deliverable:  $DIR/violators.txt"
echo "  Two of these three pods would be refused under the baseline standard."
echo "  Setting the enforce label does not evict them, so find them yourself."
