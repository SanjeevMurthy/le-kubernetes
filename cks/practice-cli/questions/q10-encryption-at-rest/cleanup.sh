#!/bin/bash
# Q10 encryption at rest: drop the lab namespace, restore the apiserver, remove the config.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete namespace enc-lab --ignore-not-found >/dev/null 2>&1
restore_file "$KAS_MANIFEST" q10
wait_apiserver
rm -rf /etc/kubernetes/enc
echo "Cleanup complete"
