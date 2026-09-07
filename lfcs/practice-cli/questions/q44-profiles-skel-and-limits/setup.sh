#!/bin/bash
# Q44 profiles and limits: provide the ana account, clear every file the task is
# meant to create, and make sure pam_limits is in the su stack so that
# "su - ana -c 'ulimit ...'" really reports what limits.d sets.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

backup_file /etc/pam.d/su q44

id ana >/dev/null 2>&1 || useradd -m -s /bin/bash -c 'Ana Diaz' ana
usermod -s /bin/bash ana
echo 'ana:Lfcs2026Pass' | chpasswd

userdel -r newbie >/dev/null 2>&1
rm -rf /home/newbie
rm -rf /etc/skel/bin
rm -f /etc/profile.d/lab.sh
rm -rf /home/ana/bin

for f in /etc/profile.d/*.sh; do
  [[ -f "$f" ]] || continue
  if grep -Eq 'HISTSIZE[[:space:]]*=[[:space:]]*5000' "$f"; then rm -f "$f"; fi
done
for f in /etc/security/limits.d/*.conf; do
  [[ -f "$f" ]] || continue
  if grep -Eq '^[[:space:]]*ana[[:space:]]' "$f"; then rm -f "$f"; fi
done

if ! grep -Eq '^[[:space:]]*session[[:space:]]+required[[:space:]]+pam_limits\.so' /etc/pam.d/su; then
  if grep -Eq '^[[:space:]]*#[[:space:]]*session[[:space:]]+required[[:space:]]+pam_limits\.so' /etc/pam.d/su; then
    sed -i -E 's/^[[:space:]]*#[[:space:]]*(session[[:space:]]+required[[:space:]]+pam_limits\.so)/\1/' /etc/pam.d/su
  else
    echo 'session    required   pam_limits.so' >> /etc/pam.d/su
  fi
fi

echo "Setup complete."
echo "  Account:  ana, shell /bin/bash, home /home/ana"
echo "  Removed:  /etc/profile.d/lab.sh, /etc/skel/bin, the newbie account, any limits file naming ana"
echo "  pam_limits is enabled in /etc/pam.d/su, so 'su - ana' reports the limits you set."
echo "  Current values for ana: EDITOR='$(su - ana -c 'echo "$EDITOR"' 2>/dev/null)' HISTSIZE='$(su - ana -c 'echo "$HISTSIZE"' 2>/dev/null)'"
