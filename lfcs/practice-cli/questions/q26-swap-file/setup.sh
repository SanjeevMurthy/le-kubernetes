#!/bin/bash
# Q26 swap file: remove any swap file left from an earlier attempt and take the
# fstab line with it, so the task starts from nothing.
source "$(dirname "$0")/../../lib/env.sh"

# Machine-readable output only: never let a locale reformat a number.
export LC_ALL=C
require_root "$@"

STATE="$LFCS_STATE_DIR/q26"
mkdir -p "$STATE"

backup_file /etc/fstab q26
swapoff /swapfile2 2>/dev/null
rm -f /swapfile2
if [[ -f /etc/fstab ]]; then
  awk '$1 ~ /^#/ || $1 != "/swapfile2"' /etc/fstab > "$STATE/fstab.tmp" &&
    cat "$STATE/fstab.tmp" > /etc/fstab
  rm -f "$STATE/fstab.tmp"
fi

echo "Setup complete."
echo "  /swapfile2 does not exist and /etc/fstab does not mention it."
echo "  Swap in use right now:"
swapon --show 2>/dev/null | sed 's/^/    /'
[[ -z "$(swapon --show --noheadings 2>/dev/null)" ]] && echo "    (none)"
echo "  Wanted: /swapfile2, 512 MB, mode 600, active at priority 10, and back after a reboot."
