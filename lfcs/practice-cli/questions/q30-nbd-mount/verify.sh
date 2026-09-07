#!/bin/bash
# Q30 NBD: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

# Machine-readable output only: never let a locale reformat a number.
export LC_ALL=C

STATE="$LFCS_STATE_DIR/q30"
TOKEN=$(cat "$STATE/token" 2>/dev/null)
if [[ -z "$TOKEN" ]]; then
  echo "  FAIL: no export recorded. Run setup first."
  echo ""; echo "Results: 0 passed, 1 failed"; exit 1
fi

fstab_verify_clean() {
  local out
  out=$(findmnt --verify 2>&1)
  ! grep -qiE '[1-9][0-9]* (parse )?error' <<<"$out"
}

echo "Checking the kernel module..."
check "the nbd module is loaded" test -d /sys/module/nbd

echo "Checking the attachment..."
check "/dev/nbd0 is connected to a server" nbd-client -c /dev/nbd0

echo "Checking the live mount..."
check_eq "/mnt/nbd is mounted from /dev/nbd0" "$(readlink -f /dev/nbd0 2>/dev/null)" \
  "$(readlink -f "$(findmnt -no SOURCE /mnt/nbd 2>/dev/null)" 2>/dev/null)"
check_eq "/mnt/nbd is ext4" "ext4" "$(findmnt -no FSTYPE /mnt/nbd 2>/dev/null)"
check_eq "marker.txt is readable on the mounted export" "$TOKEN" \
  "$(tr -d ' \n\r' < /mnt/nbd/marker.txt 2>/dev/null)"

echo "Checking the deliverable..."
check_eq "$COURSE_DIR/30/token.txt holds the marker" "$TOKEN" \
  "$(tr -d ' \n\r' < "$COURSE_DIR/30/token.txt" 2>/dev/null)"

echo "Checking what survives a reboot..."
check_persisted "the nbd module is configured to load at boot" \
  '^[[:space:]]*nbd[[:space:]]*$' /etc/modules-load.d/*.conf /etc/modules
check_persisted "/etc/fstab has a line for /mnt/nbd" \
  '^[^#]*[[:space:]]/mnt/nbd[[:space:]]' /etc/fstab
FSTAB_LINE=$(grep -E '^[^#]*[[:space:]]/mnt/nbd[[:space:]]' /etc/fstab 2>/dev/null | head -1)
check_contains "the /mnt/nbd fstab line uses _netdev" "_netdev" "$FSTAB_LINE"
check_contains "the /mnt/nbd fstab line uses noauto" "noauto" "$FSTAB_LINE"
check "/etc/fstab parses cleanly (findmnt --verify)" fstab_verify_clean

summary
