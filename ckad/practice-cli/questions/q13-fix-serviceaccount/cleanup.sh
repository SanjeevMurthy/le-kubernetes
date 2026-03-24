#!/bin/bash
# Q13 — Fix ServiceAccount Assignment: Cleanup
kubectl delete namespace monitoring --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
