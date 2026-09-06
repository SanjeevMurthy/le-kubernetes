#!/bin/bash
# Q15 cleanup: remove everything setup created.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete namespace appsec --ignore-not-found >/dev/null 2>&1
rm -rf "$COURSE_DIR/15"
echo "Cleanup complete"
