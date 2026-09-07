#!/bin/bash
# Q34 find and permissions: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

rm -rf "${COURSE_DIR:?}/34"
rm -rf "${LFCS_STATE_DIR:?}/q34"

userdel -r auditor >/dev/null 2>&1
groupdel devs >/dev/null 2>&1

echo "Cleanup complete. $COURSE_DIR/34, the auditor account and the devs group are gone."
