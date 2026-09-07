#!/bin/bash
# Q03 cron and at: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q03"

if [[ "$(distro)" == ubuntu ]]; then
  CRONDIR=/var/spool/cron/crontabs
else
  CRONDIR=/var/spool/cron
fi

# Remove only the at jobs that appeared after setup ran.
if [[ -f "$STATE/atq.before" ]]; then
  atq 2>/dev/null | awk '{print $1}' | sort > "$STATE/atq.after"
  for j in $(comm -13 "$STATE/atq.before" "$STATE/atq.after"); do
    atrm "$j" >/dev/null 2>&1
  done
fi

crontab -u backupop -r >/dev/null 2>&1
if crontab -l >/dev/null 2>&1; then
  crontab -l 2>/dev/null | grep -v '/usr/local/bin/cleanup.sh' | crontab -
fi
restore_file "$CRONDIR/root" q03

userdel -r backupop >/dev/null 2>&1
rm -f /usr/local/bin/backup.sh /usr/local/bin/cleanup.sh
rm -f /var/log/lfcs-backup.log /var/log/lfcs-cleanup.log
rm -rf "${LFCS_STATE_DIR:?}/q03"

echo "Cleanup complete. User backupop, both scripts, both crontabs and the new at jobs are gone."
