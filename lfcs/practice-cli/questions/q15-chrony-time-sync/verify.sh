#!/bin/bash
# Q15 chrony: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

STATE="$LFCS_STATE_DIR/q15"
CONF=$(cat "$STATE/conf" 2>/dev/null)
UNIT=$(cat "$STATE/unit" 2>/dev/null)
[[ -n "$CONF" ]] || { CONF=/etc/chrony/chrony.conf; [[ -f /etc/chrony.conf ]] && CONF=/etc/chrony.conf; }
[[ -n "$UNIT" ]] || { UNIT=chrony; systemctl list-unit-files 2>/dev/null | grep -q '^chronyd\.service' && UNIT=chronyd; }

echo "Checking the daemon..."
check_eq "$UNIT is running" "active" "$(systemctl is-active "$UNIT" 2>/dev/null)"
check_eq "$UNIT starts at boot" "enabled" "$(systemctl is-enabled "$UNIT" 2>/dev/null)"

echo "Control test: the daemon answers chronyc, so it read its configuration..."
check "chronyc tracking gets an answer from the running daemon" chronyc tracking

echo "Checking the live source list..."
SRC=$( { chronyc sources 2>/dev/null; chronyc -n sources 2>/dev/null; } )
if getent ahostsv4 time.google.com >/dev/null 2>&1; then
  found=no
  printf '%s\n' "$SRC" | grep -qi 'google' && found=yes
  for ip in $(getent ahostsv4 time.google.com 2>/dev/null | awk '{print $1}' | sort -u); do
    printf '%s\n' "$SRC" | grep -qF "$ip" && found=yes
  done
  check_eq "chronyc sources lists the configured time.google.com source" "yes" "$found"
else
  echo "  NOTE: time.google.com does not resolve on this host, so the live source list cannot name it."
  echo "        The configuration file is still graded below."
  check "chronyd has at least one source" test -n "$SRC"
fi

echo "Checking the timezone..."
check_eq "the live timezone is Asia/Kolkata" "Asia/Kolkata" \
  "$(timedatectl show -p Timezone --value 2>/dev/null)"
check_contains "/etc/localtime points at the Asia/Kolkata zone file, which is the on-disk half" \
  "Asia/Kolkata" "$(readlink -f /etc/localtime 2>/dev/null)"

echo "Checking the configuration survives a reboot..."
check_persisted "server time.google.com iburst is in the chrony configuration" \
  '^[[:space:]]*server[[:space:]]+time\.google\.com([[:space:]]+.*)?[[:space:]]+iburst' \
  "$CONF" /etc/chrony/chrony.conf /etc/chrony.conf /etc/chrony/conf.d/*.conf /etc/chrony.d/*.conf
check_persisted "allow 192.168.56.0/24 is in the chrony configuration, so the host serves time" \
  '^[[:space:]]*allow[[:space:]]+192\.168\.56\.0/24' \
  "$CONF" /etc/chrony/chrony.conf /etc/chrony.conf /etc/chrony/conf.d/*.conf /etc/chrony.d/*.conf

summary
