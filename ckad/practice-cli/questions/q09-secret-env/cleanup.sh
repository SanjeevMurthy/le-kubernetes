#!/bin/bash
# Q9 — Create Secret and Pod with Env Vars: Cleanup
kubectl delete pod secret-pod --ignore-not-found &>/dev/null || true
kubectl delete secret app-secret --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
