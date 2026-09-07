#!/bin/bash
# Q23 partition and persistent mount: hand the candidate one genuinely spare
# block device, and make sure nothing already mounts /data or claims the disk.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q23"
mkdir -p "$STATE"

# /data is also used by Q31. Refuse rather than mount over another question.
other=$(grep -lxF /data "$LFCS_STATE_DIR"/q*/mountpoint 2>/dev/null | grep -v '/q23/mountpoint')
if [[ -n "$other" ]]; then
  echo "/data is already claimed by another question ($other)."
  echo "Clean that question up first, then run this setup again."
  exit 1
fi

fstab_drop_target() {   # delete every fstab line whose mount point is $1
  local t="$1"
  [[ -f /etc/fstab ]] || return 0
  awk -v t="$t" '$1 ~ /^#/ || $2 != t' /etc/fstab > "$STATE/fstab.tmp" &&
    cat "$STATE/fstab.tmp" > /etc/fstab
  rm -f "$STATE/fstab.tmp"
}

# Claimed by a *different* question. This question's own record is excluded,
# so re-running setup keeps the same device instead of quietly dropping to a
# loop file the second time.
claimed() {
  grep -lxF "$1" "$LFCS_STATE_DIR"/q*/devices 2>/dev/null | grep -qv "/q23/devices"
}

backup_file /etc/fstab q23
umount /data 2>/dev/null
fstab_drop_target /data
# Never delete the directory while something is still mounted on it.
findmnt -no TARGET /data >/dev/null 2>&1 || rm -rf /data

# A real disk behaves in lsblk exactly as it does in the exam, so prefer one.
# spare_disk only returns a device with no filesystem, no mount and no
# partitions; never widen that test. Fall back to a loop file otherwise.
DEV=$(spare_disk 2>/dev/null)
if [[ -z "$DEV" ]] || claimed "$DEV"; then
  DEV=$(make_loop_disk d23 2048)
  KIND=loop
else
  KIND=disk
fi

if [[ -z "$DEV" || ! -b "$DEV" ]]; then
  echo "No spare block device and no free loop device. Cannot set up this question."
  exit 1
fi

# Clear anything left from an earlier attempt so the task starts from nothing.
for p in $(lsblk -lnpo NAME,TYPE "$DEV" 2>/dev/null | awk '$2=="part" {print $1}'); do
  umount "$p" 2>/dev/null
  wipefs -aq "$p" 2>/dev/null
done
wipefs -aq "$DEV" 2>/dev/null
partprobe "$DEV" 2>/dev/null

echo "$DEV" > "$STATE/devices"
echo "$KIND" > "$STATE/kind"
echo /data > "$STATE/mountpoint"

echo "Setup complete."
echo "  Spare device: $DEV ($(lsblk -dno SIZE "$DEV" | tr -d ' '), $KIND)"
echo "  It has no partition table, no filesystem and no mount point. Confirm with: lsblk -f $DEV"
echo "  Wanted: one partition, ext4 labelled 'data', mounted at /data with noatime, in fstab by UUID."
echo "  Touch no other disk."
