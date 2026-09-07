#!/bin/bash
# Q25 online extend: a small full volume group with a mounted 500 MB volume, and
# a second device that is deliberately left outside the group. Sizes are fixed,
# so this uses loop-backed files rather than whatever spare disk the host has.
source "$(dirname "$0")/../../lib/env.sh"

# Machine-readable output only: never let a locale reformat a number.
export LC_ALL=C
require_root "$@"

STATE="$LFCS_STATE_DIR/q25"
MP=/var/lib/lfcs-logs
mkdir -p "$STATE"

backup_file /etc/fstab q25
umount "$MP" 2>/dev/null
if [[ -f /etc/fstab ]]; then
  awk -v t="$MP" '$1 ~ /^#/ || $2 != t' /etc/fstab > "$STATE/fstab.tmp" &&
    cat "$STATE/fstab.tmp" > /etc/fstab
  rm -f "$STATE/fstab.tmp"
fi

DEV_A=$(make_loop_disk d25a 600)
DEV_B=$(make_loop_disk d25b 1024)
if [[ ! -b "$DEV_A" || ! -b "$DEV_B" ]]; then
  echo "Could not create two loop-backed disks. Check that losetup has free devices."
  exit 1
fi

if vgs vg_ext >/dev/null 2>&1; then
  for lv in $(lvs --noheadings -o lv_name vg_ext 2>/dev/null | tr -d ' '); do
    umount "/dev/vg_ext/$lv" 2>/dev/null
    lvchange -an "vg_ext/$lv" >/dev/null 2>&1
    lvremove -f "vg_ext/$lv" >/dev/null 2>&1
  done
  vgremove -f vg_ext >/dev/null 2>&1
fi
for d in "$DEV_A" "$DEV_B"; do
  pvremove -ff -y "$d" >/dev/null 2>&1
  wipefs -aq "$d" 2>/dev/null
done

pvcreate -f -y "$DEV_A" >/dev/null 2>&1
vgcreate vg_ext "$DEV_A" >/dev/null 2>&1
lvcreate -L 500M -n lv_logs vg_ext >/dev/null 2>&1
mkfs.ext4 -q -F /dev/vg_ext/lv_logs >/dev/null 2>&1
mkdir -p "$MP"
mount /dev/vg_ext/lv_logs "$MP" || { echo "Could not mount the log volume."; exit 1; }

{
  echo "lfcs application log, do not lose this file"
  date -u +'started %Y-%m-%dT%H:%M:%SZ'
  head -c 4096 /dev/urandom | od -An -tx1 | tr -d ' \n'
  echo
} > "$MP/app.log"
sha256sum "$MP/app.log" | awk '{print $1}' > "$STATE/marker.sha"

UUID=$(blkid -s UUID -o value /dev/vg_ext/lv_logs)
echo "UUID=$UUID  $MP  ext4  defaults  0  2" >> /etc/fstab

MID=$(findmnt -no ID "$MP" 2>/dev/null | tr -d ' ')
[[ -z "$MID" ]] && MID=unknown
echo "$MID" > "$STATE/mountid"
printf '%s\n%s\n' "$DEV_A" "$DEV_B" > "$STATE/devices"
echo "$MP" > "$STATE/mountpoint"

echo "Setup complete."
echo "  vg_ext holds one physical volume, $DEV_A, with almost no free extents left."
echo "  vg_ext/lv_logs is 500 MB, ext4, mounted at $MP, and listed in /etc/fstab by UUID."
echo "  $MP/app.log must survive unchanged."
echo "  Spare device, not yet part of any group: $DEV_B"
echo "  Wanted: lv_logs at 900 MB or more, with the filesystem grown to match, and $MP never unmounted."
