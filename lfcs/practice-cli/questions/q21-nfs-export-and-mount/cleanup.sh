#!/bin/bash
# Q21 NFS: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q21"
UNIT=$(cat "$STATE/unit" 2>/dev/null)
[[ -n "$UNIT" ]] || { UNIT=nfs-server; [[ "$(distro)" == ubuntu ]] && UNIT=nfs-kernel-server; }

umount -f /mnt/share >/dev/null 2>&1
umount -l /mnt/share >/dev/null 2>&1

fstab_drop_target /mnt/share
restore_file /etc/exports q21
for f in /etc/exports.d/*.exports; do [[ -e "$f" ]] && restore_file "$f" q21; done
exportfs -ra >/dev/null 2>&1
systemctl daemon-reload >/dev/null 2>&1

del_netns_peer nfs-peer

rmdir /mnt/share >/dev/null 2>&1
rm -rf /srv/share

if [[ "$(cat "$STATE/unit-enabled" 2>/dev/null)" == enabled ]]; then
  systemctl enable --now "$UNIT" >/dev/null 2>&1
else
  systemctl disable --now "$UNIT" >/dev/null 2>&1
fi

rm -rf "${LFCS_STATE_DIR:?}/q21"

echo "Cleanup complete."
echo "  /mnt/share is unmounted, /etc/exports and /etc/fstab are restored, /srv/share is gone,"
echo "  the peer namespace is deleted and $UNIT is back the way setup found it."
