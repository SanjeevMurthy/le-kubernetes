#!/bin/bash
# Q17 packet filtering: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q17"
NS=fw-peer
FRONT=$(cat "$STATE/front" 2>/dev/null)

if [[ -f "$STATE/pids" ]]; then
  while read -r pid; do [[ -n "$pid" ]] && kill "$pid" 2>/dev/null; done < "$STATE/pids"
fi
del_netns_peer "$NS"

if [[ "$FRONT" == firewalld ]]; then
  for p in 80 443 9999 8080 4505 4506; do
    firewall-cmd --permanent --remove-port="$p/tcp" >/dev/null 2>&1
    firewall-cmd --remove-port="$p/tcp" >/dev/null 2>&1
  done
  for s in http https; do
    firewall-cmd --permanent --remove-service="$s" >/dev/null 2>&1
    firewall-cmd --remove-service="$s" >/dev/null 2>&1
  done
  firewall-cmd --reload >/dev/null 2>&1
  [[ "$(cat "$STATE/firewalld" 2>/dev/null)" == active ]] || systemctl disable --now firewalld >/dev/null 2>&1
else
  command -v ufw >/dev/null 2>&1 && ufw --force disable >/dev/null 2>&1
  nft flush ruleset >/dev/null 2>&1
  systemctl stop nftables >/dev/null 2>&1
fi

restore_file /etc/nftables.conf q17
restore_file /etc/sysconfig/nftables.conf q17
restore_file /etc/default/ufw q17
restore_file /etc/ufw/user.rules q17

if [[ "$(cat "$STATE/nftables-enabled" 2>/dev/null)" == enabled ]]; then
  systemctl enable --now nftables >/dev/null 2>&1
else
  systemctl disable nftables >/dev/null 2>&1
fi
if grep -qi active "$STATE/ufw" 2>/dev/null; then
  ufw --force enable >/dev/null 2>&1
fi

rm -rf "${LFCS_STATE_DIR:?}/q17"

echo "Cleanup complete."
echo "  The peer namespace, the veth pair and the six listeners are gone."
echo "  The saved firewall files were restored and the front end put back the way setup found it."
echo "  The live ruleset was flushed rather than rebuilt, so reboot the host if you want it exactly as it was."
