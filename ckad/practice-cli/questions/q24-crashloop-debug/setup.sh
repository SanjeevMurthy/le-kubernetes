#!/bin/bash
set -e
# Q24 — CrashLoopBackOff Debug: Setup

# Clean prior state
kubectl delete namespace debug-ns --ignore-not-found &>/dev/null || true
while kubectl get namespace debug-ns &>/dev/null 2>&1; do sleep 1; done
rm -f /root/crash-events.txt &>/dev/null || true

# Create namespace
kubectl create namespace debug-ns &>/dev/null

# Create pod that immediately crashes (CrashLoopBackOff)
kubectl apply -f - &>/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: crash-pod
  namespace: debug-ns
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sh", "-c", "exit 1"]
EOF

echo "Setup complete."
