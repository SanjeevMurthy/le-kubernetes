#!/bin/bash
# Q38 port conflict: a packaged unit holds TCP 8090 and the application unit that
# needs it fails to start. legacy.service goes into the vendor directory so it can
# be masked, the way a packaged unit is masked on a real host.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

DIR=$(course_dir 38)
rm -f "$DIR/answer.txt"

systemctl unmask legacy.service >/dev/null 2>&1
systemctl disable --now legacy.service >/dev/null 2>&1
systemctl disable --now webapp.service >/dev/null 2>&1
rm -f /etc/systemd/system/legacy.service /usr/lib/systemd/system/legacy.service
rm -f /etc/systemd/system/webapp.service
rm -f /etc/systemd/system/multi-user.target.wants/legacy.service
rm -f /etc/systemd/system/multi-user.target.wants/webapp.service
systemctl daemon-reload

mkdir -p /srv/legacy /srv/webapp
echo "legacy-report" > /srv/legacy/index.html
echo "webapp-ok"     > /srv/webapp/index.html

mkdir -p /usr/lib/systemd/system
cat > /usr/lib/systemd/system/legacy.service <<'UNIT'
[Unit]
Description=Legacy reporting endpoint (lab)

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server 8090 --directory /srv/legacy
Restart=no

[Install]
WantedBy=multi-user.target
UNIT

cat > /etc/systemd/system/webapp.service <<'UNIT'
[Unit]
Description=Web application (lab)
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server 8090 --directory /srv/webapp
Restart=no

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now legacy.service >/dev/null 2>&1
sleep 1
systemctl start webapp.service >/dev/null 2>&1
sleep 1

echo "Setup complete."
echo "  webapp.service is $(systemctl is-active webapp.service 2>/dev/null) and must end up active and enabled."
echo "  Something else already listens on TCP 8090; find it yourself, it is not named here."
echo "  Deliverable: $DIR/answer.txt holding only the unit name that held the port."
echo "  Port 8090 currently answers: $(curl -s --max-time 3 http://127.0.0.1:8090/ 2>/dev/null | tr -d '\n')"
