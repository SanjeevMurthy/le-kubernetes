#!/bin/bash
# Q11 journal and a broken unit: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

JBK="$LFCS_STATE_DIR/backup/q11/var_log_journal"

systemctl disable --now billing.service >/dev/null 2>&1
rm -f /etc/systemd/system/billing.service
rm -rf /etc/systemd/system/billing.service.d
rm -f /etc/systemd/system/multi-user.target.wants/billing.service
systemctl daemon-reload
rm -rf /opt/billing
rm -rf "$COURSE_DIR/11"

restore_file /etc/systemd/journald.conf q11
rm -rf /var/log/journal
if [[ -d "$JBK" ]]; then
  mv "$JBK" /var/log/journal
fi
systemctl restart systemd-journald >/dev/null 2>&1

echo "Cleanup complete."
echo "  billing.service, /opt/billing and $COURSE_DIR/11 removed."
echo "  /etc/systemd/journald.conf restored and the original /var/log/journal put back if there was one."
