#!/bin/bash
# Q40 service limits: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

systemctl disable --now fdhog.service >/dev/null 2>&1
rm -rf /etc/systemd/system/fdhog.service.d
rm -f /etc/systemd/system/fdhog.service
rm -f /usr/lib/systemd/system/fdhog.service
rm -f /etc/systemd/system/multi-user.target.wants/fdhog.service
systemctl daemon-reload
systemctl reset-failed fdhog.service >/dev/null 2>&1

pkill -f '/usr/local/bin/fdhog.sh' >/dev/null 2>&1
rm -f /usr/local/bin/fdhog.sh

echo "Cleanup complete. The fdhog unit, its drop-in directory and /usr/local/bin/fdhog.sh are gone."
