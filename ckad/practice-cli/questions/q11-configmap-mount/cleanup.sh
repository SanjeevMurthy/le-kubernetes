#!/bin/bash
# Q11 — ConfigMap Volume Mount: Cleanup
kubectl delete pod web-pod --ignore-not-found &>/dev/null || true
kubectl delete configmap web-config --ignore-not-found &>/dev/null || true
rm -f /opt/index.html || true
echo "Cleanup complete"
