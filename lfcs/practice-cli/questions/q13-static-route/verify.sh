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

# The gateway address on its own proves nothing in these files. The interface
# already carries 192.168.56.10/24, and that string contains 192.168.56.1, so a
# plain grep for the gateway passes on a file where no route was ever written.
# Both branches below therefore insist on the destination and the gateway
# together, inside one route entry.
GWRE=${GW//./\\.}

# netplan_routes prints one "to=<dest>,via=<gw>;" token per route entry found in
# the netplan files. A netplan route is a list item with to: and via: keys, which
# may be on one line or on several, so the entry has to be reassembled first.
netplan_routes() {
  local f
  for f in "$@"; do
    [[ -f "$f" ]] || continue
    awk '
      BEGIN { q = sprintf("%c%c", 34, 39); indent = -1; buf = "" }
      function emit(   n, i, a, to, via) {
        if (buf == "") return
        n = split(buf, a, /[ \t]+/)
        to = ""; via = ""
        for (i = 1; i < n; i++) {
          if (a[i] == "to:")  { to  = a[i + 1] }
          if (a[i] == "via:") { via = a[i + 1] }
        }
        if (to != "" || via != "")
          printf "to=%s,via=%s; ", (to == "" ? "none" : to), (via == "" ? "none" : via)
        buf = ""
      }
      {
        line = $0
        sub(/#.*/, "", line)
        gsub("[" q "{},]", " ", line)
        if (line ~ /^[ \t]*$/) next
        match(line, /^[ \t]*/)
        col = RLENGTH
        if (line ~ /^[ \t]*-([ \t]|$)/) {
          emit()
          indent = col
          sub(/^[ \t]*-[ \t]*/, "", line)
          buf = line
        } else if (indent >= 0 && col > indent) {
          buf = buf " " line
        } else {
          emit()
          indent = col
          buf = line
        }
      }
      END { emit() }
    ' "$f"
  done
}

if [[ "$(distro)" == ubuntu ]]; then
  check_persisted "10.200.0.0/16 is written into the netplan configuration as a route destination, a to: key" \
    "^[^#]*[[:space:]{,]to:[[:space:]]*[\"']?10\.200\.0\.0/16" \
    /etc/netplan/*.yaml /etc/netplan/*.yml
  # The trailing semicolon is what stops via=192.168.56.10 from satisfying a
  # check for via=192.168.56.1.
  check_contains "the same netplan route entry sends 10.200.0.0/16 via $GW" \
    "to=10.200.0.0/16,via=$GW;" "$(netplan_routes /etc/netplan/*.yaml /etc/netplan/*.yml)"
else
  check_persisted "a route to 10.200.0.0/16 via $GW is written into the NetworkManager connection" \
    "(^route[0-9]+=10\.200\.0\.0/16,[[:space:]]*$GWRE([,[:space:]]|\$))|(^[[:space:]]*10\.200\.0\.0/16[[:space:]]+via[[:space:]]+$GWRE([[:space:]]|\$))" \
    /etc/NetworkManager/system-connections/*.nmconnection \
    /etc/sysconfig/network-scripts/route-* /etc/sysconfig/network-scripts/ifcfg-*
  if [[ -n "$CON" ]]; then
    check_contains "nmcli reports the route on connection $CON" "10.200.0.0/16" \
      "$(nmcli -g ipv4.routes con show "$CON" 2>/dev/null)"
  fi
fi

summary
