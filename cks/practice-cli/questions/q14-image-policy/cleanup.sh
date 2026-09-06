#!/bin/bash
# Q14 ImagePolicyWebhook: restore the apiserver, then remove the admission config.
source "$(dirname "$0")/../../lib/env.sh"
restore_file "$KAS_MANIFEST" q14
wait_apiserver
rm -rf /etc/kubernetes/admission-controllers
kubectl delete pod ipw-probe --ignore-not-found >/dev/null 2>&1
echo "Cleanup complete"
