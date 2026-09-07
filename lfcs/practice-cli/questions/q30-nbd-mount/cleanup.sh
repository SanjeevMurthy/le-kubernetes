#!/bin/bash
# Q30 NBD: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q30"

# The candidate may have declared the module in /etc/modules-load.d/*.conf or in
# /etc/modules. Take the declaration out of both, so the next run of this
# question starts with nothing to inherit. Nothing is backed up here: setup
# already saved every file it found declaring nbd, and those are restored below.
strip_nbd_boot_config() {
  local f tmp
  for f in /etc/modules /etc/modules-load.d/*.conf; do
    [[ -f "$f" ]] || continue
    grep -Eq '^[[:space:]]*nbd[[:space:]]*$' "$f" || continue
    tmp="$f.lfcs-q30"
    awk '!/^[[:space:]]*nbd[[:space:]]*$/' "$f" > "$tmp" && cat "$tmp" > "$f"
    rm -f "$tmp"
    if [[ "$f" == /etc/modules-load.d/* ]] && ! grep -q '[^[:space:]]' "$f"; then
      rm -f "$f"
    fi
  done
  return 0
}

umount /mnt/nbd 2>/dev/null
nbd-client -d /dev/nbd0 >/dev/null 2>&1
modprobe -r nbd 2>/dev/null

# Kills the nbd-server running inside the namespace and removes the veth pair.
del_netns_peer nbd-peer

fstab_drop_target /mnt/nbd
# Only when setup ran: with no record of what this host looked like before, an
# nbd line here is the host's own and must be left alone.
if [[ -f "$STATE/modfiles" ]]; then
  strip_nbd_boot_config
  while read -r f; do
    [[ -n "$f" ]] && restore_file "$f" q30
  done < "$STATE/modfiles"
fi

umount "$STATE/mnt" 2>/dev/null
rm -rf "$COURSE_DIR/30"
findmnt -no TARGET /mnt/nbd >/dev/null 2>&1 || rm -rf /mnt/nbd
rm -rf "${LFCS_STATE_DIR:?}/q30"

echo "Cleanup complete. /mnt/nbd unmounted, /dev/nbd0 disconnected, nbd module removed, the nbd-peer namespace and its nbd-server deleted, its /etc/fstab line removed, the export image removed, the nbd line taken out of /etc/modules-load.d and /etc/modules, and any file that declared it before setup restored."
