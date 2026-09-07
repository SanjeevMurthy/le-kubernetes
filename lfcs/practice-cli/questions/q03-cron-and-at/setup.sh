#!/bin/bash
# Q03 cron and at: create the user and the two scripts, clear any job that would
# make the task pass before it is started, and record the at queue as it was.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q03"
mkdir -p "$STATE"

if [[ "$(distro)" == ubuntu ]]; then
  CRONDIR=/var/spool/cron/crontabs
else
  CRONDIR=/var/spool/cron
fi

command -v at >/dev/null 2>&1 || pkg_install at
systemctl enable --now atd >/dev/null 2>&1

# Record whether this question created the account before creating it, so
# cleanup deletes only what it made. A host with a real backupop account keeps
# it and its home directory. The record is written once, so a second setup run
# does not overwrite the first answer.
if [[ ! -f "$STATE/created-user" ]]; then
  if id backupop >/dev/null 2>&1; then
    echo no > "$STATE/created-user"
  else
    echo yes > "$STATE/created-user"
  fi
fi
id backupop >/dev/null 2>&1 || useradd -m -s /bin/bash backupop

cat > /usr/local/bin/backup.sh <<'SHEOF'
#!/bin/bash
# Lab placeholder. A real backup would go here.
echo "$(date -Is) backup ran as $(id -un)" >> /var/log/lfcs-backup.log
SHEOF

cat > /usr/local/bin/cleanup.sh <<'SHEOF'
#!/bin/bash
# Lab placeholder. A real cleanup would go here.
echo "$(date -Is) cleanup ran as $(id -un)" >> /var/log/lfcs-cleanup.log
SHEOF

chmod 755 /usr/local/bin/backup.sh /usr/local/bin/cleanup.sh

backup_file "$CRONDIR/root" q03
crontab -u backupop -r >/dev/null 2>&1
if crontab -l >/dev/null 2>&1; then
  crontab -l 2>/dev/null | grep -v '/usr/local/bin/cleanup.sh' | crontab -
fi

[[ -f "$STATE/atq.before" ]] || atq 2>/dev/null | awk '{print $1}' | sort > "$STATE/atq.before"

echo "Setup complete."
echo "  User:            backupop (no crontab yet)"
echo "  Scripts:         /usr/local/bin/backup.sh and /usr/local/bin/cleanup.sh"
echo "  Crontab spool:   $CRONDIR"
echo "  atd is $(systemctl is-active atd 2>/dev/null) and $(systemctl is-enabled atd 2>/dev/null)"
echo "  Field order is minute hour day-of-month month day-of-week command."
