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
userdel -r newbie >/dev/null 2>&1
rm -rf /home/newbie
userdel -r ana >/dev/null 2>&1
rm -rf /home/ana

restore_file /etc/pam.d/su q44

echo "Cleanup complete. The profile.d and limits.d files for this question, /etc/skel/bin,"
echo "the ana and newbie accounts are gone, and /etc/pam.d/su is restored."
