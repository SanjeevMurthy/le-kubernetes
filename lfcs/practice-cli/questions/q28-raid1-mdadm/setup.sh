#!/bin/bash
# Q28 RAID 1: two empty block devices, no md0 anywhere, nothing on /mnt/raid.
# Sizes are fixed so the mirror is predictable, hence loop-backed files.
source "$(dirname "$0")/../../lib/env.sh"

# Machine-readable output only: never let a locale reformat a number.
export LC_ALL=C
require_root "$@"

STATE="$LFCS_STATE_DIR/q28"
mkdir -p "$STATE"

if ! command -v mdadm >/dev/null 2>&1; then
  pkg_install mdadm
fi
if ! command -v mdadm >/dev/null 2>&1; then
  echo "mdadm is missing and could not be installed. Nothing was changed."
  exit 1
fi

MDCONF=/etc/mdadm.conf
[[ "$(distro)" == ubuntu ]] && MDCONF=/etc/mdadm/mdadm.conf
mkdir -p "$(dirname "$MDCONF")"

if [[ -f "$MDCONF" ]]; then echo yes > "$STATE/mdconf-existed"; else echo no > "$STATE/mdconf-existed"; fi
echo "$MDCONF" > "$STATE/mdconf"

backup_file /etc/fstab q28
backup_file "$MDCONF" q28

umount /mnt/raid 2>/dev/null
mdadm --stop /dev/md0 >/dev/null 2>&1
fstab_drop_target /mnt/raid
if [[ -f "$MDCONF" ]]; then
  grep -vE '^ARRAY[[:space:]].*(/dev/md/?0)([[:space:]]|$)' "$MDCONF" > "$STATE/mdconf.tmp" &&
    cat "$STATE/mdconf.tmp" > "$MDCONF"
  rm -f "$STATE/mdconf.tmp"
fi

DEV_A=$(make_loop_disk d28a 1024)
DEV_B=$(make_loop_disk d28b 1024)
if [[ ! -b "$DEV_A" || ! -b "$DEV_B" ]]; then
  echo "Could not create two loop-backed disks. Check that losetup has free devices."
  exit 1
fi
for d in "$DEV_A" "$DEV_B"; do
  mdadm --zero-superblock "$d" >/dev/null 2>&1
  wipefs -aq "$d" 2>/dev/null
done

printf '%s\n%s\n' "$DEV_A" "$DEV_B" > "$STATE/devices"
echo /mnt/raid > "$STATE/mountpoint"
mkdir -p /mnt/raid

echo "Setup complete."
echo "  Spare devices: $DEV_A and $DEV_B (1024 MB each, no filesystem, no RAID superblock)"
echo "  There is no /dev/md0 and $MDCONF has no ARRAY line for it."
echo "  Wanted: RAID 1 /dev/md0 across both, ext4, mounted at /mnt/raid, in fstab, and defined in $MDCONF."
echo "  Check the starting state with: cat /proc/mdstat"
