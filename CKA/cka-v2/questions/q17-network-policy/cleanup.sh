#!/bin/bash
# Q17 — Network Policy Configuration: Cleanup
kubectl delete networkpolicy allow-frontend -n production --ignore-not-found &>/dev/null
kubectl delete namespace production --ignore-not-found &>/dev/null
kubectl delete namespace monitoring --ignore-not-found &>/dev/null
echo "Cleanup complete"
