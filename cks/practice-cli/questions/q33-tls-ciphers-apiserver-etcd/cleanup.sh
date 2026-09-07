#!/bin/bash
# Q33 TLS hardening: put both static pod manifests back and wait for the
# control plane to return.
source "$(dirname "$0")/../../lib/env.sh"
restore_file /etc/kubernetes/manifests/etcd.yaml q33
restore_file "$KAS_MANIFEST" q33
wait_apiserver
echo "Cleanup complete"
