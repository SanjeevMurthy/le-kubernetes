#!/bin/bash
# Q42 sudo and ageing: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

for f in /etc/sudoers.d/*; do
  [[ -f "$f" ]] || continue
  case "${f##*/}" in README|README.*) continue ;; esac
  if grep -Eq '^[[:space:]]*(ana|%ops)[[:space:]]' "$f"; then rm -f "$f"; fi
done

restore_file /etc/login.defs q42
restore_file /etc/security/pwquality.conf q42
restore_file /etc/sudoers q42

userdel -r ana >/dev/null 2>&1
userdel -r opsman >/dev/null 2>&1
groupdel ops >/dev/null 2>&1

echo "Cleanup complete. The ana and opsman accounts, the ops group and every"
echo "/etc/sudoers.d file carrying an ana or %ops rule are gone, and login.defs,"
echo "pwquality.conf and sudoers are restored from the backups setup took."
