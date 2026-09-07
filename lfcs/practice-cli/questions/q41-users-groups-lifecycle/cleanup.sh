#!/bin/bash
# Q41 accounts: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q41"

# Only what exists because of this question. ana, devs and qa are shared with
# Q42, Q43 and Q44: if the host already had them when setup ran, they belong to
# whichever question made them and deleting them here would break it.
if [[ "$(cat "$STATE/created-user-ana" 2>/dev/null)" == yes ]]; then
  userdel -r ana >/dev/null 2>&1
  rm -rf /home/ana
fi
[[ "$(cat "$STATE/created-user-svc-batch" 2>/dev/null)" == yes ]] && userdel -r svc-batch >/dev/null 2>&1

if [[ -f "$STATE/created-bob" ]]; then
  userdel -r bob >/dev/null 2>&1
  echo "The bob account created by setup has been removed."
else
  usermod -U bob >/dev/null 2>&1
  echo "bob existed before setup ran, so the account was unlocked and kept."
fi

# Groups last: a group that is still some account's primary group cannot go.
[[ "$(cat "$STATE/created-group-devs" 2>/dev/null)" == yes ]] && groupdel devs >/dev/null 2>&1
[[ "$(cat "$STATE/created-group-qa" 2>/dev/null)" == yes ]] && groupdel qa >/dev/null 2>&1

rm -rf "${LFCS_STATE_DIR:?}/q41"

echo "Cleanup complete. ana, svc-batch and the devs and qa groups were removed only"
echo "where the host did not already have them when setup ran."
