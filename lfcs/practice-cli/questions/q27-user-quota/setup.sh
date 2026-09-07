#!/bin/bash
# Q27 quotas: a plain ext4 filesystem on /quota, mounted and in fstab with no
# quota option anywhere, plus the user the limits will be set for.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q27"
mkdir -p "$STATE"

command -v setquota >/dev/null 2>&1 || pkg_install quota
if ! command -v setquota >/dev/null 2>&1 || ! command -v quotaon >/dev/null 2>&1; then
  echo "The quota tools are missing and could not be installed."
  echo "Install the 'quota' package, then run this setup again. Nothing was changed."
  exit 1
fi

# Claimed by a *different* question. This question's own record is excluded,
# so re-running setup keeps the same device instead of quietly dropping to a
# loop file the second time.
claimed() {
  grep -lxF "$1" "$LFCS_STATE_DIR"/q*/devices 2>/dev/null | grep -qv "/q27/devices"
}

backup_file /etc/fstab q27
quotaoff -u /quota 2>/dev/null
umount /quota 2>/dev/null
if [[ -f /etc/fstab ]]; then
  awk '$1 ~ /^#/ || $2 != "/quota"' /etc/fstab > "$STATE/fstab.tmp" &&
    cat "$STATE/fstab.tmp" > /etc/fstab
  rm -f "$STATE/fstab.tmp"
fi

DEV=$(spare_disk 2>/dev/null)
if [[ -z "$DEV" ]] || claimed "$DEV"; then
  DEV=$(make_loop_disk d27 1024)
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
mkfs.ext4 -q -F -L quotafs "$DEV" >/dev/null 2>&1

mkdir -p /quota
# Deliberately mounted with plain defaults: the candidate has to add usrquota.
UUID=$(blkid -s UUID -o value "$DEV")
echo "UUID=$UUID  /quota  ext4  defaults  0  2" >> /etc/fstab
mount /quota || { echo "Could not mount /quota."; exit 1; }
chmod 1777 /quota

if getent passwd qa >/dev/null 2>&1; then
  echo no > "$STATE/created-user"
else
  useradd -m qa >/dev/null 2>&1
  echo yes > "$STATE/created-user"
fi

echo "$DEV" > "$STATE/devices"
echo /quota > "$STATE/mountpoint"

echo "Setup complete."
echo "  $DEV is ext4, mounted at /quota, and in /etc/fstab by UUID with plain 'defaults'."
echo "  Current options: $(findmnt -no OPTIONS /quota)"
echo "  User qa exists. The quota tools are installed."
echo "  Wanted: user quotas on /quota now and after a reboot, and qa limited to 51200 soft, 102400 hard blocks."
