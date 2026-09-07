#!/bin/bash
# Q37 apiserver bad volume: restore the original manifest and wait for the
# control plane to come back before returning.
source "$(dirname "$0")/../../lib/env.sh"
restore_file "$KAS_MANIFEST" q37
wait_apiserver
rm -f "$CKS_STATE_DIR/q37.fault"
echo "Cleanup complete"
