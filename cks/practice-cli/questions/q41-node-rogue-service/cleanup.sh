#!/bin/bash
# Q41 rogue service: remove only the unit and the directory that setup created,
# and leave every other unit on the node untouched.
source "$(dirname "$0")/../../lib/env.sh"
FILE=/etc/systemd/system/lab-fileshare.service
restore_file "$FILE" q41
on_worker bash -s >/dev/null 2>&1 <<'REMOTE' || true
FILE=/etc/systemd/system/lab-fileshare.service
MARK='# CKS practice CLI q41 lab unit'
systemctl disable --now lab-fileshare.service 2>/dev/null || true
if [ -f "$FILE" ] && grep -qF "$MARK" "$FILE"; then rm -f "$FILE"; fi
systemctl daemon-reload 2>/dev/null || true
systemctl reset-failed lab-fileshare.service 2>/dev/null || true
# Only if the port is still bound, and only for the exact command line setup ran.
if ss -H -ltn 2>/dev/null | awk '{print $4}' | grep -Eq '(^|[:.])8888$'; then
  pkill -f 'http\.server 8888 --bind 0\.0\.0\.0' 2>/dev/null || true
fi
rm -f /srv/lab-fileshare/README.txt
rmdir /srv/lab-fileshare 2>/dev/null || true
REMOTE
rm -rf "$COURSE_DIR/41"
echo "Cleanup complete"
