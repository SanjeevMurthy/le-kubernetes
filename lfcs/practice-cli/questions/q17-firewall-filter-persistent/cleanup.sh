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
  # ufw disable unloads every rule ufw installed, which is the whole of a ufw
  # answer. Note what is not here: systemctl stop nftables. The Debian and
  # Rocky unit files both flush the entire ruleset in ExecStop, which erases the
  # rules docker, libvirt or podman reinstalled while this question was open.
  # An nft answer is taken apart table by table below instead.
  command -v ufw >/dev/null 2>&1 && ufw --force disable >/dev/null 2>&1
fi

# ─── remove this question's own tables, never the whole ruleset ────
# The answer here is an input chain with a drop policy plus accepts for 22, 80,
# 443 and the three exam ports. Setup left the live ruleset empty, so a chain
# shaped like that is this question's: docker, libvirt and podman add forward
# and nat rules and never an input chain with policy drop. 4505, 4506 and the
# 9999 that must be dropped are this question's ports and nothing else's, so
# they identify the table even when the candidate's answer was incomplete.
# 8080 is deliberately not in that list, because q18 uses it too.
#
# A table that also holds iptables' built-in chains, or docker's or ufw's, is
# shared. There only the matching rules are deleted and the input policy is put
# back to accept, so that an unfinished answer cannot leave the lab VM dropping
# everything it receives.
NFTREMOVED=0

nft_own_tables() {
  nft -a list ruleset 2>/dev/null | awk '
    $1 == "table" { fam = $2; tbl = $3; next }
    /hook input/ && /policy drop/  { print fam, tbl; next }
    /dport/ && /(4505|4506|9999)/  { print fam, tbl }' | sort -u
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
        NFTREMOVED=$((NFTREMOVED + 1))
    done < <(nft -a list table "$FAM" "$TBL" 2>/dev/null |
             awk -v fam="$FAM" -v tbl="$TBL" '
               $1 == "chain" { ch = $2 }
               /# handle [0-9]+$/ && /dport/ && /(4505|4506|9999)/ { print fam, tbl, ch, $NF }')
    while read -r c; do
      [[ -n "$c" ]] || continue
      nft chain "$FAM" "$TBL" "$c" '{ policy accept ; }' >/dev/null 2>&1
    done < <(nft list table "$FAM" "$TBL" 2>/dev/null | awk '
               $1 == "chain" { ch = $2 }
               /hook input/ && /policy drop/ { print ch }')
  else
    nft delete table "$FAM" "$TBL" >/dev/null 2>&1 && NFTREMOVED=$((NFTREMOVED + 1))
  fi
done < <(nft_own_tables)

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
echo "  Removed $NFTREMOVED nftables table(s) or rule(s) belonging to this question."
echo "  Nothing else was touched: rules docker, libvirt, podman or ufw installed are still loaded."
