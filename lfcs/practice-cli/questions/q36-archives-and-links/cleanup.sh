#!/bin/bash
# Q36 archives and links: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

rm -rf "${COURSE_DIR:?}/36"
rm -rf "${LFCS_STATE_DIR:?}/q36"

echo "Cleanup complete. $COURSE_DIR/36 and its archives, links and extracted tree are gone."
