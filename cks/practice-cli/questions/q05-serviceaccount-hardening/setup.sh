#!/bin/bash
# Q5 ServiceAccount token hardening: the legacy pod really exists and really
# has a token mounted, so the candidate has something to fix.
set -e
source "$(dirname "$0")/../../lib/env.sh"

NS=app

kubectl create namespace "$NS" 2>/dev/null || true

# Reset to the insecure starting state on every run.
kubectl delete serviceaccount app-sa -n "$NS" --ignore-not-found >/dev/null 2>&1 || true
if [[ "$(kubectl get pod legacy -n "$NS" -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null)" != "default" ]]; then
  kubectl delete pod legacy -n "$NS" --ignore-not-found --now >/dev/null 2>&1 || true
fi
if ! kubectl get pod legacy -n "$NS" >/dev/null 2>&1; then
  kubectl run legacy --image=busybox:1.36 -n "$NS" -- sleep 3600 >/dev/null
fi

kubectl wait --for=condition=Ready pod/legacy -n "$NS" --timeout=120s >/dev/null 2>&1 || echo "warning: pod legacy is not Ready yet"

SA=$(kubectl get pod legacy -n "$NS" -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null)
echo "Setup complete: namespace '$NS' runs pod 'legacy' (busybox:1.36, command 'sleep 3600')"
echo "as ServiceAccount '$SA', with an API token mounted at /var/run/secrets/kubernetes.io/serviceaccount."
echo "No ServiceAccount 'app-sa' exists yet."
