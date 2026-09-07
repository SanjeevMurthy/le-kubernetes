#!/bin/bash
# Q10 systemd unit: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

http_get() {
  if command -v curl >/dev/null 2>&1; then
    curl -s --max-time 5 "$1" 2>/dev/null
  else
    python3 -c 'import sys,urllib.request; sys.stdout.write(urllib.request.urlopen(sys.argv[1], timeout=5).read().decode())' "$1" 2>/dev/null
  fi
}

echo "Checking the unit exists and runs..."
check "systemd knows inventory.service" systemctl cat inventory.service
check_eq "inventory.service is active" "active" "$(systemctl is-active inventory.service 2>/dev/null)"

echo "Checking the live effect..."
check_contains "something is listening on 9090" ":9090" "$(ss -H -ltn 2>/dev/null)"
check_contains "the application answers on 9090" "inventory-ok" \
  "$(http_get http://localhost:9090/)"
MAINPID=$(systemctl show inventory.service -p MainPID --value 2>/dev/null)
check_eq "the process runs as the inventory account" \
  "$(id -u inventory 2>/dev/null)" "$(ps -o uid= -p "$MAINPID" 2>/dev/null | tr -d ' ')"

echo "Checking the effective unit settings..."
check_eq "User is inventory" "inventory" "$(systemctl show inventory.service -p User --value 2>/dev/null)"
check_eq "Restart is on-failure" "on-failure" "$(systemctl show inventory.service -p Restart --value 2>/dev/null)"
check_contains "ExecStart runs the application" "/opt/inventory/server.sh" \
  "$(systemctl show inventory.service -p ExecStart --value 2>/dev/null)"

echo "Checking the service comes back after a reboot..."
check_eq "inventory.service is enabled" "enabled" "$(systemctl is-enabled inventory.service 2>/dev/null)"
check_persisted "User=inventory is written in the unit file" \
  '^[[:space:]]*User[[:space:]]*=[[:space:]]*inventory' \
  /etc/systemd/system/inventory.service
check_persisted "Restart=on-failure is written in the unit file" \
  '^[[:space:]]*Restart[[:space:]]*=[[:space:]]*on-failure' \
  /etc/systemd/system/inventory.service
check_persisted "the unit is wired into multi-user.target on disk" \
  '^[[:space:]]*ExecStart' \
  /etc/systemd/system/multi-user.target.wants/inventory.service

summary
