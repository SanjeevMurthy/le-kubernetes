#!/bin/bash
# Q19 bridge: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

STATE="$LFCS_STATE_DIR/q19"
NIC=$(cat "$STATE/nic" 2>/dev/null)
ADDR=$(cat "$STATE/addr" 2>/dev/null)
GW=$(cat "$STATE/gw" 2>/dev/null)
GWPING=$(cat "$STATE/gwping" 2>/dev/null)

if [[ -z "$NIC" || -z "$ADDR" ]]; then
  echo "  FAIL: setup has not run, so the interface and its address are unknown. Run setup first."
  FAIL=$((FAIL + 1))
  summary
  exit $?
fi

echo "Checking the bridge device..."
check "br0 exists and the kernel calls it a bridge" test -d /sys/class/net/br0/bridge
check_contains "ip -d -j link show br0 reports info_kind bridge" '"info_kind":"bridge"' \
  "$(ip -d -j link show br0 2>/dev/null)"
check_contains "br0 is up" '"UP"' "$(ip -j link show br0 2>/dev/null)"

echo "Checking that $NIC is a port of br0..."
MASTER=$(basename "$(readlink /sys/class/net/"$NIC"/master 2>/dev/null)" 2>/dev/null)
check_eq "the master of $NIC is br0" "br0" "$MASTER"
check_contains "bridge link lists $NIC under br0" "$NIC" "$(bridge link show 2>/dev/null | grep 'master br0')"

echo "Checking where the address ended up..."
check_contains "$ADDR is on br0" "\"local\":\"${ADDR%/*}\"" "$(ip -j addr show dev br0 2>/dev/null)"
check_eq "$NIC no longer holds an IPv4 address of its own" "" \
  "$(ip -o -4 addr show dev "$NIC" 2>/dev/null | awk '{print $4}' | tr '\n' ' ' | sed 's/ *$//')"

echo "Checking the host can still reach its gateway..."
if [[ "$GWPING" == yes ]]; then
  check "the gateway $GW still answers ping through br0" ping -c1 -W3 "$GW"
else
  echo "  NOTE: $GW did not answer ping before the change either, so reachability is not graded."
fi

echo "Checking the bridge survives a reboot..."
if [[ "$(distro)" == ubuntu ]]; then
  check_persisted "a bridges: section defines br0 in the netplan configuration" \
    'bridges:' /etc/netplan/*.yaml /etc/netplan/*.yml
  check_persisted "$NIC is listed as a member of the bridge" \
    "(interfaces:.*$NIC|^[[:space:]]*-[[:space:]]+$NIC[[:space:]]*\$)" \
    /etc/netplan/*.yaml /etc/netplan/*.yml
  check_persisted "$ADDR is written on the bridge, not on the port" \
    "${ADDR%/*}/" /etc/netplan/*.yaml /etc/netplan/*.yml
else
  check_persisted "a NetworkManager connection of type bridge exists" \
    '^type=bridge' /etc/NetworkManager/system-connections/*.nmconnection
  check_persisted "a NetworkManager connection makes a port of br0" \
    '^(master|controller)=br0' /etc/NetworkManager/system-connections/*.nmconnection
  check_persisted "$ADDR is written into the bridge connection" \
    "${ADDR%/*}/" /etc/NetworkManager/system-connections/*.nmconnection
  check_eq "nmcli reports br0 as a bridge connection" "bridge" \
    "$(nmcli -g connection.type con show br0 2>/dev/null)"
fi

summary
