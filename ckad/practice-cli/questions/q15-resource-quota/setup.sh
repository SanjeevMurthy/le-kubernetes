#!/bin/bash
set -e
# Q15 — Create Pod Under Resource Quota: Setup
#
# Quota values are sized for small clusters (1 CPU, ~2Gi memory per node).
# The question asks user to create a Pod using "half the quota" values.

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
    limits.cpu: "1"
    limits.memory: 1Gi
EOF
