#!/bin/bash
# Q17 packet filtering: build a peer host on 10.99.17.0/24, put six listeners on
# the host address, and clear the firewall down to a starting state.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q17"
mkdir -p "$STATE/www"
NS=fw-peer
HOSTIP=10.99.17.1
PORTS="80 9999 8080 4505 4506"

PEERIP=$(make_netns_peer "$NS" 17)

start_listener() {
  # Two statements: within a single local, $p is not yet set when dir is
  # expanded, so every port would have shared one document root and served the
  # wrong body.
  local p="$1" i=0
  local dir="$STATE/www/$p"
  mkdir -p "$dir"
  printf 'fw-%s\n' "$p" > "$dir/index.html"
  if curl -s --max-time 2 -o /dev/null "http://$HOSTIP:$p/" 2>/dev/null; then
    return 0
  fi
  nohup python3 -m http.server "$p" --bind "$HOSTIP" --directory "$dir" >/dev/null 2>&1 &
  echo $! >> "$STATE/pids"
  while [[ $i -lt 25 ]]; do
    curl -s --max-time 1 -o /dev/null "http://$HOSTIP:$p/" 2>/dev/null && return 0
    i=$((i + 1))
    sleep 0.2
  done
  echo "  Warning: nothing answers on $HOSTIP:$p"
  return 0
}

for p in $PORTS; do start_listener "$p"; done

backup_file /etc/nftables.conf q17
backup_file /etc/sysconfig/nftables.conf q17
backup_file /etc/default/ufw q17
backup_file /etc/ufw/user.rules q17

[[ -f "$STATE/nftables-enabled" ]] || systemctl is-enabled nftables > "$STATE/nftables-enabled" 2>/dev/null
[[ -f "$STATE/ufw" ]]             || { ufw status 2>/dev/null | head -1 > "$STATE/ufw"; }
[[ -f "$STATE/firewalld" ]]       || systemctl is-active firewalld > "$STATE/firewalld" 2>/dev/null

if [[ "$(distro)" == rocky ]] && command -v firewall-cmd >/dev/null 2>&1; then
  FRONT=firewalld
  systemctl enable --now firewalld >/dev/null 2>&1
  for p in 80 443 9999 8080 4505 4506; do
    firewall-cmd --permanent --remove-port="$p/tcp" >/dev/null 2>&1
    firewall-cmd --remove-port="$p/tcp" >/dev/null 2>&1
  done
  for s in http https; do
    firewall-cmd --permanent --remove-service="$s" >/dev/null 2>&1
    firewall-cmd --remove-service="$s" >/dev/null 2>&1
  done
  firewall-cmd --reload >/dev/null 2>&1
else
  FRONT=nftables
  if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -qi active; then
    ufw --force disable >/dev/null 2>&1
  fi
  systemctl stop nftables >/dev/null 2>&1
  systemctl disable nftables >/dev/null 2>&1
  nft flush ruleset >/dev/null 2>&1
  if [[ -f /etc/nftables.conf ]] && grep -qE '4505|4506' /etc/nftables.conf; then
    restore_file /etc/nftables.conf q17
    backup_file /etc/nftables.conf q17
  fi
fi
echo "$FRONT" > "$STATE/front"

echo "Setup complete."
echo "  Peer host:        $PEERIP in network namespace $NS"
echo "  This host:        $HOSTIP on veth-$NS"
echo "  Listeners on $HOSTIP: $PORTS, plus sshd on 22"
echo "  Reach the peer with: ip netns exec $NS curl -s --max-time 3 http://$HOSTIP:80/"
if [[ "$FRONT" == firewalld ]]; then
  echo "  Front end:        firewalld, active, zone $(firewall-cmd --get-default-zone 2>/dev/null)"
  echo "  Open right now:   $(firewall-cmd --list-services 2>/dev/null) $(firewall-cmd --list-ports 2>/dev/null)"
  echo "  Persistence:      firewall-cmd --permanent, then firewall-cmd --reload"
else
  echo "  Front end:        raw nftables. The live ruleset has been flushed and ufw is disabled."
  echo "  Rules now:        $(nft list ruleset 2>/dev/null | grep -c .) lines"
  echo "  Persistence:      nft list ruleset > /etc/nftables.conf, then systemctl enable --now nftables"
fi
echo "  Accept 22, 80, 443, ICMP, loopback and established, drop the rest."
echo "  Accept 8080, 4505 and 4506 as well. Blocking those three ends a real exam session."
