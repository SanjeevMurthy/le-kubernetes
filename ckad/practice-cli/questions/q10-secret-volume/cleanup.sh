#!/bin/bash
# Q10 — Secret as Volume Mount: Cleanup
kubectl delete pod secret-vol-pod --ignore-not-found &>/dev/null || true
kubectl delete secret credentials-secret --ignore-not-found &>/dev/null || true
rm -rf /opt/credentials || true
echo "Cleanup complete"
