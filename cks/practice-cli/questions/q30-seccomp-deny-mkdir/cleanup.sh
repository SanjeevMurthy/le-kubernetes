#!/bin/bash
# Q30 seccomp deny mkdir: remove the lab namespace, the profile and the deliverable.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete namespace seccomp-lab --ignore-not-found >/dev/null 2>&1
on_worker rm -f /var/lib/kubelet/seccomp/profiles/no-mkdir.json 2>/dev/null
rm -rf "$COURSE_DIR/30"
echo "Cleanup complete"
