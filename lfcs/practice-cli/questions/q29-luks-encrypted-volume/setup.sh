#!/bin/bash
# Q29 LUKS: one bare block device, no mapping called secret, no key file, and
# neither /etc/crypttab nor /etc/fstab mentioning any of it.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q29"
mkdir -p "$STATE"

command -v cryptsetup >/dev/null 2>&1 || pkg_install cryptsetup
if ! command -v cryptsetup >/dev/null 2>&1; then
  echo "cryptsetup is missing and could not be installed. Nothing was changed."
  exit 1
fi

# Claimed by a *different* question. This question's own record is excluded,
# so re-running setup keeps the same device instead of quietly dropping to a
# loop file the second time.
claimed() {
  grep -lxF "$1" "$LFCS_STATE_DIR"/q*/devices 2>/dev/null | grep -qv "/q29/devices"
}

backup_file /etc/fstab q29
backup_file /etc/crypttab q29

umount /mnt/secret 2>/dev/null
cryptsetup close secret 2>/dev/null
rm -f /root/secret.key
if [[ -f /etc/fstab ]]; then
  awk '$1 ~ /^#/ || $2 != "/mnt/secret"' /etc/fstab > "$STATE/fstab.tmp" &&
    cat "$STATE/fstab.tmp" > /etc/fstab
  rm -f "$STATE/fstab.tmp"
fi
if [[ -f /etc/crypttab ]]; then
  awk '$1 ~ /^#/ || $1 != "secret"' /etc/crypttab > "$STATE/crypttab.tmp" &&
    cat "$STATE/crypttab.tmp" > /etc/crypttab
  rm -f "$STATE/crypttab.tmp"
fi

DEV=$(spare_disk 2>/dev/null)
if [[ -z "$DEV" ]] || claimed "$DEV"; then
  DEV=$(make_loop_disk d29 1024)
fi
if [[ -z "$DEV" || ! -b "$DEV" ]]; then
  echo "No spare block device and no free loop device. Cannot set up this question."
  exit 1
fi

for p in $(lsblk -lnpo NAME,TYPE "$DEV" 2>/dev/null | awk '$2=="part" {print $1}'); do
  umount "$p" 2>/dev/null
  wipefs -aq "$p" 2>/dev/null
done
wipefs -aq "$DEV" 2>/dev/null

echo "$DEV" > "$STATE/devices"
echo /mnt/secret > "$STATE/mountpoint"
mkdir -p /mnt/secret

echo "Setup complete."
echo "  Spare device: $DEV ($(lsblk -dno SIZE "$DEV" | tr -d ' '), no filesystem, no LUKS header)"
echo "  There is no /dev/mapper/secret, no /root/secret.key, and neither /etc/crypttab nor /etc/fstab mentions them."
echo "  Wanted: LUKS on $DEV, key file /root/secret.key mode 600, mapping 'secret', ext4 at /mnt/secret, both files written."
echo "  Remember that luksFormat destroys the device and wants YES in capitals."
