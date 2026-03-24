#!/bin/bash
# Q16 — Create NodePort Service: Cleanup
# Delete any NodePort service targeting api
for svc in $(kubectl get svc --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null); do
  SVC_TYPE=$(kubectl get svc "$svc" -o jsonpath='{.spec.type}' 2>/dev/null)
  SVC_SEL=$(kubectl get svc "$svc" -o jsonpath='{.spec.selector.app}' 2>/dev/null)
  if [[ "$SVC_TYPE" == "NodePort" && "$SVC_SEL" == "api" ]]; then
    kubectl delete svc "$svc" --ignore-not-found &>/dev/null || true
  fi
done
kubectl delete deployment api-server --ignore-not-found &>/dev/null || true
rm -f /root/nodeport-output.txt || true
echo "Cleanup complete"
