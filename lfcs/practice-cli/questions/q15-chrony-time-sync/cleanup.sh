#!/bin/bash
# Q15 chrony: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q15"
CONF=$(cat "$STATE/conf" 2>/dev/null)
UNIT=$(cat "$STATE/unit" 2>/dev/null)
TZ_OLD=$(cat "$STATE/tz" 2>/dev/null)
WAS_ENABLED=$(cat "$STATE/enabled" 2>/dev/null)
WAS_ACTIVE=$(cat "$STATE/active" 2>/dev/null)
[[ -n "$UNIT" ]] || UNIT=chrony

[[ -n "$CONF" ]] && restore_file "$CONF" q15
for f in /etc/chrony/chrony.conf /etc/chrony.conf /etc/chrony/conf.d/*.conf /etc/chrony.d/*.conf; do
  [[ -e "$f" ]] && restore_file "$f" q15
done

[[ -n "$TZ_OLD" ]] && timedatectl set-timezone "$TZ_OLD" >/dev/null 2>&1

if [[ "$WAS_ENABLED" == enabled ]]; then
  systemctl enable "$UNIT" >/dev/null 2>&1
else
  systemctl disable "$UNIT" >/dev/null 2>&1
fi
if [[ "$WAS_ACTIVE" == active ]]; then
  systemctl restart "$UNIT" >/dev/null 2>&1
else
  systemctl stop "$UNIT" >/dev/null 2>&1
fi

rm -rf "${LFCS_STATE_DIR:?}/q15"

echo "Cleanup complete."
echo "  Chrony configuration restored, timezone back to ${TZ_OLD:-its original value}."
echo "  $UNIT is now $(systemctl is-active "$UNIT" 2>/dev/null), $(systemctl is-enabled "$UNIT" 2>/dev/null)."
