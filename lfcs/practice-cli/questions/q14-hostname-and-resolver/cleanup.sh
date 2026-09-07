#!/bin/bash
# Q14 hostname and resolver: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q14"
PAT='1\.1\.1\.1|9\.9\.9\.9'
OLD=$(cat "$STATE/hostname" 2>/dev/null)

list_netfiles() {
  local f
  if [[ "$(distro)" == ubuntu ]]; then
    for f in /etc/netplan/*.yaml /etc/netplan/*.yml; do [[ -f "$f" ]] && echo "$f"; done
  else
    for f in /etc/NetworkManager/system-connections/*.nmconnection /etc/sysconfig/network-scripts/ifcfg-*; do
      [[ -f "$f" ]] && echo "$f"
    done
  fi
  for f in /etc/systemd/resolved.conf /etc/systemd/resolved.conf.d/*.conf; do
    [[ -f "$f" ]] && echo "$f"
  done
  return 0
}

while read -r f; do [[ -n "$f" ]] && restore_file "$f" q14; done < <(list_netfiles)

while read -r f; do
  [[ -n "$f" ]] || continue
  grep -qE "$PAT" "$f" 2>/dev/null || continue
  if [[ -f "$STATE/orig" ]] && grep -Fxq "$f" "$STATE/orig"; then continue; fi
  rm -f "$f"
  echo "  Removed $f, which was written for this question."
done < <(list_netfiles)

restore_file /etc/hosts q14
restore_file /etc/hostname q14

if [[ -n "$OLD" ]]; then
  hostnamectl set-hostname "$OLD" >/dev/null 2>&1
fi

if [[ "$(distro)" == ubuntu ]]; then
  netplan apply >/dev/null 2>&1
else
  nmcli con reload >/dev/null 2>&1
fi
systemctl restart systemd-resolved >/dev/null 2>&1

rm -rf "${LFCS_STATE_DIR:?}/q14"

echo "Cleanup complete."
echo "  Hostname back to ${OLD:-the original name}, /etc/hosts and the resolver configuration restored."
