#!/bin/bash
# Q14 — Restrict images by registry: Setup
echo "Only images from 'registry.internal' may run. Implement via EITHER:"
echo "  (A) Kyverno ClusterPolicy (Enforce) restricting the image registry, OR"
echo "  (B) ImagePolicyWebhook on the apiserver (admission config + kubeconfig + flags)."
if ! kubectl get crd clusterpolicies.kyverno.io &>/dev/null; then
  echo "NOTE: Kyverno not detected (option A requires it)."
fi
