#!/bin/bash
# Q40 service limits: install a packaged unit whose application needs 100 open
# file descriptors and whose vendor limit allows 16, so it starts and fails.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

systemctl disable --now fdhog.service >/dev/null 2>&1
rm -rf /etc/systemd/system/fdhog.service.d
rm -f /etc/systemd/system/fdhog.service
rm -f /etc/systemd/system/multi-user.target.wants/fdhog.service
systemctl daemon-reload

cat > /usr/local/bin/fdhog.sh <<'SHEOF'
#!/bin/bash
# Lab application: it needs 100 open file descriptors, then idles.
opened=0
for i in $(seq 1 100); do
  if ! exec {fd}< /dev/null 2>/dev/null; then
    echo "cannot open descriptor number $i" >&2
    exit 1
  fi
  opened=$(( opened + 1 ))
done
echo "opened $opened descriptors"
while true; do
  sleep 3600
done
SHEOF
chmod 755 /usr/local/bin/fdhog.sh

mkdir -p /usr/lib/systemd/system
cat > /usr/lib/systemd/system/fdhog.service <<'UNIT'
[Unit]
Description=File descriptor hungry application (lab)

[Service]
Type=simple
ExecStart=/usr/local/bin/fdhog.sh
LimitNOFILE=16
Restart=no

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable fdhog.service >/dev/null 2>&1
systemctl start fdhog.service >/dev/null 2>&1
sleep 2

echo "Setup complete."
echo "  Vendor unit:  /usr/lib/systemd/system/fdhog.service, LimitNOFILE=16"
echo "  Application:  /usr/local/bin/fdhog.sh, needs 100 open file descriptors"
echo "  State now:    fdhog.service is $(systemctl is-active fdhog.service 2>/dev/null)"
echo "  Targets:      LimitNOFILE 65536, TasksMax 4096, service active, vendor unit untouched"
