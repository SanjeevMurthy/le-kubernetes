#!/bin/bash
# Q27 quotas: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

# Machine-readable output only: never let a locale reformat a number.
export LC_ALL=C

STATE="$LFCS_STATE_DIR/q27"
if [[ ! -f "$STATE/devices" ]]; then
  echo "  FAIL: no device recorded. Run setup first."
  echo ""; echo "Results: 0 passed, 1 failed"; exit 1
fi

fstab_verify_clean() {
  local out
  out=$(findmnt --verify 2>&1)
  ! grep -qiE '[1-9][0-9]* (parse )?error' <<<"$out"
}

echo "Checking the mount option that everything else depends on..."
check "/quota is mounted with usrquota" \
  bash -c 'findmnt -no OPTIONS /quota 2>/dev/null | tr "," "\n" | grep -qx usrquota'

echo "Checking quotas are switched on..."
check "quotaon -p reports user quota on for /quota" \
  bash -c 'quotaon -p -u /quota 2>/dev/null | grep -qiE "user quota on .* is on"'

echo "Checking the limits for qa..."
QLINE=$(repquota -u /quota 2>/dev/null | awk '$1=="qa"')
check_eq "qa has a block soft limit of 51200" "51200" "$(awk '{print $4}' <<<"$QLINE")"
check_eq "qa has a block hard limit of 102400" "102400" "$(awk '{print $5}' <<<"$QLINE")"
check_eq "qa has no inode limits" "0 0" "$(awk '{print $7, $8}' <<<"$QLINE")"

echo "Checking the quota option survives a reboot..."
check_persisted "/etc/fstab mounts /quota with usrquota" \
  '^[^#]*[[:space:]]/quota[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]*usrquota' /etc/fstab
check "/etc/fstab parses cleanly (findmnt --verify)" fstab_verify_clean

summary
