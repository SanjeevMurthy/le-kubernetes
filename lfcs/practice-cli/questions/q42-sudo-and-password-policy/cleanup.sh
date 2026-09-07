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

# Only what setup created. ana is shared with Q41, Q43 and Q44: if the host
# already had her when setup ran, she belongs to another question and removing
# her here would take her home directory and her group memberships with it.
STATE="$LFCS_STATE_DIR/q42"
[[ "$(cat "$STATE/created-user-ana" 2>/dev/null)" == yes ]] && userdel -r ana >/dev/null 2>&1
[[ "$(cat "$STATE/created-user-opsman" 2>/dev/null)" == yes ]] && userdel -r opsman >/dev/null 2>&1
[[ "$(cat "$STATE/created-group-ops" 2>/dev/null)" == yes ]] && groupdel ops >/dev/null 2>&1

rm -rf "${LFCS_STATE_DIR:?}/q42"

echo "Cleanup complete. Every /etc/sudoers.d file carrying an ana or %ops rule is"
echo "gone, login.defs, pwquality.conf and sudoers are restored from the backups"
echo "setup took, and the ana and opsman accounts and the ops group were removed"
echo "only if this question created them."
