#!/bin/bash
# Q02 process and I/O: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

pkill -f 'lfcs-reader' >/dev/null 2>&1
rm -rf "$COURSE_DIR/2"
rm -rf "${LFCS_STATE_DIR:?}/q02"

echo "Cleanup complete. Reader stopped, $COURSE_DIR/2 and its 200 MB file removed."
