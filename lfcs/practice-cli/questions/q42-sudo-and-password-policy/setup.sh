#!/bin/bash
# Q42 sudo and ageing: create the two accounts and the ops group, take a copy of
# every file the task touches, and clear any sudo drop-in from an earlier run.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

backup_file /etc/sudoers q42
backup_file /etc/login.defs q42
backup_file /etc/security/pwquality.conf q42

getent group ops >/dev/null 2>&1 || groupadd ops
id ana    >/dev/null 2>&1 || useradd -m -s /bin/bash -c 'Ana Diaz' ana
id opsman >/dev/null 2>&1 || useradd -m -s /bin/bash -c 'Ops Manager' opsman
usermod -aG ops opsman
echo 'ana:Lfcs2026Pass'    | chpasswd
echo 'opsman:Lfcs2026Ops'  | chpasswd

for f in /etc/sudoers.d/*; do
  [[ -f "$f" ]] || continue
  case "${f##*/}" in README|README.*) continue ;; esac
  if grep -Eq '^[[:space:]]*(ana|%ops)[[:space:]]' "$f"; then rm -f "$f"; fi
done

chage -M 99999 -m 0 -W 7 ana

if [[ "$(distro)" == ubuntu && ! -f /etc/security/pwquality.conf ]]; then
  pkg_install libpam-pwquality
fi

echo "Setup complete."
echo "  Accounts: ana, opsman (member of group ops)"
echo "  /etc/sudoers.d holds no rule for ana or %ops"
echo "  /etc/sudoers, /etc/login.defs and /etc/security/pwquality.conf are backed up under $LFCS_STATE_DIR/backup/q42"
echo "  Current PASS_MAX_DAYS: $(awk '/^[[:space:]]*PASS_MAX_DAYS/ {print $2}' /etc/login.defs 2>/dev/null | head -1)"
if [[ -f /etc/security/pwquality.conf ]]; then
  echo "  /etc/security/pwquality.conf exists; set minlen there."
else
  echo "  /etc/security/pwquality.conf does not exist yet; create it with the minlen line."
fi
