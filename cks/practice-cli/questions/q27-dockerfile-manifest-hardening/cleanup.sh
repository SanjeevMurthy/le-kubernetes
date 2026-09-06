#!/bin/bash
# Q27 Dockerfile and manifest hardening: remove the two files and the recorded
# line counts. Nothing was applied to a cluster.
source "$(dirname "$0")/../../lib/env.sh"
rm -rf "$COURSE_DIR/27"
rm -f "$CKS_STATE_DIR/q27.lines"
echo "Cleanup complete"
