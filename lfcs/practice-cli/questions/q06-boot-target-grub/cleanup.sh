#!/bin/bash
# Q06 boot target and GRUB: Cleanup.
# This one regenerates the boot configuration on purpose. Restoring
# /etc/default/grub without regenerating would leave the lab VM booting from a
# generated file that no longer matches its source.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q06"

restore_file /etc/default/grub q06

TARGET=multi-user.target
[[ -s "$STATE/default-target" ]] && TARGET=$(cat "$STATE/default-target")
systemctl set-default "$TARGET" >/dev/null 2>&1

if [[ "$(distro)" == ubuntu ]]; then
  GRUBCFG=/boot/grub/grub.cfg
  update-grub >/dev/null 2>&1 && REGEN=ok || REGEN=failed
else
  GRUBCFG=/boot/grub2/grub.cfg
  grub2-mkconfig -o "$GRUBCFG" >/dev/null 2>&1 && REGEN=ok || REGEN=failed
fi

rm -rf "${LFCS_STATE_DIR:?}/q06"

echo "Cleanup complete."
echo "  /etc/default/grub restored, default target set back to $TARGET"
echo "  $GRUBCFG regenerated: $REGEN"
if [[ "$REGEN" != ok ]]; then
  echo "  WARNING: the boot configuration was NOT regenerated. Run it by hand before rebooting this VM:"
  echo "    update-grub                              # Ubuntu"
  echo "    grub2-mkconfig -o /boot/grub2/grub.cfg   # Rocky"
fi
