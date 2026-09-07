#!/bin/bash
# Q12 static IPv4 on the second NIC: name the lab interface, remember every
# address it already carries, and make sure neither the running kernel nor any
# network configuration file already holds the answer.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q12"
mkdir -p "$STATE/removed"

TARGET_IP=10.50.0.10
[[ "$(distro)" == rocky ]] && TARGET_IP=10.50.0.20
TARGET="$TARGET_IP/24"
PAT='10\.50\.0\.'

second_nic() {
  local pri nic
  pri=$(ip -o route show default 2>/dev/null | awk '{print $5}' | head -1)
  for nic in $(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | sed 's/@.*//'); do
    case "$nic" in
      lo|docker*|veth*|virbr*|br-*|br0|podman*|cni*|tun*|tap*|wg*|bond*|dummy*|nft*) continue ;;
    esac
    [[ "$nic" == "$pri" ]] && continue
    echo "$nic"; return 0
  done
  return 1
}

list_netfiles() {
  local f
  if [[ "$(distro)" == ubuntu ]]; then
    for f in /etc/netplan/*.yaml /etc/netplan/*.yml; do [[ -f "$f" ]] && echo "$f"; done
  else
    for f in /etc/NetworkManager/system-connections/*.nmconnection /etc/sysconfig/network-scripts/ifcfg-*; do
      [[ -f "$f" ]] && echo "$f"
    done
  fi
  return 0
}

NIC=$(second_nic)
if [[ -z "$NIC" ]]; then
  echo "No second network interface found. This question needs the nic2 tag."
  exit 1
fi
echo "$NIC" > "$STATE/nic"

CON=""
if [[ "$(distro)" == rocky ]]; then
  CON=$(nmcli -t -f NAME,DEVICE con show 2>/dev/null | awk -F: -v d="$NIC" '$2==d {print $1; exit}')
  echo "$CON" > "$STATE/con"
fi

# Remember every address the interface carries now. One of them may be the
# address this SSH session is running over, so verify insists they all survive.
ip -o -4 addr show dev "$NIC" 2>/dev/null | awk '{print $4}' | grep -v "^$PAT" > "$STATE/keep"

# Restore any network file a previous run of this question modified, so the
# question always starts from the host's own configuration.
while read -r f; do
  [[ -n "$f" ]] || continue
  b="$LFCS_STATE_DIR/backup/q12/$(echo "$f" | tr / _)"
  [[ -f "$b" ]] && restore_file "$f" q12
done < <(list_netfiles)

[[ -f "$STATE/orig" ]] || list_netfiles > "$STATE/orig"

# Anything still carrying the lab address after that restore was written by the
# candidate, so move it aside rather than editing it.
while read -r f; do
  [[ -n "$f" ]] || continue
  grep -qE "$PAT" "$f" 2>/dev/null || continue
  if grep -Fxq "$f" "$STATE/orig"; then
    echo "  Warning: $f still mentions $TARGET_IP and is one of this host's own files. Check it by hand."
  else
    mv -f "$f" "$STATE/removed/$(basename "$f")"
    echo "  Moved $f into $STATE/removed (it was written by an earlier attempt)."
  fi
done < <(list_netfiles)

while read -r f; do [[ -n "$f" ]] && backup_file "$f" q12; done < <(list_netfiles)

if [[ "$(distro)" == ubuntu ]]; then
  netplan apply >/dev/null 2>&1
else
  nmcli con reload >/dev/null 2>&1
  [[ -n "$CON" ]] && nmcli con up "$CON" >/dev/null 2>&1
fi

ip addr del "$TARGET" dev "$NIC" >/dev/null 2>&1

echo "Setup complete."
echo "  Second interface:     $NIC"
[[ -n "$CON" ]] && echo "  NetworkManager con:   $CON"
echo "  Address to add:       $TARGET"
echo "  Addresses it must keep: $(tr '\n' ' ' < "$STATE/keep")"
echo "  Live now:             $(ip -o -4 addr show dev "$NIC" | awk '{print $4}' | tr '\n' ' ')"
if [[ "$(distro)" == ubuntu ]]; then
  echo "  Persistence file:     the netplan YAML under /etc/netplan that already configures $NIC"
  echo "  Use netplan try, not netplan apply, if your session runs over $NIC."
else
  echo "  Persistence file:     /etc/NetworkManager/system-connections/*.nmconnection"
  echo "  Use nmcli con mod \"$CON\" +ipv4.addresses $TARGET, with the plus sign."
fi
