#!/bin/bash
# Q23 — Readiness Probe: Cleanup
kubectl delete deployment health-app --ignore-not-found &>/dev/null || true
echo "Cleanup complete"
