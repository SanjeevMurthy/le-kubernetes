#!/bin/bash
# Q21 NFS: create the directory to export, start the NFS server without enabling
# it, build a peer on 10.99.21.0/24 so the export can be proven over the network,
# and take any export or fstab line for this share back out.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q21"
mkdir -p "$STATE"
NS=nfs-peer
HOSTIP=10.99.21.1

if [[ "$(distro)" == ubuntu ]]; then
  UNIT=nfs-kernel-server
  PKG=nfs-kernel-server
else
  UNIT=nfs-server
  PKG=nfs-utils
fi
command -v exportfs >/dev/null 2>&1 || pkg_install "$PKG"
if ! command -v exportfs >/dev/null 2>&1; then
  echo "The NFS server tools could not be installed. Install $PKG and run setup again."
  exit 1
fi
echo "$UNIT" > "$STATE/unit"

PEERIP=$(make_netns_peer "$NS" 21)

mkdir -p /srv/share
printf 'nfs-marker-ok\n' > /srv/share/marker
chmod 755 /srv/share

backup_file /etc/exports q21
backup_file /etc/fstab q21

# Undo an earlier attempt: unmount, then take the lines back out of both files.
umount -f /mnt/share >/dev/null 2>&1
sed -i -E '\%[[:space:]]/mnt/share[[:space:]]%d' /etc/fstab
sed -i -E '\%^[[:space:]]*/srv/share[[:space:]]%d' /etc/exports
for f in /etc/exports.d/*.exports; do
  [[ -f "$f" ]] || continue
  backup_file "$f" q21
  sed -i -E '\%^[[:space:]]*/srv/share[[:space:]]%d' "$f"
done
exportfs -ra >/dev/null 2>&1
systemctl daemon-reload >/dev/null 2>&1

# Record the unit's boot state before anything changes it, so cleanup can put it
# back. Then start the server but leave it disabled: the task asks the candidate
# to make it start at boot, which is only real work if setup has not done it.
[[ -f "$STATE/unit-enabled" ]] || systemctl is-enabled "$UNIT" > "$STATE/unit-enabled" 2>/dev/null
systemctl disable "$UNIT" >/dev/null 2>&1
systemctl start "$UNIT" >/dev/null 2>&1

# Record whether the fstab was already clean, so a pre-existing warning that has
# nothing to do with this question is not counted against the candidate.
FSTAB_OK=no
findmnt --verify >/dev/null 2>&1 && FSTAB_OK=yes
echo "$FSTAB_OK" > "$STATE/fstab-ok"

# Record whether showmount answers at all, so the peer test has a control.
SHOWMOUNT=no
showmount -e "$HOSTIP" >/dev/null 2>&1 && SHOWMOUNT=yes
echo "$SHOWMOUNT" > "$STATE/showmount"

echo "Setup complete."
BOOTSTATE=$(systemctl is-enabled "$UNIT" 2>/dev/null)
echo "  Server unit:      $UNIT ($(systemctl is-active "$UNIT" 2>/dev/null))"
echo "  At boot:          $UNIT is ${BOOTSTATE:-unknown}, so it would not come back after a reboot"
echo "  Directory:        /srv/share, containing marker"
echo "  This host:        $HOSTIP, peer $PEERIP in namespace $NS"
echo "  Export wanted:    /srv/share to 10.0.0.0/8, rw, sync, no_root_squash"
echo "  Mount wanted:     $HOSTIP:/srv/share at /mnt/share, in /etc/fstab with _netdev"
echo "  Current exports:  $(exportfs -s 2>/dev/null | tr '\n' ' ' | cut -c1-140)"
echo "  Mount 10.99.21.1, not localhost: 127.0.0.1 is not inside 10.0.0.0/8."
[[ "$FSTAB_OK" == yes ]] || echo "  Note: findmnt --verify already reports a problem in /etc/fstab, so it is not graded."
