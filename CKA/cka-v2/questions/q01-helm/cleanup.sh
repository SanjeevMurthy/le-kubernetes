#!/bin/bash
# Q1 — Helm Template Generation and Chart Installation: Cleanup
helm uninstall argocd -n argocd &>/dev/null || true
helm repo remove argocd &>/dev/null || true
kubectl delete ns argocd --ignore-not-found &>/dev/null
rm -f /root/argo-helm.yaml
echo "Cleanup complete"
