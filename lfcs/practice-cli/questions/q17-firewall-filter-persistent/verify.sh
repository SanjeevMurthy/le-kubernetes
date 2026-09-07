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

# ─── the three exam ports, read out of the saved configuration ─────
# The Linux Foundation rule is that 8080, 4505 and 4506 are never blocked, in a
# live rule or in a saved file. Looking for the digits alone passes a file that
# holds "ufw deny 8080", or an nftables file that drops the port while the live
# ruleset happens to accept it, which is the exact mistake that ends the session
# at the next boot. So each back end's file is read on its own terms and has to
# say accept.
saved_port_state() {   # saved_port_state file port -> accept | deny | (nothing)
  local f="$1" p="$2" w
  w="[^0-9]$p([^0-9]|\$)"          # the port as a number of its own, never 80 inside 8080
  [[ -f "$f" ]] || return 0
  case "$f" in
    */firewalld/*.xml)
      # firewalld: <port port="8080" protocol="tcp"/> accepts. A rich <rule>
      # block spans several lines, so the block is collected whole before its
      # verdict, <accept/>, <drop/> or <reject/>, is known.
      awk -v p="$p" '
        /<rule/    { inrule = 1; blk = "" }
        inrule     { blk = blk " " $0 }
        /<\/rule>/ { if (inrule && blk ~ ("port=\"" p "\"")) {
                       if (blk ~ /<drop/ || blk ~ /<reject/) d = 1
                       else if (blk ~ /<accept/)             a = 1
                     }
                     inrule = 0 }
        !inrule && $0 ~ ("<port[^>]*port=\"" p "\"") { a = 1 }
        END { if (d) print "deny"; else if (a) print "accept" }' "$f"
      ;;
    */nftables.conf)
      # nft syntax: "tcp dport 8080 accept", or a set, "tcp dport { 8080, 4505,
      # 4506 } accept". The verdict is the last word of the rule.
      if grep -Eq -- "dport.*$w.*(drop|reject)" "$f"; then echo deny
      elif grep -Eq -- "dport.*$w.*accept" "$f"; then echo accept
      fi
      ;;
    */user.rules|*/rules.v4|*/sysconfig/iptables)
      # iptables-save syntax, which is what ufw writes into user.rules too, with
      # ufw's own "### tuple ###" line above each rule. "ufw deny 8080" lands
      # here as a DROP, and "ufw reject 8080" as a REJECT.
      if grep -Eq -- "--dports?.*$w.*-j[[:space:]]+(DROP|REJECT)" "$f" ||
         grep -Eq -- "^### tuple ### (deny|reject) [^ ]+ $p([^0-9]|\$)" "$f"; then echo deny
      elif grep -Eq -- "--dports?.*$w.*-j[[:space:]]+ACCEPT" "$f"; then echo accept
      fi
      ;;
  esac
}

ANSWER_FILES=()
remember_answer_file() {
  local f="$1" g
  for g in "${ANSWER_FILES[@]}"; do [[ "$g" == "$f" ]] && return 0; done
  ANSWER_FILES+=("$f")
  return 0
}

echo "Checking the saved configuration accepts the three ports, rather than merely naming them..."
for p in 8080 4505 4506; do
  ACCFILE=""; DENYFILE=""
  for f in "${PFILES[@]}"; do
    [[ -f "$f" ]] || continue
    case "$(saved_port_state "$f" "$p")" in
      deny)   [[ -z "$DENYFILE" ]] && DENYFILE="$f" ;;
      accept) [[ -z "$ACCFILE" ]] && ACCFILE="$f"
              remember_answer_file "$f" ;;
    esac
  done
  if [[ -n "$DENYFILE" ]]; then
    echo "  FAIL: the saved configuration blocks $p ($DENYFILE denies, drops or rejects it, which ends the exam session at the next boot)"
    FAIL=$((FAIL + 1))
  elif [[ -n "$ACCFILE" ]]; then
    echo "  PASS: $p is accepted in the saved firewall configuration (in $ACCFILE)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: no saved firewall configuration accepts $p (looked in: ${PFILES[*]}; a reboot would block it)"
    FAIL=$((FAIL + 1))
  fi
done

# ─── the loader has to be the one that reads this answer ───────────
# "A firewall service is enabled" is not the same claim. On stock Ubuntu
# systemctl is-enabled ufw says enabled even when ufw is inactive and the answer
# was written in raw nftables, so that check passed while nothing would load the
# rules. Match the file the rules are actually in against the unit that reads it.
loader_for() {   # loader_for file -> the unit that restores it at boot
  case "$1" in
    */nftables.conf)                    echo nftables ;;
    */ufw/user.rules|*/ufw/user6.rules) echo ufw ;;
    */firewalld/*)                      echo firewalld ;;
    */iptables/rules.v4|*/iptables/rules.v6) echo netfilter-persistent ;;
    */sysconfig/iptables)               echo iptables ;;
    *)                                  echo none ;;
  esac
}

loader_ready() {   # loader_ready unit -> 0 when it will restore the rules at boot
  case "$1" in
    ufw)  systemctl is-enabled ufw >/dev/null 2>&1 &&
          ufw status 2>/dev/null | grep -qi "^Status: active" ;;
    netfilter-persistent)
          systemctl is-enabled netfilter-persistent >/dev/null 2>&1 ||
          systemctl is-enabled iptables >/dev/null 2>&1 ;;
    none) return 1 ;;
    *)    systemctl is-enabled "$1" >/dev/null 2>&1 ;;
  esac
}

echo "Checking the enabled service is the one that reloads that file at boot..."
if [[ ${#ANSWER_FILES[@]} -eq 0 ]]; then
  echo "  FAIL: no service can restore this answer, because no saved file accepts 8080, 4505 and 4506"
  FAIL=$((FAIL + 1))
else
  MATCH=""
  for f in "${ANSWER_FILES[@]}"; do
    U="$(loader_for "$f")"
    if loader_ready "$U"; then MATCH="$f, reloaded at boot by $U"; break; fi
  done
  if [[ -n "$MATCH" ]]; then
    echo "  PASS: the enabled service is the one that restores the saved rules ($MATCH)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: the rules are saved but nothing enabled will load them at boot"
    for f in "${ANSWER_FILES[@]}"; do
      U="$(loader_for "$f")"
      echo "        $f is restored by $U, and systemctl is-enabled $U says $(systemctl is-enabled "$U" 2>&1 | head -1)"
      [[ "$U" == ufw ]] &&
        echo "        ufw must also be active; ufw status says $(ufw status 2>/dev/null | head -1)"
    done
    FAIL=$((FAIL + 1))
  fi
fi

summary
