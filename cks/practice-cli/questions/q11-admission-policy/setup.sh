#!/bin/bash
# Q11 — Admission policy (Kyverno): Setup
if ! kubectl get crd clusterpolicies.kyverno.io &>/dev/null; then
  echo "NOTE: Kyverno not detected. Install it first:"
  echo "  kubectl create -f https://github.com/kyverno/kyverno/releases/latest/download/install.yaml"
fi
echo "Create a Kyverno ClusterPolicy 'restrict-registries' (Enforce) allowing only registry.internal/ images."
