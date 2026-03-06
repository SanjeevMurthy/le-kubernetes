#!/bin/bash
# Q6 — Helm Template ArgoCD: Setup
# No cluster setup needed — this is a Helm templating exercise.

echo "No cluster setup needed for this question."
echo ""
echo "Prerequisite: Helm must be installed on this machine."
echo ""
if command -v helm &>/dev/null; then
  echo "  Helm is installed: $(helm version --short 2>/dev/null)"
else
  echo "  WARNING: Helm is not installed. Install it first."
fi
echo ""
echo "Your tasks:"
echo "  1. Add the ArgoCD Helm repo (https://argoproj.github.io/argo-helm)"
echo "  2. Create namespace 'argocd'"
echo "  3. Generate Helm template from chart version 7.7.3 with CRDs disabled"
echo "  4. Save output to /root/argo-helm.yaml"
