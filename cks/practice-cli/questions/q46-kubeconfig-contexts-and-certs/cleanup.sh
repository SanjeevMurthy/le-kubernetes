#!/bin/bash
# Q46 kubeconfig: the question only ever wrote inside its own directory, and it
# deliberately never touched the candidate's context, so there is nothing to
# restore.
source "$(dirname "$0")/../../lib/env.sh"
rm -rf "$COURSE_DIR/46"
rm -rf "$CKS_STATE_DIR/backup/q46"
echo "Cleanup complete"
