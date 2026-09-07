#!/bin/bash
# Q10 systemd unit: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

systemctl disable --now inventory.service >/dev/null 2>&1
rm -f /etc/systemd/system/inventory.service
rm -rf /etc/systemd/system/inventory.service.d
rm -f /etc/systemd/system/multi-user.target.wants/inventory.service
systemctl daemon-reload

pkill -f 'http.server 9090' >/dev/null 2>&1
userdel inventory >/dev/null 2>&1
rm -rf /opt/inventory

echo "Cleanup complete. Unit, enable symlink, the inventory account and /opt/inventory are gone."
