#!/bin/bash
# Q4 — PVC Mount: Cleanup
kubectl delete pod data-pod --ignore-not-found &>/dev/null || true
kubectl delete pvc data-pvc --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
