#!/bin/bash
# Q29 LUKS: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

STATE="$LFCS_STATE_DIR/q29"
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

echo "Checking the container..."
check_eq "$DEV holds a LUKS header" "crypto_LUKS" "$(blkid -s TYPE -o value "$DEV" 2>/dev/null)"
check "cryptsetup recognises it as a LUKS device" cryptsetup isLuks "$DEV"

echo "Checking the key file..."
check "/root/secret.key exists" test -f /root/secret.key
check_eq "/root/secret.key is mode 600 owned by root" "600 root" \
  "$(stat -c '%a %U' /root/secret.key 2>/dev/null)"
# The precondition above is what makes this meaningful: the device is LUKS, so a
# failure here means the key file really does not open it.
if cryptsetup isLuks "$DEV" >/dev/null 2>&1 && [[ -f /root/secret.key ]]; then
  check "the key file actually unlocks $DEV" \
    cryptsetup luksOpen --test-passphrase --key-file /root/secret.key "$DEV"
else
  echo "  FAIL: cannot test the key file (no LUKS device or no key file)"
  FAIL=$((FAIL + 1))
fi

echo "Checking the open mapping..."
check "the mapping 'secret' is active" \
  bash -c 'cryptsetup status secret 2>/dev/null | grep -q "is active"'
check_eq "the mapping is backed by $DEV" "$(readlink -f "$DEV" 2>/dev/null)" \
  "$(readlink -f "$(cryptsetup status secret 2>/dev/null | awk '$1=="device:" {print $2}')" 2>/dev/null)"

echo "Checking the filesystem and the live mount..."
check_eq "/mnt/secret is mounted from /dev/mapper/secret" "$(readlink -f /dev/mapper/secret 2>/dev/null)" \
  "$(readlink -f "$(findmnt -no SOURCE /mnt/secret 2>/dev/null)" 2>/dev/null)"
check_eq "/mnt/secret is ext4" "ext4" "$(findmnt -no FSTYPE /mnt/secret 2>/dev/null)"

echo "Checking it unlocks and mounts after a reboot..."
LUKSUUID=$(blkid -s UUID -o value "$DEV" 2>/dev/null)
if [[ -z "$LUKSUUID" ]]; then
  echo "  FAIL: $DEV has no LUKS UUID, so no /etc/crypttab line can be right"
  FAIL=$((FAIL + 1))
else
  check_persisted "/etc/crypttab unlocks 'secret' from UUID=$LUKSUUID with the key file" \
    "^[[:space:]]*secret[[:space:]]+UUID=\"?'?$LUKSUUID'?\"?[[:space:]]+/root/secret\.key" \
    /etc/crypttab
fi
check_persisted "/etc/fstab mounts /dev/mapper/secret at /mnt/secret" \
  '^[^#]*/dev/mapper/secret[[:space:]]+/mnt/secret[[:space:]]' /etc/fstab
check "/etc/fstab parses cleanly (findmnt --verify)" fstab_verify_clean

summary
