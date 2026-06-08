#!/bin/bash
set -e
# Q4 — PVC Mount: Setup

# Clean prior state
kubectl delete pod data-pod --ignore-not-found &>/dev/null || true
kubectl delete pvc data-pvc --ignore-not-found &>/dev/null || true

echo "Setup complete. No pre-existing resources needed."
