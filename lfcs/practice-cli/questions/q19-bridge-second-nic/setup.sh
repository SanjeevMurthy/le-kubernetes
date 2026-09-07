#!/bin/bash
# Q19 bridge: record the second interface, its address and whether its gateway
# answers today, then make sure no br0 from an earlier attempt is in the way.
# Setup deliberately leaves the interface alone: moving its address is the task.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q19"
mkdir -p "$STATE/removed"
PAT='br0'

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

NIC=$(cat "$STATE/nic" 2>/dev/null)
if [[ -z "$NIC" ]]; then
  NIC=$(second_nic)
  [[ -n "$NIC" ]] || { echo "No second network interface found. This question needs the nic2 tag."; exit 1; }
  echo "$NIC" > "$STATE/nic"
fi

# The address to move. Take it from the interface, or from br0 if a previous
# attempt already moved it there.
ADDR=$(cat "$STATE/addr" 2>/dev/null)
if [[ -z "$ADDR" ]]; then
  ADDR=$(ip -o -4 addr show dev "$NIC" 2>/dev/null | awk '{print $4}' | head -1)
  [[ -n "$ADDR" ]] || ADDR=$(ip -o -4 addr show dev br0 2>/dev/null | awk '{print $4}' | head -1)
  [[ -n "$ADDR" ]] || { echo "$NIC has no IPv4 address, so there is nothing to move onto a bridge."; exit 1; }
  echo "$ADDR" > "$STATE/addr"
fi
IPONLY=${ADDR%/*}
GW="${IPONLY%.*}.1"
echo "$GW" > "$STATE/gw"

CON=""
if [[ "$(distro)" == rocky ]]; then
  CON=$(nmcli -t -f NAME,DEVICE con show 2>/dev/null | awk -F: -v d="$NIC" '$2==d {print $1; exit}')
  echo "$CON" > "$STATE/con"
fi

while read -r f; do
  [[ -n "$f" ]] || continue
  b="$LFCS_STATE_DIR/backup/q19/$(echo "$f" | tr / _)"
  [[ -f "$b" ]] && restore_file "$f" q19
done < <(list_netfiles)

[[ -f "$STATE/orig" ]] || list_netfiles > "$STATE/orig"

while read -r f; do
  [[ -n "$f" ]] || continue
  grep -qE "$PAT" "$f" 2>/dev/null || continue
  if grep -Fxq "$f" "$STATE/orig"; then
    echo "  Warning: $f still mentions br0 and is one of this host's own files. Check it by hand."
  else
    mv -f "$f" "$STATE/removed/$(basename "$f")"
    echo "  Moved $f into $STATE/removed (it was written by an earlier attempt)."
  fi
done < <(list_netfiles)

while read -r f; do [[ -n "$f" ]] && backup_file "$f" q19; done < <(list_netfiles)

if [[ "$(distro)" == rocky ]]; then
  for c in $(nmcli -t -f NAME,TYPE con show 2>/dev/null | awk -F: '$2=="bridge" || $1 ~ /^br0/ {print $1}'); do
    nmcli con delete "$c" >/dev/null 2>&1
  done
  nmcli con reload >/dev/null 2>&1
  [[ -n "$CON" ]] && nmcli con up "$CON" >/dev/null 2>&1
else
  netplan apply >/dev/null 2>&1
fi
ip link del br0 >/dev/null 2>&1

# Bring the address back if an earlier attempt left the interface bare.
ip -o -4 addr show dev "$NIC" | grep -q . || ip addr replace "$ADDR" dev "$NIC" >/dev/null 2>&1
ip link set "$NIC" up >/dev/null 2>&1

# Whether the gateway answers today decides whether verify may grade reachability.
GWPING=no
ping -c1 -W2 "$GW" >/dev/null 2>&1 && GWPING=yes
echo "$GWPING" > "$STATE/gwping"

echo "Setup complete."
echo "  Second interface:  $NIC"
echo "  Address to move:   $ADDR (currently on $NIC)"
echo "  Gateway:           $GW, answers ping right now: $GWPING"
[[ -n "$CON" ]] && echo "  NetworkManager con: $CON"
echo "  Bridge wanted:     br0, with $NIC as a port and $ADDR on the bridge"
echo "  br0 exists now:    $(ip -br link show br0 2>/dev/null | awk '{print $1}' || echo no)"
if [[ "$(distro)" == ubuntu ]]; then
  echo "  Persistence file:  a bridges: section in the netplan YAML under /etc/netplan"
  echo "  Use netplan try. It rolls the change back by itself if the session dies."
else
  echo "  Persistence files: /etc/NetworkManager/system-connections/br0.nmconnection and the port connection"
fi
echo "  Turn spanning tree off, or the port takes about 30 seconds to start forwarding."
