#!/bin/bash
# Q06 boot target and GRUB: point the default target at graphical.target and set
# a wrong GRUB timeout in both the source file and the generated file, so both
# halves of the task start wrong.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q06"
mkdir -p "$STATE"

[[ -f "$STATE/default-target" ]] || systemctl get-default > "$STATE/default-target" 2>/dev/null

backup_file /etc/default/grub q06

systemctl set-default graphical.target >/dev/null 2>&1

if [[ -f /etc/default/grub ]]; then
  if grep -q '^GRUB_TIMEOUT=' /etc/default/grub; then
    sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub
  else
    echo 'GRUB_TIMEOUT=5' >> /etc/default/grub
  fi
else
  echo 'GRUB_TIMEOUT=5' > /etc/default/grub
fi

if [[ "$(distro)" == ubuntu ]]; then
  GRUBCFG=/boot/grub/grub.cfg
  update-grub >/dev/null 2>&1 && REGEN=ok || REGEN=failed
else
  GRUBCFG=/boot/grub2/grub.cfg
  grub2-mkconfig -o "$GRUBCFG" >/dev/null 2>&1 && REGEN=ok || REGEN=failed
fi

echo "Setup complete."
echo "  Default target now: $(systemctl get-default 2>/dev/null)"
echo "  /etc/default/grub:  $(grep '^GRUB_TIMEOUT=' /etc/default/grub 2>/dev/null)"
echo "  Generated config:   $GRUBCFG (regeneration at setup: $REGEN)"
echo "  Required: multi-user.target by default, and a 10 second GRUB timeout that the boot loader really reads."
if [[ "$REGEN" != ok ]]; then
  echo "  Warning: the GRUB tool did not run here. Check that grub is installed before starting."
fi
