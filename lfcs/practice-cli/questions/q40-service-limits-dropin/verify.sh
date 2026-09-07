#!/bin/bash
# Q40 service limits: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

echo "Checking the effective unit settings..."
check_eq "LimitNOFILE is 65536" "65536" \
  "$(systemctl show fdhog.service -p LimitNOFILE --value 2>/dev/null)"
check_eq "TasksMax is 4096" "4096" \
  "$(systemctl show fdhog.service -p TasksMax --value 2>/dev/null)"

echo "Checking the service actually runs with them..."
check "fdhog.service is active" systemctl is-active --quiet fdhog.service
# /proc/PID/limits is columnar: limit name, soft limit, hard limit, units. The
# name itself contains spaces, so the two numbers are counted from the end of the
# line rather than from the start. Grepping the whole row for 65536 would also
# accept a soft:hard pair of 1024:65536, which is not what the question asks for.
MAINPID=$(systemctl show fdhog.service -p MainPID --value 2>/dev/null)
LIMLINE=$(grep '^Max open files' "/proc/$MAINPID/limits" 2>/dev/null)
SOFT=$(awk 'NF>=4 {print $(NF-2)}' <<<"$LIMLINE")
HARD=$(awk 'NF>=4 {print $(NF-1)}' <<<"$LIMLINE")
check_eq "the running process really has 65536 open files as its soft limit" "65536" "$SOFT"
check_eq "the running process really has 65536 open files as its hard limit" "65536" "$HARD"

echo "Checking the change survives a reboot and a package upgrade..."
check_eq "fdhog.service is enabled" "enabled" \
  "$(systemctl is-enabled fdhog.service 2>/dev/null)"
check_persisted "LimitNOFILE=65536 is written in a drop-in under /etc/systemd/system" \
  '^[[:space:]]*LimitNOFILE[[:space:]]*=[[:space:]]*65536[[:space:]]*$' \
  /etc/systemd/system/fdhog.service.d/*.conf
check_persisted "TasksMax=4096 is written in the same drop-in" \
  '^[[:space:]]*TasksMax[[:space:]]*=[[:space:]]*4096[[:space:]]*$' \
  /etc/systemd/system/fdhog.service.d/*.conf
check_file_has "the vendor unit is untouched and still reads LimitNOFILE=16" \
  '^[[:space:]]*LimitNOFILE[[:space:]]*=[[:space:]]*16[[:space:]]*$' \
  /usr/lib/systemd/system/fdhog.service

summary
