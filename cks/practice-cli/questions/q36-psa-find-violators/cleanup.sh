#!/bin/bash
# Q36 PSA violators: remove everything setup created.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete namespace psa-lab --ignore-not-found >/dev/null 2>&1
rm -rf "$COURSE_DIR/36"
echo "Cleanup complete"
