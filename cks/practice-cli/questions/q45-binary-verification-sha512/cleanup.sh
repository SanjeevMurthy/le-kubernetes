#!/bin/bash
# Q45 binary verification: the question created its own directory and nothing
# outside it, so removing that directory and the recorded answer is the whole
# cleanup.
source "$(dirname "$0")/../../lib/env.sh"
rm -rf "$COURSE_DIR/45"
rm -rf "$CKS_STATE_DIR/backup/q45"
echo "Cleanup complete"
