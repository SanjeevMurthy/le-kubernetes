#!/bin/bash
# Q14 hostname and resolver: rename the host, drop the static entry for node9 and
# strip 1.1.1.1, 9.9.9.9 and the lab.local search domain out of every place that
# would make the task pass before the candidate has done anything.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q14"
mkdir -p "$STATE/removed"
PAT='1\.1\.1\.1|9\.9\.9\.9'

WANT=node1.lab.local
[[ "$(distro)" == rocky ]] && WANT=node2.lab.local

list_netfiles() {
  local f
  if [[ "$(distro)" == ubuntu ]]; then
    for f in /etc/netplan/*.yaml /etc/netplan/*.yml; do [[ -f "$f" ]] && echo "$f"; done
  else
    for f in /etc/NetworkManager/system-connections/*.nmconnection /etc/sysconfig/network-scripts/ifcfg-*; do
      [[ -f "$f" ]] && echo "$f"
    done
  fi
  for f in /etc/systemd/resolved.conf /etc/systemd/resolved.conf.d/*.conf; do
    [[ -f "$f" ]] && echo "$f"
  done
  return 0
}

[[ -f "$STATE/hostname" ]] || hostnamectl --static > "$STATE/hostname" 2>/dev/null

backup_file /etc/hosts q14
backup_file /etc/hostname q14

while read -r f; do
  [[ -n "$f" ]] || continue
  b="$LFCS_STATE_DIR/backup/q14/$(echo "$f" | tr / _)"
  [[ -f "$b" ]] && restore_file "$f" q14
done < <(list_netfiles)

[[ -f "$STATE/orig" ]] || list_netfiles > "$STATE/orig"

while read -r f; do
  [[ -n "$f" ]] || continue
  grep -qE "$PAT" "$f" 2>/dev/null || continue
  if grep -Fxq "$f" "$STATE/orig"; then
    echo "  Warning: $f still names 1.1.1.1 or 9.9.9.9 and is one of this host's own files. Check it by hand."
  else
    mv -f "$f" "$STATE/removed/$(basename "$f")"
    echo "  Moved $f into $STATE/removed (it was written by an earlier attempt)."
  fi
done < <(list_netfiles)

while read -r f; do [[ -n "$f" ]] && backup_file "$f" q14; done < <(list_netfiles)

# Rename the host and keep the loopback alias in step, so sudo stays quiet.
sed -i -E '/[[:space:]]node9([[:space:]]|$)/d; /node9\.lab\.local/d' /etc/hosts
sed -i -E '/^127\.0\.1\.1[[:space:]]/d' /etc/hosts
printf '127.0.1.1\tlfcs-unset\n' >> /etc/hosts
hostnamectl set-hostname lfcs-unset >/dev/null 2>&1

if [[ "$(distro)" == ubuntu ]]; then
  netplan apply >/dev/null 2>&1
else
  nmcli con reload >/dev/null 2>&1
fi
systemctl restart systemd-resolved >/dev/null 2>&1

echo "Setup complete."
echo "  Static hostname now:   $(hostnamectl --static 2>/dev/null)"
echo "  Hostname wanted:       $WANT"
echo "  Host entry wanted:     192.168.56.90 for node9.lab.local and node9"
echo "  DNS servers wanted:    1.1.1.1 and 9.9.9.9, search domain lab.local"
echo "  getent hosts node9:    $(getent hosts node9 2>/dev/null || echo 'no answer')"
echo "  Live DNS now:          $( { resolvectl dns 2>/dev/null | tr -s ' ' ; grep -h '^nameserver' /etc/resolv.conf 2>/dev/null; } | tr '\n' ' ' | cut -c1-160)"
if [[ "$(distro)" == ubuntu ]]; then
  echo "  Persistence file:      the netplan YAML under /etc/netplan, or /etc/systemd/resolved.conf"
else
  echo "  Persistence file:      /etc/NetworkManager/system-connections/*.nmconnection, or /etc/systemd/resolved.conf"
fi
echo "  Editing /etc/resolv.conf by hand does not persist and does not count."
