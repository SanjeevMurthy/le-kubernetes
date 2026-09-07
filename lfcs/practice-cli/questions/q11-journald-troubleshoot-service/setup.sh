#!/bin/bash
# Q11 journal and a broken unit: plant a service whose script is not executable,
# and put the journal in memory only so the evidence would be lost at a reboot.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

DIR=$(course_dir 11)
JBK="$LFCS_STATE_DIR/backup/q11/var_log_journal"
mkdir -p "$LFCS_STATE_DIR/backup/q11"

rm -f "$DIR/error.txt"

# 1. Volatile journal, with any existing persistent journal put safely aside.
backup_file /etc/systemd/journald.conf q11
if [[ -d /var/log/journal && ! -d "$JBK" ]]; then
  mv /var/log/journal "$JBK"
fi
rm -rf /var/log/journal
if grep -Eq '^#?[[:space:]]*Storage=' /etc/systemd/journald.conf 2>/dev/null; then
  sed -i -E 's/^#?[[:space:]]*Storage=.*/Storage=volatile/' /etc/systemd/journald.conf
else
  printf 'Storage=volatile\n' >> /etc/systemd/journald.conf
fi
systemctl restart systemd-journald >/dev/null 2>&1

# 2. The application, deliberately without its executable bit.
mkdir -p /opt/billing
cat > /opt/billing/billing.sh <<'SHEOF'
#!/bin/bash
# Lab application. Prints a line, then stays in the foreground.
echo "billing started at $(date -Is)"
while true; do
  echo "billing heartbeat $(date -Is)"
  sleep 30
done
SHEOF
chmod 644 /opt/billing/billing.sh
chown root:root /opt/billing/billing.sh

cat > /etc/systemd/system/billing.service <<'UNITEOF'
[Unit]
Description=Billing collector
After=network.target

[Service]
Type=simple
ExecStart=/opt/billing/billing.sh
Restart=no

[Install]
WantedBy=multi-user.target
UNITEOF

systemctl daemon-reload
systemctl enable billing.service >/dev/null 2>&1
systemctl start billing.service >/dev/null 2>&1

echo "Setup complete."
echo "  Unit:            billing.service, $(systemctl is-enabled billing.service 2>/dev/null), currently $(systemctl is-active billing.service 2>/dev/null)"
echo "  Journal storage: $(grep -E '^Storage=' /etc/systemd/journald.conf) and /var/log/journal does not exist"
echo "  Deliverable:     $DIR/error.txt"
echo "  Start with: journalctl -u billing.service -b --no-pager"
