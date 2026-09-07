#!/bin/bash
# Q31 disk-full triage: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q31"
MP=/srv/data

# Kill the holder first: while it lives, the filesystem cannot be unmounted.
pkill -f lfcs-logwriter >/dev/null 2>&1
sleep 1
umount "$MP" 2>/dev/null

if [[ -f /etc/fstab ]]; then
  awk -v t="$MP" '$1 ~ /^#/ || $2 != t' /etc/fstab > /tmp/lfcs-q31-fstab &&
    cat /tmp/lfcs-q31-fstab > /etc/fstab
  rm -f /tmp/lfcs-q31-fstab
fi
restore_file /etc/fstab q31

free_loop_disk d31
rm -rf "$COURSE_DIR/31"
findmnt -no TARGET "$MP" >/dev/null 2>&1 || rm -rf "$MP"
rm -rf "${LFCS_STATE_DIR:?}/q31"

echo "Cleanup complete. The lfcs-logwriter holder killed, $MP unmounted and removed, /etc/fstab restored, loop disk d31 released, $COURSE_DIR/31 removed."
