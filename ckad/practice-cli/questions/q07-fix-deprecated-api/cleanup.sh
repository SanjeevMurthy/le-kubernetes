#!/bin/bash
# Q7 — Fix Deprecated API Version: Cleanup
kubectl delete deployment broken-app --ignore-not-found &>/dev/null || true
rm -f /root/broken-deploy.yaml || true
echo "Cleanup complete"
