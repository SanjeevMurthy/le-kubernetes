#!/bin/bash
# Q25 online extend: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

# Machine-readable output only: never let a locale reformat a number.
export LC_ALL=C

STATE="$LFCS_STATE_DIR/q25"
MP=/var/lib/lfcs-logs
DEV_B=$(sed -n '2p' "$STATE/devices" 2>/dev/null)

if [[ ! -f "$STATE/devices" ]]; then
  echo "  FAIL: no devices recorded. Run setup first."
  echo ""; echo "Results: 0 passed, 1 failed"; exit 1
fi

fstab_verify_clean() {
  local out
  out=$(findmnt --verify 2>&1)
  ! grep -qiE '[1-9][0-9]* (parse )?error' <<<"$out"
}

check_ge() {   # check_ge "label" minimum value
  if [[ -n "$3" ]] && awk -v a="$3" -v b="$2" 'BEGIN {exit !(a + 0 >= b + 0)}'; then
    echo "  PASS: $1 (got $3)"; PASS=$((PASS + 1))
  else
    echo "  FAIL: $1 (expected at least $2, got '$3')"; FAIL=$((FAIL + 1))
  fi
}

echo "Checking the volume group..."
check_eq "vg_ext now spans two physical volumes" "2" \
  "$(vgs --noheadings -o pv_count vg_ext 2>/dev/null | tr -d ' ')"
check_eq "the second device was added to vg_ext" "vg_ext" \
  "$(pvs --noheadings -o vg_name "$DEV_B" 2>/dev/null | tr -d ' ')"

echo "Checking the logical volume..."
check_ge "vg_ext/lv_logs is at least 900 MB" 900 \
  "$(lvs --noheadings --units m --nosuffix -o lv_size vg_ext/lv_logs 2>/dev/null | tr -d ' ')"

echo "Checking the filesystem itself grew, which lvs cannot tell you..."
check_ge "df reports at least 850M for $MP" 850 \
  "$(df -BM --output=size "$MP" 2>/dev/null | tail -1 | tr -dc '0-9')"

echo "Checking the volume stayed in service..."
check_eq "$MP is still mounted" "$MP" "$(findmnt -no TARGET "$MP" 2>/dev/null)"
WANT_ID=$(cat "$STATE/mountid" 2>/dev/null)
if [[ -n "$WANT_ID" && "$WANT_ID" != unknown ]]; then
  check_eq "$MP was never unmounted (same mount ID as at setup)" "$WANT_ID" \
    "$(findmnt -no ID "$MP" 2>/dev/null | tr -d ' ')"
else
  echo "  note: findmnt on this host has no ID column, so the unmount test is skipped"
fi
check_eq "app.log survived unchanged" "$(cat "$STATE/marker.sha" 2>/dev/null)" \
  "$(sha256sum "$MP/app.log" 2>/dev/null | awk '{print $1}')"

echo "Checking the mount still survives a reboot..."
UUID=$(blkid -s UUID -o value /dev/vg_ext/lv_logs 2>/dev/null)
if [[ -z "$UUID" ]]; then
  echo "  FAIL: vg_ext/lv_logs has no filesystem UUID, so the fstab line cannot be right"
  FAIL=$((FAIL + 1))
else
  check_persisted "/etc/fstab still mounts $MP by the volume's current UUID" \
    "^[^#]*UUID=\"?'?${UUID}'?\"?[[:space:]]+${MP}[[:space:]]" /etc/fstab
fi
check "/etc/fstab parses cleanly (findmnt --verify)" fstab_verify_clean

summary
