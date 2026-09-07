#!/bin/bash
# Q12 static IPv4 on the second NIC: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q12"
NIC=$(cat "$STATE/nic" 2>/dev/null)
CON=$(cat "$STATE/con" 2>/dev/null)
PAT='10\.50\.0\.'

TARGET_IP=10.50.0.10
[[ "$(distro)" == rocky ]] && TARGET_IP=10.50.0.20

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

while read -r f; do [[ -n "$f" ]] && restore_file "$f" q12; done < <(list_netfiles)

# Remove any file the candidate added that still carries the lab address.
while read -r f; do
  [[ -n "$f" ]] || continue
  grep -qE "$PAT" "$f" 2>/dev/null || continue
  if [[ -f "$STATE/orig" ]] && grep -Fxq "$f" "$STATE/orig"; then continue; fi
  rm -f "$f"
  echo "  Removed $f, which was written for this question."
done < <(list_netfiles)

if [[ "$(distro)" == ubuntu ]]; then
  netplan apply >/dev/null 2>&1
else
  nmcli con reload >/dev/null 2>&1
  [[ -n "$CON" ]] && nmcli con up "$CON" >/dev/null 2>&1
fi

[[ -n "$NIC" ]] && ip addr del "$TARGET_IP/24" dev "$NIC" >/dev/null 2>&1

rm -rf "${LFCS_STATE_DIR:?}/q12"

echo "Cleanup complete."
echo "  $TARGET_IP/24 removed from ${NIC:-the lab interface} and from the network configuration."
echo "  The host's own netplan or NetworkManager files were restored from the backup."
