#!/bin/bash
# Q01 sysctl: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

echo "Checking the running kernel..."
check_eq "net.ipv4.ip_forward is 1 right now" "1" "$(sysctl -n net.ipv4.ip_forward 2>/dev/null)"
check_eq "vm.swappiness is 10 right now" "10" "$(sysctl -n vm.swappiness 2>/dev/null)"
check_eq "procfs agrees about ip_forward" "1" "$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)"

echo "Checking the change survives a reboot..."
check_persisted "net.ipv4.ip_forward = 1 is written to a config file" \
  '^[[:space:]]*net\.ipv4\.ip_forward[[:space:]]*=[[:space:]]*1[[:space:]]*$' \
  /etc/sysctl.conf /etc/sysctl.d/*.conf
check_persisted "vm.swappiness = 10 is written to a config file" \
  '^[[:space:]]*vm\.swappiness[[:space:]]*=[[:space:]]*10[[:space:]]*$' \
  /etc/sysctl.conf /etc/sysctl.d/*.conf

summary
