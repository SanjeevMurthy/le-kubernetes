#!/bin/bash
# Q26 swap file: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

# swapoff before deleting, or the pages are not actually released.
swapoff /swapfile2 2>/dev/null

fstab_drop_target /swapfile2

rm -f /swapfile2
rm -rf "${LFCS_STATE_DIR:?}/q26"

echo "Cleanup complete. /swapfile2 swapped off and deleted, its /etc/fstab line removed."
