#!/bin/bash
# Q31 Falco hunt: remove the lab namespace and the deliverable.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete namespace falco-hunt --ignore-not-found >/dev/null 2>&1
rm -rf "$COURSE_DIR/31"
echo "Cleanup complete"
