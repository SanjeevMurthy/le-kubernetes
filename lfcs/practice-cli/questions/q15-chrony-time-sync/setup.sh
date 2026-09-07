#!/bin/bash
# Q15 chrony: stop the time daemon, take the lab source and the allow rule out of
# the configuration file, and put the timezone back to UTC.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q15"
mkdir -p "$STATE"

if [[ "$(distro)" == ubuntu ]]; then
  CONF=/etc/chrony/chrony.conf
  UNIT=chrony
else
  CONF=/etc/chrony.conf
  UNIT=chronyd
fi
systemctl list-unit-files 2>/dev/null | grep -q "^${UNIT}\.service" || {
  if systemctl list-unit-files 2>/dev/null | grep -q '^chronyd\.service'; then UNIT=chronyd; else UNIT=chrony; fi
}
[[ -f "$CONF" ]] || { [[ -f /etc/chrony.conf ]] && CONF=/etc/chrony.conf; }
[[ -f "$CONF" ]] || { [[ -f /etc/chrony/chrony.conf ]] && CONF=/etc/chrony/chrony.conf; }
echo "$CONF" > "$STATE/conf"
echo "$UNIT" > "$STATE/unit"

if [[ ! -f "$CONF" ]]; then
  echo "No chrony configuration file found. Install chrony and run setup again."
  exit 1
fi

[[ -f "$STATE/tz" ]]      || timedatectl show -p Timezone --value > "$STATE/tz" 2>/dev/null
[[ -f "$STATE/enabled" ]] || systemctl is-enabled "$UNIT" > "$STATE/enabled" 2>/dev/null
[[ -f "$STATE/active" ]]  || systemctl is-active "$UNIT" > "$STATE/active" 2>/dev/null

backup_file "$CONF" q15
for f in /etc/chrony/conf.d/*.conf /etc/chrony.d/*.conf; do
  [[ -f "$f" ]] && backup_file "$f" q15
done

sed -i -E '/^[[:space:]]*server[[:space:]]+time\.google\.com/d; /^[[:space:]]*allow[[:space:]]+192\.168\.56\.0\/24/d' "$CONF"
for f in /etc/chrony/conf.d/*.conf /etc/chrony.d/*.conf; do
  [[ -f "$f" ]] || continue
  sed -i -E '/^[[:space:]]*server[[:space:]]+time\.google\.com/d; /^[[:space:]]*allow[[:space:]]+192\.168\.56\.0\/24/d' "$f"
done

timedatectl set-timezone UTC >/dev/null 2>&1
systemctl disable --now "$UNIT" >/dev/null 2>&1

echo "Setup complete."
echo "  Configuration file:  $CONF"
echo "  Service unit:        $UNIT ($(systemctl is-active "$UNIT" 2>/dev/null), $(systemctl is-enabled "$UNIT" 2>/dev/null))"
echo "  Timezone now:        $(timedatectl show -p Timezone --value 2>/dev/null)"
echo "  Wanted:              server time.google.com iburst"
echo "                       allow 192.168.56.0/24"
echo "                       timezone Asia/Kolkata, service running and enabled"
echo "  Sources in the file: $(grep -cE '^[[:space:]]*(server|pool)' "$CONF" 2>/dev/null) server or pool lines"
if getent ahostsv4 time.google.com >/dev/null 2>&1; then
  echo "  This host can resolve time.google.com, so chronyc sources will name it."
else
  echo "  Note: this host cannot resolve time.google.com right now, so the live source list will not name it."
fi
