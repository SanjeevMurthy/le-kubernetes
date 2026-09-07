#!/bin/bash
# Q25 online extend: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q25"
MP=/var/lib/lfcs-logs

umount "$MP" 2>/dev/null

fstab_drop_target "$MP"

if vgs vg_ext >/dev/null 2>&1; then
  for lv in $(lvs --noheadings -o lv_name vg_ext 2>/dev/null | tr -d ' '); do
    umount "/dev/vg_ext/$lv" 2>/dev/null
    lvchange -an "vg_ext/$lv" >/dev/null 2>&1
    lvremove -f "vg_ext/$lv" >/dev/null 2>&1
  done
  vgremove -f vg_ext >/dev/null 2>&1
fi
while read -r d; do
  [[ -b "$d" ]] || continue
  pvremove -ff -y "$d" >/dev/null 2>&1
  wipefs -aq "$d" 2>/dev/null
done < <(cat "$STATE/devices" 2>/dev/null)

free_loop_disk d25a
free_loop_disk d25b
# Only remove the directory when nothing is mounted on it.
findmnt -no TARGET "$MP" >/dev/null 2>&1 || rm -rf "$MP"
rm -rf "${LFCS_STATE_DIR:?}/q25"

echo "Cleanup complete. $MP unmounted and removed, lv_logs and vg_ext removed, PV labels cleared, /etc/fstab restored, loop disks d25a and d25b released."
