#!/bin/bash
# Q22 unreachable web app: run the application bound to loopback, drop its port
# in the live ruleset and in the distribution's saved nftables file, and build a
# peer that can prove whether the host is reachable.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q22"
mkdir -p "$STATE"
NS=dbg-peer
HOSTIP=10.99.22.1
DIR=$(course_dir 22)

command -v nft >/dev/null 2>&1 || pkg_install nftables
if ! command -v nft >/dev/null 2>&1; then
  echo "nft is not available. Install nftables and run setup again."
  exit 1
fi

PEERIP=$(make_netns_peer "$NS" 22)

mkdir -p /srv/labapp
printf 'app-ok\n' > /srv/labapp/index.html

rm -rf /etc/systemd/system/labapp.service.d
cat > /etc/systemd/system/labapp.service <<'UNITEOF'
[Unit]
Description=LFCS Q22 lab web application
After=network.target

[Service]
ExecStart=/usr/bin/python3 -u -m http.server 8082 --bind 127.0.0.1 --directory /srv/labapp
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNITEOF
systemctl daemon-reload
systemctl enable --now labapp >/dev/null 2>&1
systemctl restart labapp >/dev/null 2>&1

rm -f "$DIR/causes.txt"

if [[ "$(distro)" == ubuntu ]]; then
  PFILE=/etc/nftables.conf
else
  PFILE=/etc/sysconfig/nftables.conf
fi
echo "$PFILE" > "$STATE/pfile"

# The drop exempts loopback on purpose. The scenario is two faults that look
# alike from the peer, and the candidate tells them apart by curling
# 127.0.0.1:8082 and getting app-ok while the peer times out. A drop that also
# ate loopback traffic would hide the bind address entirely, and the question
# and the solution both promise that loopback answers.
read -r -d '' NFTBLOCK <<'BLOCKEOF'
# LFCS Q22 lab rule. This is the drop that has to be found and removed.
table inet labq22 {
	chain input {
		type filter hook input priority 0; policy accept;
		iifname "lo" accept
		tcp dport 8082 drop
	}
}
BLOCKEOF

backup_file "$PFILE" q22
if [[ ! -f "$PFILE" ]]; then
  mkdir -p "$(dirname "$PFILE")"
  printf '#!/usr/sbin/nft -f\n' > "$PFILE"
  echo yes > "$STATE/created"
fi
grep -q 'labq22' "$PFILE" 2>/dev/null || printf '\n%s\n' "$NFTBLOCK" >> "$PFILE"

nft delete table inet labq22 >/dev/null 2>&1
printf '%s\n' "$NFTBLOCK" | nft -f - >/dev/null 2>&1

LADDR=$(ss -H -ltn 2>/dev/null | awk '{print $4}' | grep ':8082$' | tr '\n' ' ')

echo "Setup complete."
echo "  Application:     labapp.service ($(systemctl is-active labapp 2>/dev/null)), serving /srv/labapp"
echo "  Listening on:    ${LADDR:-nothing yet}"
echo "  This host:       $HOSTIP, peer $PEERIP in namespace $NS"
echo "  From the host:   $(curl -s --max-time 3 http://127.0.0.1:8082/ 2>/dev/null || echo 'no answer')"
echo "  From the peer:   $(in_peer "$NS" curl -s --max-time 3 "http://$HOSTIP:8082/" 2>/dev/null || echo 'no answer')"
echo "  A working application answers app-ok."
echo "  There are two causes. One is in the unit, one is a packet filter rule that is"
echo "  loaded now and also saved in $PFILE, so it would come back after a reboot."
echo "  Write what you found to $DIR/causes.txt, one cause per line."
