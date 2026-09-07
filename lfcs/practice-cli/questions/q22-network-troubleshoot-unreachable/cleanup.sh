#!/bin/bash
# Q22 unreachable web app: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q22"
PFILE=$(cat "$STATE/pfile" 2>/dev/null)
[[ -n "$PFILE" ]] || { PFILE=/etc/nftables.conf; [[ "$(distro)" == rocky ]] && PFILE=/etc/sysconfig/nftables.conf; }

nft delete table inet labq22 >/dev/null 2>&1

systemctl disable --now labapp >/dev/null 2>&1
rm -rf /etc/systemd/system/labapp.service.d
rm -f /etc/systemd/system/labapp.service
systemctl daemon-reload
rm -rf /srv/labapp

del_netns_peer dbg-peer

if [[ -f "$STATE/created" ]]; then
  rm -f "$PFILE"
else
  restore_file "$PFILE" q22
fi

rm -rf "${COURSE_DIR:?}/22"
rm -rf "${LFCS_STATE_DIR:?}/q22"

echo "Cleanup complete."
echo "  labapp.service, /srv/labapp, the peer namespace and the labq22 nft table are gone,"
echo "  and $PFILE was put back the way setup found it."
