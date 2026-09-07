#!/bin/bash
# Q12 static IPv4 on the second NIC: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

STATE="$LFCS_STATE_DIR/q12"
NIC=$(cat "$STATE/nic" 2>/dev/null)
CON=$(cat "$STATE/con" 2>/dev/null)

TARGET_IP=10.50.0.10
[[ "$(distro)" == rocky ]] && TARGET_IP=10.50.0.20
TARGET="$TARGET_IP/24"

if [[ -z "$NIC" ]]; then
  echo "  FAIL: setup has not run, so the lab interface is unknown. Run setup first."
  FAIL=$((FAIL + 1))
  summary
  exit $?
fi

echo "Checking the live address on $NIC..."
J=$(ip -j addr show dev "$NIC" 2>/dev/null)
check_contains "$TARGET_IP is live on $NIC" "\"local\":\"$TARGET_IP\"" "$J"

RJ=$(ip -j route show dev "$NIC" 2>/dev/null)
check_contains "the connected route 10.50.0.0/24 is on $NIC, so the prefix is /24" \
  '"dst":"10.50.0.0/24"' "$RJ"

echo "Checking the addresses the interface already had..."
if [[ -s "$STATE/keep" ]]; then
  while read -r a; do
    [[ -n "$a" ]] || continue
    check_contains "$a is still on $NIC" "\"local\":\"${a%/*}\"" "$J"
  done < "$STATE/keep"
else
  echo "  NOTE: $NIC had no IPv4 address when setup ran, so there is nothing to preserve."
fi

echo "Checking the address survives a reboot..."
if [[ "$(distro)" == ubuntu ]]; then
  check_persisted "$TARGET is written into the netplan configuration" \
    "$TARGET_IP/24" /etc/netplan/*.yaml /etc/netplan/*.yml
else
  check_persisted "$TARGET is written into the NetworkManager connection" \
    "$TARGET_IP/24" /etc/NetworkManager/system-connections/*.nmconnection \
    /etc/sysconfig/network-scripts/ifcfg-*
  if [[ -n "$CON" ]]; then
    check_contains "nmcli reports the address on connection $CON" "$TARGET" \
      "$(nmcli -g ipv4.addresses con show "$CON" 2>/dev/null)"
    check_eq "connection $CON uses ipv4.method manual" "manual" \
      "$(nmcli -g ipv4.method con show "$CON" 2>/dev/null)"
  fi
fi

summary
