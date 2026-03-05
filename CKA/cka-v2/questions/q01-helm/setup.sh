#!/bin/bash
set -e
# Q1 — Helm Template Generation and Chart Installation: Setup
# Verify helm is installed. No cluster resources needed.

if ! command -v helm &>/dev/null; then
  echo "ERROR: Helm is not installed. Please install helm before attempting this question." >&2
  exit 1
fi

# Clean any prior state silently
helm uninstall argocd -n argocd &>/dev/null || true
kubectl delete ns argocd --ignore-not-found &>/dev/null
helm repo remove argocd &>/dev/null || true
rm -f /root/argo-helm.yaml
