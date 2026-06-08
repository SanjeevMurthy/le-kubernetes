#!/bin/bash
# Q19 — Fix Ingress Backend: Cleanup
kubectl delete ingress api-ingress --ignore-not-found &>/dev/null || true
kubectl delete service store-svc --ignore-not-found &>/dev/null || true
kubectl delete deployment store-app --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
