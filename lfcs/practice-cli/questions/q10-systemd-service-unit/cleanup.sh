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

# Only what this question created. An inventory account or directory the host
# already had is not this question's to delete.
STATE="$LFCS_STATE_DIR/q10"
[[ "$(cat "$STATE/created-user" 2>/dev/null)" == yes ]] && userdel inventory >/dev/null 2>&1
if [[ "$(cat "$STATE/created-dir" 2>/dev/null)" == yes ]]; then
  rm -rf /opt/inventory
else
  rm -f /opt/inventory/index.html /opt/inventory/server.sh
fi
rm -rf "${LFCS_STATE_DIR:?}/q10"

echo "Cleanup complete. The unit and its enable symlink are gone, and the inventory account and /opt/inventory were removed only if this question created them."
