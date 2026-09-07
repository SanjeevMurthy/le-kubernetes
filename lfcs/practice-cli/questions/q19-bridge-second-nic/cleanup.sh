#!/bin/bash
# Q19 bridge: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q19"
NIC=$(cat "$STATE/nic" 2>/dev/null)
ADDR=$(cat "$STATE/addr" 2>/dev/null)
CON=$(cat "$STATE/con" 2>/dev/null)
PAT='br0'

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

while read -r f; do [[ -n "$f" ]] && restore_file "$f" q19; done < <(list_netfiles)

while read -r f; do
  [[ -n "$f" ]] || continue
  grep -qE "$PAT" "$f" 2>/dev/null || continue
  if [[ -f "$STATE/orig" ]] && grep -Fxq "$f" "$STATE/orig"; then continue; fi
  rm -f "$f"
  echo "  Removed $f, which was written for this question."
done < <(list_netfiles)

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
if [[ -n "$NIC" && -n "$ADDR" ]]; then
  ip link set "$NIC" up >/dev/null 2>&1
  ip -o -4 addr show dev "$NIC" | grep -q . || ip addr replace "$ADDR" dev "$NIC" >/dev/null 2>&1
fi

rm -rf "${LFCS_STATE_DIR:?}/q19"

echo "Cleanup complete."
echo "  br0 is gone, ${ADDR:-the address} is back on ${NIC:-the second interface}, and the"
echo "  network configuration files were restored from the backup."
