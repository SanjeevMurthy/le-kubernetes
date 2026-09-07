#!/bin/bash
# Q41 accounts: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q41"

userdel -r ana >/dev/null 2>&1
userdel -r svc-batch >/dev/null 2>&1
rm -rf /home/ana

if [[ -f "$STATE/created-bob" ]]; then
  userdel -r bob >/dev/null 2>&1
  echo "The bob account created by setup has been removed."
else
  usermod -U bob >/dev/null 2>&1
  echo "bob existed before setup ran, so the account was unlocked and kept."
fi

groupdel devs >/dev/null 2>&1
groupdel qa >/dev/null 2>&1
rm -rf "${LFCS_STATE_DIR:?}/q41"

echo "Cleanup complete. ana, svc-batch and the devs and qa groups are gone."
