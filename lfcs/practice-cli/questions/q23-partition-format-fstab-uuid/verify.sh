#!/bin/bash
# Q23 partition and persistent mount: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

STATE="$LFCS_STATE_DIR/q23"
DEV=$(head -1 "$STATE/devices" 2>/dev/null)

if [[ -z "$DEV" ]]; then
  echo "  FAIL: no device recorded. Run setup first."
  echo ""; echo "Results: 0 passed, 1 failed"; exit 1
fi

fstab_verify_clean() {
  local out
  out=$(findmnt --verify 2>&1)
  ! grep -qiE '[1-9][0-9]* (parse )?error' <<<"$out"
}

PARTS=$(lsblk -lnpo NAME,TYPE "$DEV" 2>/dev/null | awk '$2=="part" {print $1}')
NPARTS=$(printf '%s\n' "$PARTS" | grep -c .)
PART=$(printf '%s\n' "$PARTS" | head -1)

echo "Checking the partition..."
check_eq "exactly one partition on $DEV" "1" "$NPARTS"

echo "Checking the filesystem..."
check_eq "the partition holds an ext4 filesystem" "ext4" "$(blkid -s TYPE -o value "$PART" 2>/dev/null)"
check_eq "its filesystem label is 'data'" "data" "$(blkid -s LABEL -o value "$PART" 2>/dev/null)"

echo "Checking the live mount..."
check_eq "/data is mounted from $PART" "$(readlink -f "$PART" 2>/dev/null)" \
  "$(readlink -f "$(findmnt -no SOURCE /data 2>/dev/null)" 2>/dev/null)"
check_eq "/data is ext4" "ext4" "$(findmnt -no FSTYPE /data 2>/dev/null)"
check "/data is mounted with noatime" \
  bash -c 'findmnt -no OPTIONS /data 2>/dev/null | tr "," "\n" | grep -qx noatime'

echo "Checking the mount survives a reboot..."
UUID=$(blkid -s UUID -o value "$PART" 2>/dev/null)
if [[ -z "$UUID" ]]; then
  echo "  FAIL: the partition has no filesystem UUID, so no fstab line can be correct"
  FAIL=$((FAIL + 1))
else
  check_persisted "/etc/fstab mounts /data by UUID=$UUID" \
    "^[^#]*UUID=\"?'?$UUID'?\"?[[:space:]]+/data[[:space:]]" /etc/fstab
fi
check_persisted "the /etc/fstab line for /data carries noatime" \
  '^[^#]*[[:space:]]/data[[:space:]].*noatime' /etc/fstab
check "/etc/fstab parses cleanly (findmnt --verify)" fstab_verify_clean

summary
