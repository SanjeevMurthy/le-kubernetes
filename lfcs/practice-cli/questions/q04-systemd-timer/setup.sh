#!/bin/bash
# Q04 systemd timer: provide the script, and remove any unit left from an
# earlier run so the question starts from nothing.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

systemctl disable --now logsync.timer >/dev/null 2>&1
systemctl disable --now logsync.service >/dev/null 2>&1
rm -f /etc/systemd/system/logsync.timer /etc/systemd/system/logsync.service
rm -rf /etc/systemd/system/logsync.service.d /etc/systemd/system/logsync.timer.d
systemctl daemon-reload

cat > /usr/local/bin/logsync.sh <<'SHEOF'
#!/bin/bash
# Lab placeholder. A real log sync would go here.
mkdir -p /var/log/logsync
echo "$(date -Is) logsync ran" >> /var/log/logsync/logsync.log
SHEOF
chmod 755 /usr/local/bin/logsync.sh

echo "Setup complete."
echo "  Script:   /usr/local/bin/logsync.sh (runs once and exits, writes /var/log/logsync/logsync.log)"
echo "  Units:    none exist yet; create them under /etc/systemd/system/"
echo "  Required: logsync.service and logsync.timer, firing at *:00, *:15, *:30 and *:45"
echo "  systemd-analyze calendar '<expression>' tells you whether an OnCalendar value parses."
