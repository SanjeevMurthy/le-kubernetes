#!/bin/bash
# Q3 cleanup: remove everything setup created.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete namespace tls-lab --ignore-not-found >/dev/null 2>&1
rm -rf "$COURSE_DIR/3"
echo "Cleanup complete"
