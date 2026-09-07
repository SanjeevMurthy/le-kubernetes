#!/bin/bash
# Q27 quotas: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q27"
DEV=$(head -1 "$STATE/devices" 2>/dev/null)

quotaoff -u /quota 2>/dev/null
umount /quota 2>/dev/null

if [[ -f /etc/fstab ]]; then
  awk '$1 ~ /^#/ || $2 != "/quota"' /etc/fstab > /tmp/lfcs-q27-fstab &&
    cat /tmp/lfcs-q27-fstab > /etc/fstab
  rm -f /tmp/lfcs-q27-fstab
fi
restore_file /etc/fstab q27

if [[ -n "$DEV" && -b "$DEV" ]]; then
  wipefs -aq "$DEV" 2>/dev/null
fi
free_loop_disk d27

[[ "$(cat "$STATE/created-user" 2>/dev/null)" == yes ]] && userdel -r qa >/dev/null 2>&1

# Only remove the directory when nothing is mounted on it.
findmnt -no TARGET /quota >/dev/null 2>&1 || rm -rf /quota
rm -rf "${LFCS_STATE_DIR:?}/q27"

echo "Cleanup complete. Quotas off, /quota unmounted and removed, /etc/fstab restored, $DEV wiped, loop disk d27 released, user qa removed if this question created it."
