#!/bin/bash
# Q03 cron and at: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

BOP=$(crontab -l -u backupop 2>/dev/null | tr -s '[:blank:]' ' ')
ROOTCRON=$(crontab -l 2>/dev/null | tr -s '[:blank:]' ' ')

echo "Checking the job scheduled for backupop..."
check_contains "crontab -l -u backupop shows the 02:30 daily job" \
  "30 2 * * * /usr/local/bin/backup.sh" "$BOP"
check_persisted "the backupop job is in the crontab spool file" \
  '^30[[:space:]]+2([[:space:]]+\*){3}[[:space:]]+/usr/local/bin/backup\.sh' \
  /var/spool/cron/crontabs/backupop /var/spool/cron/backupop

echo "Checking the job scheduled for root..."
check_contains "crontab -l shows the Sunday 04:00 job" \
  "0 4 * * 0 /usr/local/bin/cleanup.sh" "$ROOTCRON"
check_persisted "the root job is in the crontab spool file" \
  '^0[[:space:]]+4[[:space:]]+\*[[:space:]]+\*[[:space:]]+(0|7|[Ss]un)[[:space:]]+/usr/local/bin/cleanup\.sh' \
  /var/spool/cron/crontabs/root /var/spool/cron/root

echo "Checking the one-off at job..."
check "atq lists at least one job" test -n "$(atq 2>/dev/null)"
found=no
for j in $(atq 2>/dev/null | awk '{print $1}'); do
  if at -c "$j" 2>/dev/null | grep -q '/usr/local/bin/backup.sh'; then found=yes; fi
done
check_eq "one queued at job runs backup.sh" "yes" "$found"
check_eq "atd is enabled, so a queued job survives a reboot" "enabled" "$(systemctl is-enabled atd 2>/dev/null)"
check_eq "atd is running now" "active" "$(systemctl is-active atd 2>/dev/null)"

summary
