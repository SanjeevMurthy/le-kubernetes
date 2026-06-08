#!/bin/bash
# Q21 — NetworkPolicy Pod-to-Pod: Cleanup
kubectl delete namespace backend --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
