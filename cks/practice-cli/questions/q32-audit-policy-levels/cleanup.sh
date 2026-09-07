#!/bin/bash
# Q32 audit policy order: restore the API server manifest and remove the files
# the setup created.
source "$(dirname "$0")/../../lib/env.sh"
restore_file "$KAS_MANIFEST" q32
wait_apiserver
rm -rf /etc/kubernetes/audit /var/log/kubernetes/audit
if [[ "$(kubectl get namespace prod -o jsonpath='{.metadata.labels.cks-lab}' 2>/dev/null)" == "q32" ]]; then
  kubectl delete namespace prod --ignore-not-found >/dev/null 2>&1
else
  kubectl -n prod delete secret db-creds --ignore-not-found >/dev/null 2>&1
fi
echo "Cleanup complete"
