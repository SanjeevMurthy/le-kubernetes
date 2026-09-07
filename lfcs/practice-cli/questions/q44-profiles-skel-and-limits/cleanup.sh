#!/bin/bash
# Q44 profiles and limits: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

rm -f /etc/profile.d/lab.sh
for f in /etc/profile.d/*.sh; do
  [[ -f "$f" ]] || continue
  if grep -Eq 'HISTSIZE[[:space:]]*=[[:space:]]*5000' "$f"; then rm -f "$f"; fi
done
for f in /etc/security/limits.d/*.conf; do
  [[ -f "$f" ]] || continue
  if grep -Eq '^[[:space:]]*ana[[:space:]]' "$f"; then rm -f "$f"; fi
done

rm -rf /etc/skel/bin

# Only what exists because of this question. ana is shared with Q41, Q42 and
# Q43: if the host already had her when setup ran, she belongs to another
# question and removing her would take her home directory with it.
STATE="$LFCS_STATE_DIR/q44"
if [[ "$(cat "$STATE/created-user-newbie" 2>/dev/null)" == yes ]]; then
  userdel -r newbie >/dev/null 2>&1
  rm -rf /home/newbie
fi
if [[ "$(cat "$STATE/created-user-ana" 2>/dev/null)" == yes ]]; then
  userdel -r ana >/dev/null 2>&1
  rm -rf /home/ana
fi

restore_file /etc/pam.d/su q44
rm -rf "${LFCS_STATE_DIR:?}/q44"

echo "Cleanup complete. The profile.d and limits.d files for this question and"
echo "/etc/skel/bin are gone, /etc/pam.d/su is restored, and the ana and newbie"
echo "accounts were removed only where the host did not already have them."
