#!/bin/bash
# Q14 — Network Policy: Cleanup
kubectl delete networkpolicy --all -n backend --ignore-not-found 2>/dev/null || true
kubectl delete ns frontend backend --ignore-not-found
rm -rf /root/network-policies
echo "✅ Cleanup complete"
