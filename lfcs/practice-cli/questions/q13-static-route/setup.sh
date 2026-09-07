#!/bin/bash
# Q13 persistent static route: name the lab interface and its gateway, remove any
# route to 10.200.0.0/16 from the kernel and from the network configuration.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q13"
mkdir -p "$STATE/removed"
PAT='10\.200\.0\.0/16'

second_nic() {
  local pri nic
  pri=$(ip -o route show default 2>/dev/null | awk '{print $5}' | head -1)
  for nic in $(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | sed 's/@.*//'); do
    case "$nic" in
      lo|docker*|veth*|virbr*|br-*|br0|podman*|cni*|tun*|tap*|wg*|bond*|dummy*|nft*) continue ;;
    esac
    [[ "$nic" == "$pri" ]] && continue
    echo "$nic"; return 0
  done
  return 1
}

list_netfiles() {
  local f
  if [[ "$(distro)" == ubuntu ]]; then
    for f in /etc/netplan/*.yaml /etc/netplan/*.yml; do [[ -f "$f" ]] && echo "$f"; done
  else
    for f in /etc/NetworkManager/system-connections/*.nmconnection /etc/sysconfig/network-scripts/ifcfg-*; do
      [[ -f "$f" ]] && echo "$f"
    done
  fi
  return 0
}

NIC=$(second_nic)
if [[ -z "$NIC" ]]; then
  echo "No second network interface found. This question needs the nic2 tag."
  exit 1
fi
echo "$NIC" > "$STATE/nic"

CIDR=$(ip -o -4 addr show dev "$NIC" 2>/dev/null | awk '{print $4}' | head -1)
if [[ -z "$CIDR" ]]; then
  echo "$NIC has no IPv4 address, so no gateway can be reached through it."
  echo "Give it an address first, for example with question 12."
  exit 1
fi
IPONLY=${CIDR%/*}
GW="${IPONLY%.*}.1"
echo "$GW" > "$STATE/gw"

CON=""
if [[ "$(distro)" == rocky ]]; then
  CON=$(nmcli -t -f NAME,DEVICE con show 2>/dev/null | awk -F: -v d="$NIC" '$2==d {print $1; exit}')
  echo "$CON" > "$STATE/con"
fi

while read -r f; do
  [[ -n "$f" ]] || continue
  b="$LFCS_STATE_DIR/backup/q13/$(echo "$f" | tr / _)"
  [[ -f "$b" ]] && restore_file "$f" q13
done < <(list_netfiles)

[[ -f "$STATE/orig" ]] || list_netfiles > "$STATE/orig"

while read -r f; do
  [[ -n "$f" ]] || continue
  grep -qE "$PAT" "$f" 2>/dev/null || continue
  if grep -Fxq "$f" "$STATE/orig"; then
    echo "  Warning: $f still mentions 10.200.0.0/16 and is one of this host's own files. Check it by hand."
  else
    mv -f "$f" "$STATE/removed/$(basename "$f")"
    echo "  Moved $f into $STATE/removed (it was written by an earlier attempt)."
  fi
done < <(list_netfiles)

while read -r f; do [[ -n "$f" ]] && backup_file "$f" q13; done < <(list_netfiles)

if [[ "$(distro)" == ubuntu ]]; then
  netplan apply >/dev/null 2>&1
else
  nmcli con reload >/dev/null 2>&1
  [[ -n "$CON" ]] && nmcli con up "$CON" >/dev/null 2>&1
fi

n=0
while ip route show 10.200.0.0/16 2>/dev/null | grep -q . && [[ $n -lt 10 ]]; do
  ip route del 10.200.0.0/16 >/dev/null 2>&1 || break
  n=$((n + 1))
done

# Prove the gateway is usable before asking for a route through it.
GWOK=no
if ip route add 10.201.0.0/16 via "$GW" dev "$NIC" >/dev/null 2>&1; then
  GWOK=yes
  ip route del 10.201.0.0/16 >/dev/null 2>&1
fi

echo "Setup complete."
echo "  Second interface:  $NIC ($CIDR)"
[[ -n "$CON" ]] && echo "  NetworkManager con: $CON"
echo "  Gateway to use:    $GW"
echo "  Route wanted:      10.200.0.0/16 via $GW dev $NIC"
if [[ "$GWOK" == yes ]]; then
  echo "  The kernel accepts $GW as a next hop on $NIC."
else
  echo "  Warning: the kernel refused a test route through $GW. Check the address on $NIC first."
fi
echo "  Live routes on $NIC now: $(ip -o route show dev "$NIC" | awk '{print $1}' | tr '\n' ' ')"
if [[ "$(distro)" == ubuntu ]]; then
  echo "  Persistence file:  the netplan YAML under /etc/netplan that already configures $NIC"
else
  echo "  Persistence file:  /etc/NetworkManager/system-connections/*.nmconnection"
fi
