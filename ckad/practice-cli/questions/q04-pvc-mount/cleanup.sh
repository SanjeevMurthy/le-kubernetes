#!/bin/bash
# Q4 — PVC Mount: Cleanup
kubectl delete pod task-pod --ignore-not-found &>/dev/null || true
kubectl delete pvc task-pvc --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
