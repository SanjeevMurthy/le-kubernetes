#!/bin/bash
# Q13 cleanup: remove everything setup created.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete namespace trivy-lab --ignore-not-found >/dev/null 2>&1
rm -rf "$COURSE_DIR/13"
echo "Cleanup complete"
