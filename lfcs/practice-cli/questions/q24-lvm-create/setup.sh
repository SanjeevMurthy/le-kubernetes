#!/bin/bash
# Q24 LVM from scratch: two empty block devices, no vg_data, nothing on /app.
# Loop-backed files are used here rather than spare_disk because the question
# depends on both devices being the same known size.
source "$(dirname "$0")/../../lib/env.sh"

# Machine-readable output only: never let a locale reformat a number.
export LC_ALL=C
require_root "$@"

STATE="$LFCS_STATE_DIR/q24"
mkdir -p "$STATE"

backup_file /etc/fstab q24
umount /app 2>/dev/null
fstab_drop_target /app

DEV_A=$(make_loop_disk d24a 1024)
DEV_B=$(make_loop_disk d24b 1024)
if [[ ! -b "$DEV_A" || ! -b "$DEV_B" ]]; then
  echo "Could not create two loop-backed disks. Check that losetup has free devices."
  exit 1
fi

# Remove anything an earlier attempt left behind, so the task starts from bare
# devices: logical volumes first, then the group, then the LVM labels.
if vgs vg_data >/dev/null 2>&1; then
  for lv in $(lvs --noheadings -o lv_name vg_data 2>/dev/null | tr -d ' '); do
    umount "/dev/vg_data/$lv" 2>/dev/null
    lvchange -an "vg_data/$lv" >/dev/null 2>&1
    lvremove -f "vg_data/$lv" >/dev/null 2>&1
  done
  vgremove -f vg_data >/dev/null 2>&1
fi
for d in "$DEV_A" "$DEV_B"; do
  pvremove -ff -y "$d" >/dev/null 2>&1
  wipefs -aq "$d" 2>/dev/null
done

printf '%s\n%s\n' "$DEV_A" "$DEV_B" > "$STATE/devices"
echo /app > "$STATE/mountpoint"
mkdir -p /app

echo "Setup complete."
echo "  Spare devices: $DEV_A and $DEV_B (1024 MB each, no partition table, no LVM label)"
echo "  Wanted: vg_data across both, extent size 16 MB, lv_app of 1.5 GB, ext4, mounted at /app, in fstab."
echo "  Confirm the starting state with: lsblk; pvs; vgs"
