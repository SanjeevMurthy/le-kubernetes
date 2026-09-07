#!/bin/bash
# Q38 port conflict: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

ANS="$COURSE_DIR/38/answer.txt"

http_get() {
  if command -v curl >/dev/null 2>&1; then
    curl -s --max-time 5 "$1" 2>/dev/null
  else
    python3 -c 'import sys,urllib.request; sys.stdout.write(urllib.request.urlopen(sys.argv[1], timeout=5).read().decode())' "$1" 2>/dev/null
  fi
}

echo "Checking the application runs..."
check "webapp.service is active" systemctl is-active --quiet webapp.service
check_contains "something listens on TCP 8090" ":8090" "$(ss -H -ltn 2>/dev/null)"
check_contains "port 8090 answers from the web application" "webapp-ok" \
  "$(http_get http://127.0.0.1:8090/)"

echo "Checking the unit that held the port..."
# The check above proves 'systemctl is-active --quiet' returns 0 for a running
# unit here, so a non-zero exit below really means legacy is not running.
check_not "legacy.service is not running" systemctl is-active --quiet legacy.service
check_eq "legacy.service is masked, not merely disabled" "masked" \
  "$(systemctl is-enabled legacy.service 2>/dev/null)"
echo "Checking the report..."
check "answer.txt exists at $ANS" test -s "$ANS"
check_eq "answer.txt names legacy.service" "legacy.service" \
  "$(tr -d '[:space:]' < "$ANS" 2>/dev/null)"

echo "Checking both changes survive a reboot..."
check_eq "the mask is a symlink to /dev/null under /etc/systemd/system" "/dev/null" \
  "$(readlink /etc/systemd/system/legacy.service 2>/dev/null)"
check_eq "webapp.service is enabled" "enabled" \
  "$(systemctl is-enabled webapp.service 2>/dev/null)"
check_persisted "webapp is wired into multi-user.target on disk" \
  '^[[:space:]]*ExecStart' \
  /etc/systemd/system/multi-user.target.wants/webapp.service

summary
