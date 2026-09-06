#!/bin/bash
# Q25 read a Secret from etcd: remove the lab namespace, the deliverables and
# the recorded value.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete namespace etcd-lab --ignore-not-found >/dev/null 2>&1
rm -rf "$COURSE_DIR/25"
rm -f "$CKS_STATE_DIR/q25.value"
echo "Cleanup complete"
