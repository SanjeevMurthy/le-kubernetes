#!/bin/bash
# Q22 unreachable web app: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

STATE="$LFCS_STATE_DIR/q22"
NS=dbg-peer
HOSTIP=10.99.22.1
DIR="$COURSE_DIR/22"
PFILE=$(cat "$STATE/pfile" 2>/dev/null)
[[ -n "$PFILE" ]] || { PFILE=/etc/nftables.conf; [[ "$(distro)" == rocky ]] && PFILE=/etc/sysconfig/nftables.conf; }

echo "Control test: the application is running and answers on loopback..."
check_eq "labapp is running" "active" "$(systemctl is-active labapp 2>/dev/null)"
check_contains "http://127.0.0.1:8082/ returns app-ok on this host" "app-ok" \
  "$(curl -s --max-time 4 http://127.0.0.1:8082/ 2>/dev/null)"
check "the peer namespace $NS exists" ip netns pids "$NS"

echo "Cause one, the bind address: checking the socket..."
LADDR="$(ss -H -ltn 2>/dev/null | awk '{print $4}' | tr '\n' ' ') "
BOUND=no
for a in "0.0.0.0:8082" "*:8082" "[::]:8082" "$HOSTIP:8082"; do
  [[ "$LADDR" == *"$a "* ]] && BOUND=yes
done
check_eq "the socket on 8082 is no longer bound to loopback only" "yes" "$BOUND"
check_contains "the host reaches the application on its own network address" "app-ok" \
  "$(curl -s --max-time 4 "http://$HOSTIP:8082/" 2>/dev/null)"

echo "Cause two, the packet filter: checking what the peer gets..."
check_contains "the peer gets app-ok from http://$HOSTIP:8082/" "app-ok" \
  "$(in_peer "$NS" curl -s --max-time 4 "http://$HOSTIP:8082/" 2>/dev/null)"
LIVEBAD=$(nft list ruleset 2>/dev/null | grep -E 'dport[^0-9]*8082' | grep -Ei 'drop|reject' | head -1)
check_eq "no live rule drops or rejects 8082" "" "$LIVEBAD"

echo "Checking both fixes survive a reboot..."
# Grade the configuration systemd will actually use, not one spelling of it in
# one file. A drop-in that resets ExecStart= and sets it again is exactly as
# reboot-proof as editing the unit, and deleting --bind is exactly as correct as
# changing its argument, because python's http.server then listens on every
# address. So the only thing the unit must not do is bind the socket to
# loopback; that the socket is reachable is already established above.
UNITFILES=()
while read -r p; do
  [[ "$p" == /* && -f "$p" ]] && UNITFILES+=("$p")
done < <(systemctl show -p FragmentPath -p DropInPaths --value labapp 2>/dev/null | tr ' ' '\n')
[[ ${#UNITFILES[@]} -gt 0 ]] || UNITFILES=(/etc/systemd/system/labapp.service)
check_persisted "the unit systemd loads for labapp is a file on disk that starts the application" \
  '^[[:space:]]*ExecStart=.*http\.server[[:space:]]+8082' "${UNITFILES[@]}"
check_eq "the ExecStart systemd would run after a reboot no longer binds loopback" "" \
  "$(systemctl show -p ExecStart --value labapp 2>/dev/null |
     grep -Eio '[-]{1,2}b[a-z]*[=[:space:]]+(127(\.[0-9]{1,3}){3}|localhost|::1)' | head -1)"
# A drop-in under /run is gone at the next boot, so it cannot be where the fix
# lives, however good the effective configuration looks right now.
RUNTIME_UNITS=""
for p in "${UNITFILES[@]}"; do
  case "$p" in
    /run/*) grep -Eq '^[[:space:]]*ExecStart=' "$p" && RUNTIME_UNITS="$RUNTIME_UNITS $p" ;;
  esac
done
check_eq "no runtime-only unit file under /run supplies the ExecStart, which a reboot would discard" \
  "" "${RUNTIME_UNITS# }"
check_eq "no saved nftables file still drops 8082 at the next boot" "" \
  "$(grep -lE '8082[^0-9]*(drop|reject)|(drop|reject)[^0-9]*8082' \
      /etc/nftables.conf /etc/sysconfig/nftables.conf /etc/iptables/rules.v4 \
      /etc/sysconfig/iptables 2>/dev/null | tr '\n' ' ' | sed 's/ *$//')"
check_eq "labapp starts at boot" "enabled" "$(systemctl is-enabled labapp 2>/dev/null)"

echo "Checking the write-up..."
check "$DIR/causes.txt exists" test -s "$DIR/causes.txt"
CAUSES=$(cat "$DIR/causes.txt" 2>/dev/null)
B=no; printf '%s' "$CAUSES" | grep -Eqi '127\.0\.0\.1|bind' && B=yes
F=no; printf '%s' "$CAUSES" | grep -Eqi 'nft|firewall|drop|iptables' && F=yes
check_eq "causes.txt names the bind address as one cause" "yes" "$B"
check_eq "causes.txt names the packet filter as the other cause" "yes" "$F"

summary
