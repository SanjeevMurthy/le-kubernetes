#!/bin/bash
# Q23 partition and persistent mount: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q23"
DEV=$(head -1 "$STATE/devices" 2>/dev/null)

umount /data 2>/dev/null

fstab_drop_target /data

if [[ -n "$DEV" && -b "$DEV" ]]; then
  for p in $(lsblk -lnpo NAME,TYPE "$DEV" 2>/dev/null | awk '$2=="part" {print $1}'); do
    umount "$p" 2>/dev/null
    wipefs -aq "$p" 2>/dev/null
  done
  wipefs -aq "$DEV" 2>/dev/null
  partprobe "$DEV" 2>/dev/null
fi

free_loop_disk d23
rmdir /data 2>/dev/null
rm -rf "${LFCS_STATE_DIR:?}/q23"

echo "Cleanup complete. /data unmounted and removed, its /etc/fstab line removed, $DEV wiped, loop disk d23 released."
