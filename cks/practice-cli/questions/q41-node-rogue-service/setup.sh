#!/bin/bash
# Q41 rogue service: install, enable and start a hand-rolled systemd unit on the
# worker that serves an open port, so the candidate has a real socket to trace.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kubectl

FILE=/etc/systemd/system/lab-fileshare.service
PORT=8888

W=$(worker_node)
[[ -n "$W" ]] || { echo "no worker node found"; exit 1; }

on_worker command -v python3 >/dev/null 2>&1 || {
  echo "python3 is not installed on $W, so the lab service cannot be started there."
  echo "Install it with: ssh $W apt-get install -y python3"
  exit 1
}
on_worker command -v ss >/dev/null 2>&1 || {
  echo "warning: ss is not installed on $W. Install iproute2 there or the verifier cannot read the listening sockets."
}

# Backs up the local copy for the common case of running this on the worker.
# The remote script below refuses to touch a unit file it did not write, which
# is what keeps this safe when the worker is a different machine.
backup_file "$FILE" q41

on_worker bash -s <<'REMOTE'
set -e
FILE=/etc/systemd/system/lab-fileshare.service
MARK='# CKS practice CLI q41 lab unit'
if [ -f "$FILE" ] && ! grep -qF "$MARK" "$FILE"; then
  echo "$FILE already exists on $(hostname) and was not written by this question. Refusing to overwrite it."
  exit 1
fi

PY=$(command -v python3)
mkdir -p /srv/lab-fileshare
echo "quarterly numbers, do not share" > /srv/lab-fileshare/README.txt

cat > "$FILE" <<UNIT
$MARK
[Unit]
Description=Lab file share
After=network.target

[Service]
Type=simple
WorkingDirectory=/srv/lab-fileshare
ExecStart=$PY -m http.server 8888 --bind 0.0.0.0
Restart=always
User=root

[Install]
WantedBy=multi-user.target
UNIT
chmod 0644 "$FILE"

systemctl daemon-reload
systemctl enable --now lab-fileshare.service

i=0
while [ "$i" -lt 10 ]; do
  if ss -H -ltn 2>/dev/null | awk '{print $4}' | grep -Eq '(^|[:.])8888$'; then break; fi
  i=$((i + 1))
  sleep 1
done
echo "seeded on $(hostname): $(systemctl is-active lab-fileshare.service), $(systemctl is-enabled lab-fileshare.service)"
REMOTE

DIR=$(course_dir 41)
rm -f "$DIR/service.txt"

echo "Setup complete."
echo "  Worker node:   $W"
echo "  Open port:     TCP $PORT on $W, served by a unit in /etc/systemd/system/"
echo "  Unit name:     not given here on purpose. Trace it from the socket."
echo "  Deliverable:   $DIR/service.txt   (one line: the unit name)"
echo "  Start with:    ssh $W 'ss -ltnp | grep 8888'"
echo "  Nothing else on the node was changed, so anything else you find there is real."
