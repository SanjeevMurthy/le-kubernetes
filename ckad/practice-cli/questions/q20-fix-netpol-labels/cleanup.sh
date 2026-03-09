#!/bin/bash
# Q20 — Fix NetworkPolicy Labels: Cleanup
kubectl delete namespace netpol-test --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
