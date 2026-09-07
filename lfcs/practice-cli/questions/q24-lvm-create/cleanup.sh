#!/bin/bash
# Q24 LVM from scratch: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q24"

umount /app 2>/dev/null

fstab_drop_target /app

# Tear LVM down in the only order that works: volumes, group, labels.
if vgs vg_data >/dev/null 2>&1; then
  for lv in $(lvs --noheadings -o lv_name vg_data 2>/dev/null | tr -d ' '); do
    umount "/dev/vg_data/$lv" 2>/dev/null
    lvchange -an "vg_data/$lv" >/dev/null 2>&1
    lvremove -f "vg_data/$lv" >/dev/null 2>&1
  done
  vgremove -f vg_data >/dev/null 2>&1
fi
while read -r d; do
  [[ -b "$d" ]] || continue
  pvremove -ff -y "$d" >/dev/null 2>&1
  wipefs -aq "$d" 2>/dev/null
done < <(cat "$STATE/devices" 2>/dev/null)

free_loop_disk d24a
free_loop_disk d24b
rmdir /app 2>/dev/null
rm -rf "${LFCS_STATE_DIR:?}/q24"

echo "Cleanup complete. /app unmounted, lv_app and vg_data removed, PV labels cleared, /etc/fstab restored, loop disks d24a and d24b released."
