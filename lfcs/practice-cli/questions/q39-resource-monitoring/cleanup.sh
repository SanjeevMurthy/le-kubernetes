#!/bin/bash
# Q39 monitoring: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

pkill -f 'lfcs-burner' >/dev/null 2>&1
rm -rf "${COURSE_DIR:?}/39"

echo "Cleanup complete. The CPU burner is stopped and $COURSE_DIR/39 is gone."
