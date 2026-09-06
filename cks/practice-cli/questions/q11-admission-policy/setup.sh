#!/bin/bash
# Q11 Kyverno admission policy: an empty namespace that currently accepts any registry.
set -e
source "$(dirname "$0")/../../lib/env.sh"

NS=kyverno-lab
POL=restrict-registries

if ! kubectl get crd clusterpolicies.kyverno.io >/dev/null 2>&1; then
  echo "Kyverno is not installed in this cluster. Install it first:"
  echo "  kubectl create -f https://github.com/kyverno/kyverno/releases/latest/download/install.yaml"
  exit 1
fi

kubectl create namespace "$NS" 2>/dev/null || true
# Reset the starting state: the policy is the deliverable.
kubectl delete clusterpolicy "$POL" --ignore-not-found >/dev/null 2>&1 || true

echo "Setup complete: Kyverno is installed and namespace '$NS' is empty."
echo "There is no ClusterPolicy '$POL', so pods from any registry are admitted today:"
if kubectl run admission-probe --image=docker.io/library/nginx:1.27 -n "$NS" --dry-run=server >/dev/null 2>&1; then
  echo "  a docker.io/library/nginx:1.27 pod is currently ACCEPTED at admission."
else
  echo "  note: a docker.io image is already being rejected; check for other admission policies."
fi
echo "Only images from registry.internal/ may be admitted once you are done."
