#!/bin/bash
# Q21 ImagePolicyWebhook: restore the API server first, then remove the files
# and the Service that setup created.
source "$(dirname "$0")/../../lib/env.sh"
restore_file "$KAS_MANIFEST" q21
wait_apiserver
kubectl delete pod ipw-probe --ignore-not-found >/dev/null 2>&1
kubectl delete svc image-bouncer -n default --ignore-not-found >/dev/null 2>&1
rm -f /etc/kubernetes/admission-controllers/admission-config.yaml \
      /etc/kubernetes/admission-controllers/kubeconfig.yaml \
      /etc/kubernetes/admission-controllers/webhook-ca.crt
rmdir /etc/kubernetes/admission-controllers 2>/dev/null || true
echo "Cleanup complete"
