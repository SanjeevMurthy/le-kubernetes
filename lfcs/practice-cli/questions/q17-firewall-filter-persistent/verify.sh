#!/bin/bash
# Q17 packet filtering: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

STATE="$LFCS_STATE_DIR/q17"
NS=fw-peer
HOSTIP=10.99.17.1

peer_tcp()  { in_peer "$NS" timeout 4 bash -c "exec 3<>/dev/tcp/$HOSTIP/$1"; }
peer_http() { in_peer "$NS" curl -s --max-time 4 "http://$HOSTIP:$1/"; }

echo "Control test: the lab network and every listener are up..."
check "the peer namespace $NS exists" ip netns pids "$NS"
LADDR="$(ss -H -ltn 2>/dev/null | awk '{print $4}' | tr '\n' ' ')"
for p in 80 9999 8080 4505 4506; do
  check_contains "a service is listening on $HOSTIP:$p" "$HOSTIP:$p " "$LADDR "
done
check_contains "sshd is listening on port 22" ":22 " "$LADDR "

echo "Effect test: what the peer can reach..."
check_contains "the peer reaches http on port 80" "fw-80" "$(peer_http 80)"
check "the peer can open a TCP connection to ssh on port 22" peer_tcp 22
check "the peer gets an answer to ping, so ICMP is accepted" \
  in_peer "$NS" ping -c1 -W3 "$HOSTIP"

echo "Effect test: what the peer must not reach..."
check_not "the peer cannot reach port 9999, so everything else is dropped" peer_tcp 9999

echo "Effect test: the three ports that must never be blocked..."
for p in 8080 4505 4506; do
  check "port $p is still reachable from the peer (blocking it ends the exam session)" peer_tcp "$p"
done

echo "Reading the live ruleset for a rule that drops one of those ports..."
RULES=$( { nft list ruleset 2>/dev/null; iptables-save 2>/dev/null; ip6tables-save 2>/dev/null; } )
for p in 8080 4505 4506; do
  BAD=$(printf '%s\n' "$RULES" | grep -Ei "(dport|--dport)[^A-Za-z0-9]*$p([^0-9]|\$).*(drop|reject)" | head -1)
  check_eq "no live rule drops or rejects $p" "" "$BAD"
done

echo "Checking the ruleset survives a reboot..."
PFILES=(/etc/nftables.conf /etc/sysconfig/nftables.conf /etc/ufw/user.rules
        /etc/iptables/rules.v4 /etc/sysconfig/iptables /etc/firewalld/zones/*.xml)
check_persisted "ssh is accepted in the saved firewall configuration" \
  '(^|[^0-9])22([^0-9]|$)|"ssh"' "${PFILES[@]}"
check_persisted "http is accepted in the saved firewall configuration" \
  '(^|[^0-9])80([^0-9]|$)|"http"' "${PFILES[@]}"
check_persisted "https is accepted in the saved firewall configuration" \
  '(^|[^0-9])443([^0-9]|$)|"https"' "${PFILES[@]}"
for p in 8080 4505 4506; do
  check_persisted "$p is accepted in the saved firewall configuration, so a reboot does not block it" \
    "(^|[^0-9])$p([^0-9]|\$)" "${PFILES[@]}"
done

echo "Checking something reloads that file at boot..."
BOOTSVC=none
for s in nftables firewalld ufw netfilter-persistent iptables; do
  systemctl is-enabled "$s" >/dev/null 2>&1 && BOOTSVC="$s"
done
if [[ "$BOOTSVC" == none ]] && command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -qi active; then
  BOOTSVC=ufw
fi
check_eq "a firewall service is enabled, so the saved rules come back after a reboot" \
  "yes" "$([[ "$BOOTSVC" != none ]] && echo yes || echo "no, nothing is enabled")"

summary
