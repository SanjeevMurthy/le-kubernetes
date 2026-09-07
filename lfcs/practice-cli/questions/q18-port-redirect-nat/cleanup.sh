#!/bin/bash
# Q18 port redirection and NAT: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q18"
OLD_FWD=$(cat "$STATE/ip_forward" 2>/dev/null)

if [[ -f "$STATE/pids" ]]; then
  while read -r pid; do [[ -n "$pid" ]] && kill "$pid" 2>/dev/null; done < "$STATE/pids"
fi
del_netns_peer nat-peer
del_netns_peer nat-out

iptables -t nat -D PREROUTING -p tcp --dport 8081 -j REDIRECT --to-port 8080 >/dev/null 2>&1
iptables -t nat -D POSTROUTING -s 10.99.18.0/24 -j MASQUERADE >/dev/null 2>&1
if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active firewalld >/dev/null 2>&1; then
  firewall-cmd --permanent --remove-forward-port=port=8081:proto=tcp:toport=8080 >/dev/null 2>&1
  firewall-cmd --permanent --remove-masquerade >/dev/null 2>&1
  firewall-cmd --reload >/dev/null 2>&1
elif nft list ruleset 2>/dev/null | grep -qE 'redirect to :8080|masquerade'; then
  nft flush ruleset >/dev/null 2>&1
fi

restore_file /etc/nftables.conf q18
restore_file /etc/sysconfig/nftables.conf q18

[[ -n "$OLD_FWD" ]] && sysctl -q -w "net.ipv4.ip_forward=$OLD_FWD" >/dev/null 2>&1

rm -rf "${LFCS_STATE_DIR:?}/q18"

echo "Cleanup complete."
echo "  Both peer namespaces, both servers and the lab nat rules are gone."
echo "  net.ipv4.ip_forward is back to ${OLD_FWD:-its original value} at runtime."
echo "  A drop-in you wrote under /etc/sysctl.d is left in place; remove it by hand if you want it gone."
