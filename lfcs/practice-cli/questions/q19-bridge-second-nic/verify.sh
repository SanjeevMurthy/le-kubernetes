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

# Netplan puts the bridge and its port in one file, and on this host the
# installer had already written this address on the port, so grepping the files
# for the address says nothing about whether it moved. Walk the YAML by
# indentation instead: print "<section>.<device> <file>" for every line that
# carries the address, which says whether it now sits under bridges: br0: or is
# still on an ethernet.
netplan_addr_owner() {   # netplan_addr_owner <address or bare ip>
  local esc f
  local files=()
  for f in /etc/netplan/*.yaml /etc/netplan/*.yml; do [[ -f "$f" ]] && files+=("$f"); done
  [[ ${#files[@]} -gt 0 ]] || return 0
  esc=$(printf '%s' "$1" | sed 's/\./\\./g')
  awk -v re="(^|[^0-9.])${esc}([^0-9.]|\$)" '
    FNR == 1 { sec = ""; secind = -1; dev = ""; devind = -1 }
    /^[[:space:]]*(#|$)/ { next }
    {
      i = match($0, /[^ ]/); i = (i > 0 ? i - 1 : 0)
      if (devind >= 0 && i <= devind) { dev = ""; devind = -1 }
      if (secind >= 0 && i <= secind) { sec = ""; secind = -1 }
      if ($0 ~ /^[[:space:]]*[A-Za-z0-9_.-]+:[[:space:]]*$/) {
        key = $0; sub(/^[[:space:]]*/, "", key); sub(/:[[:space:]]*$/, "", key)
        if (key ~ /^(ethernets|bridges|bonds|vlans|vrfs|wifis|tunnels|modems|dummy-devices|virtual-ethernets|nm-devices)$/) {
          sec = key; secind = i; dev = ""; devind = -1; next
        }
        if (secind >= 0 && devind < 0 && i > secind) { dev = key; devind = i; next }
      }
      if ($0 ~ re) print (sec == "" ? "unsectioned." : sec "." dev) " " FILENAME
    }
  ' "${files[@]}" 2>/dev/null
}

echo "Checking the bridge survives a reboot..."
IPONLY="${ADDR%/*}"
IPRE=$(printf '%s' "$IPONLY" | sed 's/\./\\./g')
ADDRRE="$IPRE/${ADDR#*/}"
if [[ "$(distro)" == ubuntu ]]; then
  check_persisted "a bridges: section defines br0 in the netplan configuration" \
    'bridges:' /etc/netplan/*.yaml /etc/netplan/*.yml
  check_persisted "$NIC is listed as a member of the bridge" \
    "(interfaces:.*${NIC}|^[[:space:]]*-[[:space:]]+${NIC}[[:space:]]*\$)" \
    /etc/netplan/*.yaml /etc/netplan/*.yml
  ONBRIDGE=no
  [[ -n "$(netplan_addr_owner "$ADDR" | grep -E '^bridges\.(br0)? ')" ]] && ONBRIDGE=yes
  ELSEWHERE=$(netplan_addr_owner "$IPONLY" | grep -Ev '^bridges\.(br0)? ' |
    sed 's/ / in /' | sort -u | tr '\n' ' ' | sed 's/ *$//')
  check_eq "$ADDR is written under bridges: br0: in the netplan configuration, so the bridge holds it after a reboot" \
    "yes" "$ONBRIDGE"
  check_eq "no netplan file still configures $IPONLY outside br0, on $NIC or anywhere else" \
    "" "$ELSEWHERE"
else
  check_persisted "a NetworkManager connection of type bridge exists" \
    '^type=bridge' /etc/NetworkManager/system-connections/*.nmconnection
  check_persisted "a NetworkManager connection makes a port of br0" \
    '^(master|controller)=br0' /etc/NetworkManager/system-connections/*.nmconnection
  # Same reasoning as the netplan branch: the installer's own connection file
  # already carries this address on the port, so what matters is which profile
  # holds it now. Sort the files that mention the address into the bridge
  # connection and everything else. A profile whose ipv4 method is disabled,
  # ignore or link-local never applies the addresses it lists, so it cannot put
  # the address back on the port; the files NetworkManager itself skips do not
  # count either.
  ONBRIDGE=no; ELSEWHERE=""
  for f in /etc/NetworkManager/system-connections/*.nmconnection \
           /etc/sysconfig/network-scripts/ifcfg-*; do
    [[ -f "$f" ]] || continue
    case "$f" in *.bak|*.old|*.orig|*.save|*.rpmsave|*.rpmnew|*~) continue ;; esac
    grep -Eq "^[[:space:]]*(address[0-9]*|IPADDR[0-9]*)=[\"']?${IPRE}([^0-9.]|\$)" "$f" || continue
    if grep -Eqi '^[[:space:]]*(type=bridge|TYPE=["]?Bridge)' "$f"; then
      grep -Eq "^[[:space:]]*address[0-9]*=[\"']?${ADDRRE}([^0-9]|\$)" "$f" && ONBRIDGE=yes
    else
      case "$(sed -n '/^\[ipv4\]/,/^\[/p' "$f" 2>/dev/null | sed -n 's/^method=//p' | head -1)" in
        disabled|ignore|link-local) ;;
        *) ELSEWHERE="$ELSEWHERE $f" ;;
      esac
    fi
  done
  check_eq "$ADDR is written into the connection of type bridge, so the bridge holds it after a reboot" \
    "yes" "$ONBRIDGE"
  check_eq "no connection file still configures $IPONLY on $NIC or on anything but the bridge" \
    "" "${ELSEWHERE# }"
  check_eq "nmcli reports br0 as a bridge connection" "bridge" \
    "$(nmcli -g connection.type con show br0 2>/dev/null)"
fi

summary
