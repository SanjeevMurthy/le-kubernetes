#!/bin/bash
# Q23 apiserver crash recovery: restore the original manifest and wait for the
# control plane to come back before returning.
source "$(dirname "$0")/../../lib/env.sh"
restore_file "$KAS_MANIFEST" q23
wait_apiserver
rm -f "$CKS_STATE_DIR/q23.mode"
echo "Cleanup complete"
