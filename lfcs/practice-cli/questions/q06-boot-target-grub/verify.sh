#!/bin/bash
# Q06 boot target and GRUB: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

echo "Checking the default boot target..."
check_eq "systemctl get-default reports multi-user.target" \
  "multi-user.target" "$(systemctl get-default 2>/dev/null)"
check_contains "the default.target symlink on disk points at multi-user.target" \
  "multi-user.target" "$(readlink -f /etc/systemd/system/default.target 2>/dev/null)"

echo "Checking the GRUB timeout..."
check_persisted "GRUB_TIMEOUT=10 is in the source file" \
  '^GRUB_TIMEOUT=10$' /etc/default/grub
check "the generated boot config carries timeout=10" \
  grep -Eq 'timeout=10' /boot/grub/grub.cfg /boot/grub2/grub.cfg

summary
