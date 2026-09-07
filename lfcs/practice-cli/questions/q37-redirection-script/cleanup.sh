#!/bin/bash
# Q37 redirection: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

rm -rf "${COURSE_DIR:?}/37"

echo "Cleanup complete. $COURSE_DIR/37, the script and both output files are gone."
