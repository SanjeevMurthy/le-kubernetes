#!/bin/bash
set -e
# Q15 — Create Pod Under Resource Quota: Setup

# Clean prior state
kubectl delete namespace prod &>/dev/null || true
while kubectl get namespace prod &>/dev/null 2>&1; do sleep 1; done

# Create namespace
kubectl create namespace prod &>/dev/null

# Create ResourceQuota
kubectl apply -f - &>/dev/null <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: prod-quota
  namespace: prod
spec:
  hard:
    pods: "10"
    limits.cpu: "2"
    limits.memory: 4Gi
EOF
