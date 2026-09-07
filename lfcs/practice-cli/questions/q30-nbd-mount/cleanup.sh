#!/bin/bash
# Q30 NBD: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q30"

umount /mnt/nbd 2>/dev/null
nbd-client -d /dev/nbd0 >/dev/null 2>&1
modprobe -r nbd 2>/dev/null

# Kills the nbd-server running inside the namespace and removes the veth pair.
del_netns_peer nbd-peer

if [[ -f /etc/fstab ]]; then
  awk '$1 ~ /^#/ || $2 != "/mnt/nbd"' /etc/fstab > /tmp/lfcs-q30-fstab &&
    cat /tmp/lfcs-q30-fstab > /etc/fstab
  rm -f /tmp/lfcs-q30-fstab
fi
restore_file /etc/fstab q30
rm -f /etc/modules-load.d/nbd.conf

umount "$STATE/mnt" 2>/dev/null
rm -rf "$COURSE_DIR/30"
findmnt -no TARGET /mnt/nbd >/dev/null 2>&1 || rm -rf /mnt/nbd
rm -rf "${LFCS_STATE_DIR:?}/q30"

echo "Cleanup complete. /mnt/nbd unmounted, /dev/nbd0 disconnected, nbd module removed, the nbd-peer namespace and its nbd-server deleted, /etc/fstab restored, /etc/modules-load.d/nbd.conf and the export image removed."
