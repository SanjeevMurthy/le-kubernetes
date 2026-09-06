#!/bin/bash
# Q28 gVisor dmesg: remove the lab namespace, the RuntimeClass and the deliverable.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete namespace gvisor-lab --ignore-not-found >/dev/null 2>&1
kubectl delete runtimeclass gvisor --ignore-not-found >/dev/null 2>&1
rm -rf "$COURSE_DIR/28"
echo "Cleanup complete"
