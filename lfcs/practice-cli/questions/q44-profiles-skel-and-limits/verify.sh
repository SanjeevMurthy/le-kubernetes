#!/bin/bash
# Q44 profiles and limits: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

echo "Checking the environment as ana sees it at login..."
check_eq "EDITOR is vim in ana's login shell" "vim" \
  "$(su - ana -c 'echo "$EDITOR"' 2>/dev/null | tr -d '[:space:]')"
check_eq "HISTSIZE is 5000 in ana's login shell" "5000" \
  "$(su - ana -c 'echo "$HISTSIZE"' 2>/dev/null | tr -d '[:space:]')"
check_contains "ana's PATH carries /home/ana/bin" "/home/ana/bin" \
  "$(su - ana -c 'echo "$PATH"' 2>/dev/null)"

echo "Checking the skeleton..."
check "/etc/skel/bin exists" test -d /etc/skel/bin
check "the account newbie exists" getent passwd newbie
check "/home/newbie/bin was created from the skeleton" test -d /home/newbie/bin

echo "Checking ana's limits at login..."
check_eq "ana's soft process limit is 100" "100" \
  "$(su - ana -c 'ulimit -Su' 2>/dev/null | tr -d '[:space:]')"
check_eq "ana's hard process limit is 200" "200" \
  "$(su - ana -c 'ulimit -Hu' 2>/dev/null | tr -d '[:space:]')"
check_eq "ana's soft open file limit is 4096" "4096" \
  "$(su - ana -c 'ulimit -Sn' 2>/dev/null | tr -d '[:space:]')"

echo "Checking every change survives a reboot..."
check_persisted "EDITOR=vim is exported from a file under /etc/profile.d" \
  'EDITOR[[:space:]]*=[[:space:]]*"?vim' /etc/profile.d/*.sh
check_persisted "HISTSIZE=5000 is exported from a file under /etc/profile.d" \
  'HISTSIZE[[:space:]]*=[[:space:]]*"?5000' /etc/profile.d/*.sh
check_persisted "PATH gains each account's own bin, not one hardcoded home" \
  'PATH=.*(\$HOME|\$\{HOME\}|~)/bin' /etc/profile.d/*.sh
check_persisted "ana's soft nproc limit is written under /etc/security" \
  '^[[:space:]]*ana[[:space:]]+soft[[:space:]]+nproc[[:space:]]+100[[:space:]]*$' \
  /etc/security/limits.d/*.conf /etc/security/limits.conf
check_persisted "ana's hard nproc limit is written under /etc/security" \
  '^[[:space:]]*ana[[:space:]]+hard[[:space:]]+nproc[[:space:]]+200[[:space:]]*$' \
  /etc/security/limits.d/*.conf /etc/security/limits.conf
check_persisted "ana's soft nofile limit is written under /etc/security" \
  '^[[:space:]]*ana[[:space:]]+soft[[:space:]]+nofile[[:space:]]+4096[[:space:]]*$' \
  /etc/security/limits.d/*.conf /etc/security/limits.conf

summary
