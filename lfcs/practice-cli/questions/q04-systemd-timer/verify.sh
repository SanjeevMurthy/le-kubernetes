#!/bin/bash
# Q04 systemd timer: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

echo "Checking both units exist..."
check "systemd knows logsync.service" systemctl cat logsync.service
check "systemd knows logsync.timer" systemctl cat logsync.timer

echo "Checking the live state..."
check_eq "logsync.timer is active" "active" "$(systemctl is-active logsync.timer 2>/dev/null)"
# systemd prints the normalised calendar spec here, so OnCalendar=*:0/15 comes
# back as *-*-* *:00/15:00. Match the normalised form, not what was typed.
check_contains "the calendar expression fires every 15 minutes" "*:00/15:00" \
  "$(systemctl show logsync.timer -p TimersCalendar --value 2>/dev/null)"
check_contains "the timer triggers logsync.service" "logsync.service" \
  "$(systemctl show logsync.timer -p Unit --value 2>/dev/null)"
check_contains "logsync.service runs the script" "/usr/local/bin/logsync.sh" \
  "$(systemctl show logsync.service -p ExecStart --value 2>/dev/null)"

echo "Checking the timer comes back after a reboot..."
check_eq "logsync.timer is enabled" "enabled" "$(systemctl is-enabled logsync.timer 2>/dev/null)"
check_persisted "the schedule is written in the timer unit" \
  'OnCalendar[[:space:]]*=[[:space:]]*\*:0{1,2}/15' \
  /etc/systemd/system/logsync.timer
check_persisted "the timer is wired into timers.target on disk" \
  'OnCalendar' \
  /etc/systemd/system/timers.target.wants/logsync.timer
check_persisted "logsync.service is a real unit file on disk" \
  'ExecStart[[:space:]]*=.*/usr/local/bin/logsync\.sh' \
  /etc/systemd/system/logsync.service

summary
