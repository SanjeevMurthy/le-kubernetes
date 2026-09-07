#!/bin/bash
# Q04 systemd timer: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

systemctl disable --now logsync.timer >/dev/null 2>&1
systemctl disable --now logsync.service >/dev/null 2>&1
rm -f /etc/systemd/system/logsync.timer /etc/systemd/system/logsync.service
rm -rf /etc/systemd/system/logsync.service.d /etc/systemd/system/logsync.timer.d
rm -f /etc/systemd/system/timers.target.wants/logsync.timer
systemctl daemon-reload
rm -f /usr/local/bin/logsync.sh
rm -rf /var/log/logsync

echo "Cleanup complete. Both units, the enable symlink, the script and its log directory are gone."
