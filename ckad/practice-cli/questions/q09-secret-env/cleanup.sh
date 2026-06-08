#!/bin/bash
# Q9 — Create Secret and Pod with Env Vars: Cleanup
kubectl delete pod api-pod --ignore-not-found &>/dev/null || true
kubectl delete secret secret1 --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
