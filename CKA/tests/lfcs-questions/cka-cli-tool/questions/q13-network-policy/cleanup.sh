#!/bin/bash
kubectl delete networkpolicy --all -n backend --ignore-not-found 2>/dev/null || true
kubectl delete ns frontend backend --ignore-not-found
echo "✅ Cleanup complete"
