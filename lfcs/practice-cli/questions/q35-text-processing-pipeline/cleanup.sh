#!/bin/bash
# Q35 text processing: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

rm -rf "${COURSE_DIR:?}/35"
rm -rf "${LFCS_STATE_DIR:?}/q35"

echo "Cleanup complete. $COURSE_DIR/35 and the recorded answers under $LFCS_STATE_DIR/q35 are gone."
