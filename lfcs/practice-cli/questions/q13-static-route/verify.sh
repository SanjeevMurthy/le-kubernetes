#!/bin/bash
# Q13 persistent static route: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

STATE="$LFCS_STATE_DIR/q13"
NIC=$(cat "$STATE/nic" 2>/dev/null)
GW=$(cat "$STATE/gw" 2>/dev/null)
CON=$(cat "$STATE/con" 2>/dev/null)

if [[ -z "$NIC" || -z "$GW" ]]; then
  echo "  FAIL: setup has not run, so the lab interface and gateway are unknown. Run setup first."
  FAIL=$((FAIL + 1))
  summary
  exit $?
fi

echo "Checking the running kernel..."
RJ=$(ip -j route show 10.200.0.0/16 2>/dev/null)
check_contains "10.200.0.0/16 is in the routing table" '"dst":"10.200.0.0/16"' "$RJ"
check_contains "its next hop is $GW" "\"gateway\":\"$GW\"" "$RJ"
check_contains "it leaves through $NIC" "\"dev\":\"$NIC\"" "$RJ"

echo "Checking which route the kernel would really use..."
GET=$(ip route get 10.200.0.5 2>/dev/null)
check_contains "ip route get 10.200.0.5 goes via $GW" "$GW" "$GET"
check_contains "ip route get 10.200.0.5 leaves through $NIC" "$NIC" "$GET"

echo "Checking the route survives a reboot..."
if [[ "$(distro)" == ubuntu ]]; then
  check_persisted "10.200.0.0/16 is written into the netplan configuration" \
    '10\.200\.0\.0/16' /etc/netplan/*.yaml /etc/netplan/*.yml
  check_persisted "the gateway $GW is written into the netplan configuration" \
    "$GW" /etc/netplan/*.yaml /etc/netplan/*.yml
else
  check_persisted "10.200.0.0/16 is written into the NetworkManager connection" \
    '10\.200\.0\.0/16' /etc/NetworkManager/system-connections/*.nmconnection \
    /etc/sysconfig/network-scripts/route-* /etc/sysconfig/network-scripts/ifcfg-*
  if [[ -n "$CON" ]]; then
    check_contains "nmcli reports the route on connection $CON" "10.200.0.0/16" \
      "$(nmcli -g ipv4.routes con show "$CON" 2>/dev/null)"
  fi
fi

summary
