#!/bin/bash
# Q23 — Readiness Probe: Cleanup
kubectl delete deployment api-deploy --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
