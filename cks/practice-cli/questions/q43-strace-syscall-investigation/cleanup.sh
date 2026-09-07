#!/bin/bash
# Q43 strace: remove the lab namespace and the deliverable.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete namespace strace-lab --ignore-not-found >/dev/null 2>&1
rm -rf "$COURSE_DIR/43"
echo "Cleanup complete"
