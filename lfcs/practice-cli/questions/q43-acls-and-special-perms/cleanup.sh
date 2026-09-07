#!/bin/bash
# Q43 ACLs: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q43"

rm -rf /srv/projects

# Only what setup created. ana, devs and qa are shared with Q41, Q42 and Q44: if
# the host already had them when setup ran, they belong to another question and
# deleting them here would break it.
[[ "$(cat "$STATE/created-user-ana" 2>/dev/null)" == yes ]] && userdel -r ana >/dev/null 2>&1
[[ "$(cat "$STATE/created-user-qauser" 2>/dev/null)" == yes ]] && userdel -r qauser >/dev/null 2>&1

# Groups last: a group that is still some account's primary group cannot go.
[[ "$(cat "$STATE/created-group-devs" 2>/dev/null)" == yes ]] && groupdel devs >/dev/null 2>&1
[[ "$(cat "$STATE/created-group-qa" 2>/dev/null)" == yes ]] && groupdel qa >/dev/null 2>&1

rm -rf "${LFCS_STATE_DIR:?}/q43"

echo "Cleanup complete. /srv/projects is gone. The ana and qauser accounts and the"
echo "devs and qa groups were removed only if this question created them."
