#!/bin/bash
# Q13 persistent static route: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q13"
CON=$(cat "$STATE/con" 2>/dev/null)
PAT='10\.200\.0\.0/16'

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

while read -r f; do [[ -n "$f" ]] && restore_file "$f" q13; done < <(list_netfiles)

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

n=0
while ip route show 10.200.0.0/16 2>/dev/null | grep -q . && [[ $n -lt 10 ]]; do
  ip route del 10.200.0.0/16 >/dev/null 2>&1 || break
  n=$((n + 1))
done

rm -rf "${LFCS_STATE_DIR:?}/q13"

echo "Cleanup complete."
echo "  The route to 10.200.0.0/16 is out of the kernel and out of the network configuration."
