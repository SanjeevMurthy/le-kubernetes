#!/bin/bash
set -e
# Q9 — Create Secret and Pod with Env Vars: Setup

# Clean prior state
kubectl delete pod api-pod &>/dev/null || true
kubectl delete secret secret1 &>/dev/null || true

echo "Setup complete. Cluster is clean — create resources from scratch."
