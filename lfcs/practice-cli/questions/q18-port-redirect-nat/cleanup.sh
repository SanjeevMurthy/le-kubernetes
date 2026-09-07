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
fi

# ─── remove this question's own nat rules, never the whole ruleset ──
# What used to be here flushed the entire ruleset on seeing any masquerade rule.
# Every masquerade rule on the host matches that: docker, libvirt, podman and
# ufw all install one, and none of them were created by this question. Flushing
# erased the lot.
#
# This question's answer names itself: the inside network 10.99.18.0/24, the
# veth interfaces setup created, the 8081 that is redirected and the 8080 it is
# redirected to. Delete rules that say one of those, by handle, and leave the
# rest of the ruleset alone. A table holding iptables' built-in chains, or
# docker's, is shared with them, so there the rules go one at a time and the
# table stays; a table that is this answer's alone is deleted whole.
NATREMOVED=0

nat_own_tables() {
  nft -a list ruleset 2>/dev/null | awk '
    $1 == "table" { fam = $2; tbl = $3; next }
    /dport 8081/ || /redirect to :8080/ || /10\.99\.18\./ || /veth-nat-/ { print fam, tbl }' |
    sort -u
}

table_is_shared() {   # table_is_shared family table -> 0 when it is not ours alone
  # A table another tool owns, by its name or by the chains in it: iptables'
  # built-ins, docker's, libvirt's, and the filter_ and nat_ chains firewalld
  # writes. Rules go one at a time out of a table like this; it is never deleted.
  case "$2" in
    firewalld|docker*|libvirt*|podman*|cni*|nm-shared|ufw*) return 0 ;;
  esac
  nft list table "$1" "$2" 2>/dev/null |
    grep -Eq 'chain (INPUT|FORWARD|OUTPUT|PREROUTING|POSTROUTING|DOCKER|LIBVIRT|CNI-|ufw-|f2b-|filter_|nat_|mangle_)'
}

while read -r FAM TBL; do
  [[ -n "$FAM" && -n "$TBL" ]] || continue
  if table_is_shared "$FAM" "$TBL"; then
    while read -r f t c h; do
      [[ -n "$h" ]] || continue
      nft delete rule "$f" "$t" "$c" handle "$h" >/dev/null 2>&1 &&
        NATREMOVED=$((NATREMOVED + 1))
    done < <(nft -a list table "$FAM" "$TBL" 2>/dev/null |
             awk -v fam="$FAM" -v tbl="$TBL" '
               $1 == "chain" { ch = $2 }
               /# handle [0-9]+$/ &&
               (/dport 8081/ || /redirect to :8080/ || /10\.99\.18\./ || /veth-nat-/) {
                 print fam, tbl, ch, $NF }')
  else
    nft delete table "$FAM" "$TBL" >/dev/null 2>&1 && NATREMOVED=$((NATREMOVED + 1))
  fi
done < <(nat_own_tables)

# A masquerade rule written with neither a source network nor an outgoing
# interface cannot be told apart from another tool's. Say so and print it with
# its handle rather than guessing, and never flush to be rid of it.
LEFTOVER=$(nft -a list ruleset 2>/dev/null |
           grep -E 'redirect to :8080|masquerade' |
           grep -Ev 'docker|virbr|podman|cni|br-[0-9a-f]|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[01]\.|192\.168\.122\.')

restore_file /etc/nftables.conf q18
restore_file /etc/sysconfig/nftables.conf q18

[[ -n "$OLD_FWD" ]] && sysctl -q -w "net.ipv4.ip_forward=$OLD_FWD" >/dev/null 2>&1

rm -rf "${LFCS_STATE_DIR:?}/q18"

echo "Cleanup complete."
echo "  Both peer namespaces and both servers are gone."
echo "  Removed $NATREMOVED nat table(s) or rule(s) belonging to this question; nothing else was touched,"
echo "  so any masquerade docker, libvirt, podman or ufw installed is still loaded."
echo "  net.ipv4.ip_forward is back to ${OLD_FWD:-its original value} at runtime."
echo "  A drop-in you wrote under /etc/sysctl.d is left in place; remove it by hand if you want it gone."
if [[ -n "$LEFTOVER" ]]; then
  echo "  Note: a redirect or masquerade rule is still loaded that names nothing this question created,"
  echo "        so it was left alone. Delete it by hand if it is yours:"
  printf '%s\n' "$LEFTOVER" | sed 's/^[[:space:]]*/        /'
  echo "        nft -a list ruleset, then nft delete rule <family> <table> <chain> handle <n>"
fi
