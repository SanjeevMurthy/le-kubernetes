#!/bin/bash
# Q8 — Secret KeyRef Migration: Cleanup
kubectl delete deployment api-server --ignore-not-found &>/dev/null || true
kubectl delete secret db-credentials --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
