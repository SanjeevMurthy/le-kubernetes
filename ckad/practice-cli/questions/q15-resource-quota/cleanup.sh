#!/bin/bash
# Q15 — Create Pod Under Resource Quota: Cleanup
kubectl delete namespace prod --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
