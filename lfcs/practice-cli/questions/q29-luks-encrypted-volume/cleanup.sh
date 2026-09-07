#!/bin/bash
# Q29 LUKS: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q29"
DEV=$(head -1 "$STATE/devices" 2>/dev/null)

umount /mnt/secret 2>/dev/null
cryptsetup close secret 2>/dev/null

if [[ -f /etc/fstab ]]; then
  awk '$1 ~ /^#/ || $2 != "/mnt/secret"' /etc/fstab > /tmp/lfcs-q29-fstab &&
    cat /tmp/lfcs-q29-fstab > /etc/fstab
  rm -f /tmp/lfcs-q29-fstab
fi
restore_file /etc/fstab q29

if [[ -f /etc/crypttab ]]; then
  awk '$1 ~ /^#/ || $1 != "secret"' /etc/crypttab > /tmp/lfcs-q29-crypttab &&
    cat /tmp/lfcs-q29-crypttab > /etc/crypttab
  rm -f /tmp/lfcs-q29-crypttab
fi
restore_file /etc/crypttab q29

rm -f /root/secret.key
if [[ -n "$DEV" && -b "$DEV" ]]; then
  cryptsetup luksErase -q "$DEV" >/dev/null 2>&1
  wipefs -aq "$DEV" 2>/dev/null
fi
free_loop_disk d29
findmnt -no TARGET /mnt/secret >/dev/null 2>&1 || rm -rf /mnt/secret
rm -rf "${LFCS_STATE_DIR:?}/q29"

echo "Cleanup complete. /mnt/secret unmounted, mapping 'secret' closed, /root/secret.key deleted, LUKS header erased from $DEV, /etc/fstab and /etc/crypttab restored, loop disk d29 released."
