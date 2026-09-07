#!/bin/bash
# Q26 swap file: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

# swapoff before deleting, or the pages are not actually released.
swapoff /swapfile2 2>/dev/null

if [[ -f /etc/fstab ]]; then
  awk '$1 ~ /^#/ || $1 != "/swapfile2"' /etc/fstab > /tmp/lfcs-q26-fstab &&
    cat /tmp/lfcs-q26-fstab > /etc/fstab
  rm -f /tmp/lfcs-q26-fstab
fi
restore_file /etc/fstab q26

rm -f /swapfile2
rm -rf "${LFCS_STATE_DIR:?}/q26"

echo "Cleanup complete. /swapfile2 swapped off and deleted, /etc/fstab restored."
