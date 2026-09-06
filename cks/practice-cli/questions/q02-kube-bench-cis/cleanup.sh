#!/bin/bash
# Q2 kube-bench: put the apiserver manifest and the kubelet config back.
source "$(dirname "$0")/../../lib/env.sh"
KUBELET_CONF=/var/lib/kubelet/config.yaml
restore_file "$KAS_MANIFEST" q02
restore_file "$KUBELET_CONF" q02
systemctl restart kubelet 2>/dev/null
wait_apiserver
echo "Cleanup complete"
