#!/bin/bash
# Q01 sysctl: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

rm -f /etc/sysctl.d/90-lab.conf
restore_file /etc/sysctl.d/90-lab.conf q01
restore_file /etc/sysctl.conf q01
sysctl -q --system >/dev/null 2>&1

echo "Cleanup complete. /etc/sysctl.conf restored, /etc/sysctl.d/90-lab.conf removed, sysctl --system reapplied."
echo "A drop-in you saved under a different name is still in /etc/sysctl.d; remove it by hand if you want the host back exactly."
