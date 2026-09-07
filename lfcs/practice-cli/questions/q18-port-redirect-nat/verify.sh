#!/bin/bash
# Q18 port redirection and NAT: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

STATE="$LFCS_STATE_DIR/q18"
IN=nat-peer
OUT=nat-out
INIP=10.99.18.1
OUTIP=10.99.118.2
OUTHOST=10.99.118.1

echo "Control test: both networks and both servers are up..."
check "the inside peer namespace $IN exists" ip netns pids "$IN"
check "the outside peer namespace $OUT exists" ip netns pids "$OUT"
check_contains "the application on $INIP:8080 answers on this host" "nat-ok" \
  "$(curl -s --max-time 4 "http://$INIP:8080/" 2>/dev/null)"
check_contains "the outside server on $OUTIP answers on this host" "out-ok" \
  "$(curl -s --max-time 4 "http://$OUTIP/" 2>/dev/null)"

echo "Checking forwarding..."
check_eq "net.ipv4.ip_forward is 1 right now" "1" "$(sysctl -n net.ipv4.ip_forward 2>/dev/null)"
# Only the places a candidate writes. /usr/lib/sysctl.d and /run/sysctl.d are
# the distribution's own drop-ins: a value already set there is not the
# candidate's answer, and accepting them passes a host that was shipped with
# forwarding on while the candidate wrote nothing at all.
check_persisted "net.ipv4.ip_forward is written to a file under /etc, so forwarding survives a reboot" \
  '^[[:space:]]*net\.ipv4\.ip_forward[[:space:]]*=[[:space:]]*1' \
  /etc/sysctl.conf /etc/sysctl.d/*.conf

echo "Effect test: the redirect, from the peer..."
check_contains "the peer gets the 8080 page when it asks for $INIP:8081" "nat-ok" \
  "$(in_peer "$IN" curl -s --max-time 4 "http://$INIP:8081/" 2>/dev/null)"
check_contains "port 8080 still answers the peer directly, so it was not hijacked" "nat-ok" \
  "$(in_peer "$IN" curl -s --max-time 4 "http://$INIP:8080/" 2>/dev/null)"

echo "Effect test: the masquerade, read from the outside server's own log..."
# The control test above curled the outside server from this host, and that
# request logs $OUTHOST, the very address a masqueraded peer request logs. So
# reading the last line of the log proves nothing: it passes on the control's
# own line when the peer's request never arrived at all. Remember where the log
# ended, tag the peer's request with a marker only it carries, and read only
# what follows.
LOGBEFORE=$(wc -l < "$STATE/out.log" 2>/dev/null | tr -d ' ')
LOGBEFORE=${LOGBEFORE:-0}
MARK="q18peer-$$"
check "the inside peer can reach the outside network at all" \
  in_peer "$IN" curl -s --max-time 5 -o /dev/null "http://$OUTIP/?$MARK"
i=0
while [[ $i -lt 15 ]]; do
  LOGNOW=$(wc -l < "$STATE/out.log" 2>/dev/null | tr -d ' ')
  [[ "${LOGNOW:-0}" -gt "$LOGBEFORE" ]] && break
  i=$((i + 1)); sleep 0.2
done
SEEN=$(tail -n "+$((LOGBEFORE + 1))" "$STATE/out.log" 2>/dev/null |
       grep -F "$MARK" | tail -1 | awk '{print $1}')
check_eq "the outside server logs this host's address for the peer's own request, so the source was masqueraded" \
  "$OUTHOST" "${SEEN:-no log line from the peer request}"

echo "Reading the live ruleset..."
RULES=$( { nft list ruleset 2>/dev/null; iptables -t nat -S 2>/dev/null; } )
check_contains "a redirect or dnat rule for 8081 is loaded" "8081" "$RULES"
MASQ=$(printf '%s\n' "$RULES" | grep -Eic 'masquerade')
check "a masquerade rule is loaded" test "${MASQ:-0}" -ge 1

echo "Checking the rules survive a reboot..."
PFILES=(/etc/nftables.conf /etc/sysconfig/nftables.conf /etc/iptables/rules.v4
        /etc/sysconfig/iptables /etc/firewalld/zones/*.xml /etc/firewalld/direct.xml)
check_persisted "the redirect from 8081 is in the saved firewall configuration" \
  '8081' "${PFILES[@]}"
check_persisted "the masquerade is in the saved firewall configuration" \
  '[Mm]asquerade|MASQUERADE' "${PFILES[@]}"

echo "Checking something reloads that file at boot..."
BOOTSVC=none
for s in nftables firewalld netfilter-persistent iptables; do
  systemctl is-enabled "$s" >/dev/null 2>&1 && BOOTSVC="$s"
done
check_eq "a firewall service is enabled, so the saved rules come back after a reboot" \
  "yes" "$([[ "$BOOTSVC" != none ]] && echo yes || echo "no, nothing is enabled")"

summary
