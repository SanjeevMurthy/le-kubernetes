#!/bin/bash
# Q18 port redirection and NAT: put this host between an inside network and an
# outside one, run the application on 8080, and log the source address the
# outside server sees so the masquerade can be proven rather than assumed.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q18"
mkdir -p "$STATE/www" "$STATE/out"
IN=nat-peer
OUT=nat-out
INIP=10.99.18.1
OUTIP=10.99.118.2

INPEER=$(make_netns_peer "$IN" 18)
make_netns_peer "$OUT" 118 >/dev/null

[[ -f "$STATE/ip_forward" ]] || sysctl -n net.ipv4.ip_forward > "$STATE/ip_forward" 2>/dev/null

# The application the redirect has to land on.
printf 'nat-ok\n' > "$STATE/www/index.html"
if ! curl -s --max-time 2 -o /dev/null "http://$INIP:8080/" 2>/dev/null; then
  nohup python3 -u -m http.server 8080 --bind "$INIP" --directory "$STATE/www" >/dev/null 2>&1 &
  echo $! >> "$STATE/pids"
fi

# The outside web server. It logs every request with its source address, which is
# the only honest way to tell a masqueraded packet from an unmasqueraded one.
printf 'out-ok\n' > "$STATE/out/index.html"
if ! curl -s --max-time 2 -o /dev/null "http://$OUTIP/" 2>/dev/null; then
  ip netns exec "$OUT" nohup python3 -u -m http.server 80 --bind "$OUTIP" \
    --directory "$STATE/out" >>"$STATE/out.log" 2>&1 &
  echo $! >> "$STATE/pids"
fi

i=0
while [[ $i -lt 25 ]]; do
  curl -s --max-time 1 -o /dev/null "http://$INIP:8080/" 2>/dev/null && break
  i=$((i + 1)); sleep 0.2
done
i=0
while [[ $i -lt 25 ]]; do
  curl -s --max-time 1 -o /dev/null "http://$OUTIP/" 2>/dev/null && break
  i=$((i + 1)); sleep 0.2
done

sysctl -q -w net.ipv4.ip_forward=1 >/dev/null 2>&1

backup_file /etc/nftables.conf q18
backup_file /etc/sysconfig/nftables.conf q18

# Point out any redirect or masquerade left by an earlier attempt rather than
# deleting a table this host may need for something else.
LEFTOVER=""
nft list ruleset 2>/dev/null | grep -qE 'redirect to :8080|masquerade' && LEFTOVER="nftables"
iptables -t nat -D PREROUTING -p tcp --dport 8081 -j REDIRECT --to-port 8080 >/dev/null 2>&1
iptables -t nat -D POSTROUTING -s 10.99.18.0/24 -j MASQUERADE >/dev/null 2>&1
if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active firewalld >/dev/null 2>&1; then
  firewall-cmd --permanent --remove-forward-port=port=8081:proto=tcp:toport=8080 >/dev/null 2>&1
  firewall-cmd --permanent --remove-masquerade >/dev/null 2>&1
  firewall-cmd --reload >/dev/null 2>&1
fi

if [[ "$(distro)" == ubuntu ]]; then
  PFILE=/etc/nftables.conf
else
  PFILE=/etc/sysconfig/nftables.conf
fi

echo "Setup complete."
echo "  Inside peer:      $INPEER, default route via $INIP"
echo "  Outside peer:     $OUTIP, this host is $( { ip -o -4 addr show dev veth-$OUT | awk '{print $4}'; } 2>/dev/null)"
echo "  Application:      $INIP:8080 answers 'nat-ok'"
echo "  Outside server:   http://$OUTIP/ answers 'out-ok' and logs the source address it sees"
echo "  net.ipv4.ip_forward is now $(sysctl -n net.ipv4.ip_forward 2>/dev/null), set at runtime only"
echo "  Wanted:           8081/tcp redirected to 8080, 10.99.18.0/24 masqueraded on the way out,"
echo "                    both persisted, and net.ipv4.ip_forward persisted under /etc/sysctl.d/"
echo "  Persistence file: $PFILE, or the firewalld permanent configuration"
echo "  Test with:        ip netns exec $IN curl -s --max-time 3 http://$INIP:8081/"
echo "                    ip netns exec $IN curl -s --max-time 3 http://$OUTIP/"
echo "  Do not redirect or drop 8080, 4505 or 4506. Port 8080 must still answer directly."
if [[ -n "$LEFTOVER" ]]; then
  echo "  Note: the live $LEFTOVER ruleset already holds a redirect or masquerade rule."
  echo "        Run cleanup for this question first if you want to start from nothing."
fi
