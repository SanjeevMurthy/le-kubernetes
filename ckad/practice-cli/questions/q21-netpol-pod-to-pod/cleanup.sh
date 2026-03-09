#!/bin/bash
# Q21 — NetworkPolicy Pod-to-Pod: Cleanup
kubectl delete namespace app-ns --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
