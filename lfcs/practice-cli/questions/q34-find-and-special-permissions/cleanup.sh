#!/bin/bash
# Q34 find and permissions: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q34"

rm -rf "${COURSE_DIR:?}/34"

# Only what setup created. If the host already had an auditor account or a devs
# group, they were not this question's to make and are not its to delete.
[[ "$(cat "$STATE/created-user" 2>/dev/null)" == yes ]] && userdel -r auditor >/dev/null 2>&1
[[ "$(cat "$STATE/created-group" 2>/dev/null)" == yes ]] && groupdel devs >/dev/null 2>&1

rm -rf "${LFCS_STATE_DIR:?}/q34"

echo "Cleanup complete. $COURSE_DIR/34 is gone. The auditor account and the devs group were removed only if this question created them."
