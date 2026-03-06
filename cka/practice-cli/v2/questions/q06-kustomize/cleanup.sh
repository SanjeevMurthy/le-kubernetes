#!/bin/bash
# Q6 — Kustomize Deployment Tasks: Cleanup
kubectl delete ns production --ignore-not-found &>/dev/null
rm -rf /root/kustomize-lab
echo "Cleanup complete"
