#!/bin/bash
# Q11 journal and a broken unit: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

ERR="$COURSE_DIR/11/error.txt"

echo "Checking the diagnosis was written down..."
check "error.txt exists at $COURSE_DIR/11" test -f "$ERR"
check_file_has "error.txt names the failure, 203/EXEC or a permission denial" \
  '203/EXEC|[Pp]ermission denied' "$ERR"

echo "Checking the service was fixed, not worked around..."
check "the script is executable now" test -x /opt/billing/billing.sh
check_contains "ExecStart still runs the original script" "/opt/billing/billing.sh" \
  "$(systemctl show billing.service -p ExecStart --value 2>/dev/null)"
check_eq "billing.service is active" "active" "$(systemctl is-active billing.service 2>/dev/null)"
check_eq "billing.service is still enabled" "enabled" "$(systemctl is-enabled billing.service 2>/dev/null)"

echo "Checking the journal is now persistent..."
check "the journal directory /var/log/journal exists" test -d /var/log/journal
check "a journal file is being written under /var/log/journal" \
  bash -c 'ls /var/log/journal/*/*.journal >/dev/null 2>&1'
# Two answers are correct. Storage=persistent always writes to disk. Storage=auto
# writes to disk whenever /var/log/journal exists, so with the directory in place
# it is just as persistent, and the exam accepts it. Storage=volatile, which setup
# leaves behind, matches neither, and neither does a commented-out line.
STORAGE_PAT='^[[:space:]]*Storage=persistent[[:space:]]*$'
STORAGE_LABEL="Storage=persistent is set in the journald configuration"
if [[ -d /var/log/journal ]]; then
  STORAGE_PAT='^[[:space:]]*Storage=(persistent|auto)[[:space:]]*$'
  STORAGE_LABEL="journald storage is persistent: Storage=persistent, or Storage=auto with /var/log/journal present"
fi
check_persisted "$STORAGE_LABEL" "$STORAGE_PAT" \
  /etc/systemd/journald.conf /etc/systemd/journald.conf.d/*.conf

summary
