#!/bin/bash
# Q28 RAID 1: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

# Machine-readable output only: never let a locale reformat a number.
export LC_ALL=C

STATE="$LFCS_STATE_DIR/q28"
if [[ ! -f "$STATE/devices" ]]; then
  echo "  FAIL: no devices recorded. Run setup first."
  echo ""; echo "Results: 0 passed, 1 failed"; exit 1
fi
MDCONF=$(cat "$STATE/mdconf" 2>/dev/null)
DEV_A=$(sed -n '1p' "$STATE/devices")
DEV_B=$(sed -n '2p' "$STATE/devices")

fstab_verify_clean() {
  local out
  out=$(findmnt --verify 2>&1)
  ! grep -qiE '[1-9][0-9]* (parse )?error' <<<"$out"
}

echo "Checking the array..."
check "/dev/md0 exists" test -b /dev/md0
check_eq "it is a RAID 1 mirror" "raid1" \
  "$(mdadm --detail --export /dev/md0 2>/dev/null | sed -n 's/^MD_LEVEL=//p')"
check_eq "it has 2 RAID devices" "2" "$(cat /sys/block/md0/md/raid_disks 2>/dev/null)"
check_eq "the mirror is not degraded" "0" "$(cat /sys/block/md0/md/degraded 2>/dev/null)"

MEMBERS=$(ls /sys/block/md0/slaves 2>/dev/null | sort | tr '\n' ' ')
WANT=$(printf '%s\n%s\n' "$(basename "$DEV_A")" "$(basename "$DEV_B")" | sort | tr '\n' ' ')
check_eq "both spare devices are the members" "$WANT" "$MEMBERS"

echo "Checking the filesystem and the live mount..."
check_eq "/mnt/raid is mounted from /dev/md0" "$(readlink -f /dev/md0 2>/dev/null)" \
  "$(readlink -f "$(findmnt -no SOURCE /mnt/raid 2>/dev/null)" 2>/dev/null)"
check_eq "/mnt/raid is ext4" "ext4" "$(findmnt -no FSTYPE /mnt/raid 2>/dev/null)"

echo "Checking the array is defined for the next boot..."
MDUUID=$(mdadm --detail --export /dev/md0 2>/dev/null | sed -n 's/^MD_UUID=//p')
if [[ -n "$MDUUID" ]]; then
  PAT="^ARRAY[[:space:]].*(UUID=$MDUUID|/dev/md/?0([[:space:]]|$))"
else
  PAT='^ARRAY[[:space:]].*/dev/md/?0([[:space:]]|$)'
fi
check_persisted "the array has an ARRAY line in the mdadm configuration" "$PAT" \
  "$MDCONF" /etc/mdadm/mdadm.conf /etc/mdadm.conf

echo "Checking the mount survives a reboot..."
UUID=$(blkid -s UUID -o value /dev/md0 2>/dev/null)
PAT2='^[^#]*/dev/md/?0[[:space:]]+/mnt/raid[[:space:]]'
[[ -n "$UUID" ]] && PAT2="$PAT2|^[^#]*UUID=\"?'?$UUID'?\"?[[:space:]]+/mnt/raid[[:space:]]"
check_persisted "/etc/fstab mounts /mnt/raid from the array" "$PAT2" /etc/fstab
check "/etc/fstab parses cleanly (findmnt --verify)" fstab_verify_clean

summary
