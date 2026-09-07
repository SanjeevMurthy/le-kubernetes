#!/bin/bash
# Q01 sysctl: reset both tunables to a wrong value and remove any drop-in that
# would make the task pass before the candidate has done anything.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

backup_file /etc/sysctl.conf q01
backup_file /etc/sysctl.d/90-lab.conf q01

rm -f /etc/sysctl.d/90-lab.conf

if [[ -f /etc/sysctl.conf ]]; then
  sed -i -E '/^[[:space:]]*(net\.ipv4\.ip_forward|vm\.swappiness)[[:space:]]*=/d' /etc/sysctl.conf
fi

sysctl -q -w net.ipv4.ip_forward=0 >/dev/null 2>&1
sysctl -q -w vm.swappiness=60 >/dev/null 2>&1

leftover=$(grep -lE '(net\.ipv4\.ip_forward|vm\.swappiness)' /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf 2>/dev/null | tr '\n' ' ')

echo "Setup complete."
echo "  net.ipv4.ip_forward is now $(sysctl -n net.ipv4.ip_forward)"
echo "  vm.swappiness is now $(sysctl -n vm.swappiness)"
echo "  /etc/sysctl.conf and /etc/sysctl.d/90-lab.conf no longer set either key."
[[ -n "$leftover" ]] && echo "  Note: these vendor files also mention the keys: $leftover"
echo "  Both values must be right now and after a reboot."
