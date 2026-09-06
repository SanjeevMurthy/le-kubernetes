#!/bin/bash
# Q6 apiserver hardening: restore the original static pod manifest.
source "$(dirname "$0")/../../lib/env.sh"
restore_file "$KAS_MANIFEST" q06
wait_apiserver
echo "Cleanup complete"
