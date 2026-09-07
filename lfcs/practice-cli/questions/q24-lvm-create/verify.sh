#!/bin/bash
# Q24 LVM from scratch: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

# Machine-readable output only: never let a locale reformat a number.
export LC_ALL=C

STATE="$LFCS_STATE_DIR/q24"
if [[ ! -f "$STATE/devices" ]]; then
  echo "  FAIL: no devices recorded. Run setup first."
  echo ""; echo "Results: 0 passed, 1 failed"; exit 1
fi

fstab_verify_clean() {
  local out
  out=$(findmnt --verify 2>&1)
  ! grep -qiE '[1-9][0-9]* (parse )?error' <<<"$out"
}

echo "Checking the volume group..."
check "the volume group vg_data exists" vgs vg_data
check_eq "vg_data has an extent size of 16.00m" "16.00m" \
  "$(vgs --noheadings -o vg_extent_size vg_data 2>/dev/null | tr -d ' ')"
check_eq "vg_data spans both physical volumes" "2" \
  "$(vgs --noheadings -o pv_count vg_data 2>/dev/null | tr -d ' ')"

echo "Checking the logical volume..."
check "the logical volume vg_data/lv_app exists" lvs vg_data/lv_app
check_eq "lv_app is 1.50g" "1.50g" \
  "$(lvs --noheadings -o lv_size vg_data/lv_app 2>/dev/null | tr -d ' ')"

echo "Checking the live mount..."
check_eq "/app is mounted from vg_data/lv_app" "$(readlink -f /dev/vg_data/lv_app 2>/dev/null)" \
  "$(readlink -f "$(findmnt -no SOURCE /app 2>/dev/null)" 2>/dev/null)"
check_eq "/app is ext4" "ext4" "$(findmnt -no FSTYPE /app 2>/dev/null)"

echo "Checking the mount survives a reboot..."
UUID=$(blkid -s UUID -o value /dev/vg_data/lv_app 2>/dev/null)
PAT='^[^#]*(/dev/vg_data/lv_app|/dev/mapper/vg_data-lv_app)[[:space:]]+/app[[:space:]]'
[[ -n "$UUID" ]] && PAT="$PAT|^[^#]*UUID=\"?'?$UUID'?\"?[[:space:]]+/app[[:space:]]"
check_persisted "/etc/fstab mounts /app from the logical volume" "$PAT" /etc/fstab
check "/etc/fstab parses cleanly (findmnt --verify)" fstab_verify_clean

summary
