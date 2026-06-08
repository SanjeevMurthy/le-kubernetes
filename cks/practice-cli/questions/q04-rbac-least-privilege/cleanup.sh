#!/bin/bash
# Q4 — Cleanup
kubectl delete clusterrolebinding ci-admin --ignore-not-found &>/dev/null
kubectl delete namespace build --ignore-not-found &>/dev/null
echo "Cleanup complete"
