#!/bin/bash
# Q16 — Expose Deployment via NodePort: Cleanup
# Delete any NodePort service targeting frontend
for svc in $(kubectl get svc --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null); do
  SVC_TYPE=$(kubectl get svc "$svc" -o jsonpath='{.spec.type}' 2>/dev/null)
  SVC_SEL=$(kubectl get svc "$svc" -o jsonpath='{.spec.selector.app}' 2>/dev/null)
  if [[ "$SVC_TYPE" == "NodePort" && "$SVC_SEL" == "frontend" ]]; then
    kubectl delete svc "$svc" --ignore-not-found &>/dev/null
  fi
done
kubectl delete deployment frontend --ignore-not-found &>/dev/null
echo "Cleanup complete"
