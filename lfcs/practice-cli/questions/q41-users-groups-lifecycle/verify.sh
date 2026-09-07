#!/bin/bash
# Q41 accounts: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

PW_ANA=$(getent passwd ana 2>/dev/null)

echo "Checking the groups..."
check_eq "group devs has GID 3001" "3001" "$(getent group devs 2>/dev/null | cut -d: -f3)"
check_eq "group qa has GID 3002" "3002" "$(getent group qa 2>/dev/null | cut -d: -f3)"

echo "Checking ana, one attribute at a time..."
check "the account ana exists" test -n "$PW_ANA"
check_eq "ana's UID is 2001" "2001" "$(printf '%s' "$PW_ANA" | cut -d: -f3)"
check_eq "ana's primary group is devs" "devs" "$(id -gn ana 2>/dev/null)"
check_contains "ana is a member of the supplementary group qa" "qa" "$(id -nG ana 2>/dev/null)"
check_eq "ana's login shell is /bin/bash" "/bin/bash" "$(printf '%s' "$PW_ANA" | cut -d: -f7)"
check_eq "ana's home directory is /home/ana" "/home/ana" "$(printf '%s' "$PW_ANA" | cut -d: -f6)"
check "the home directory /home/ana exists" test -d /home/ana
check_eq "/home/ana is owned by ana" "ana" "$(stat -c %U /home/ana 2>/dev/null)"
check_eq "ana's comment field is Ana Diaz" "Ana Diaz" "$(printf '%s' "$PW_ANA" | cut -d: -f5)"

EXPIRES=$(LC_ALL=C chage -l ana 2>/dev/null | awk -F: '/Account expires/ {sub(/^[[:space:]]+/, "", $2); print $2}')
check_eq "ana's account expires on 30 June 2027" "Jun 30, 2027" "$EXPIRES"
check_eq "ana has a usable password set" "P" "$(passwd -S ana 2>/dev/null | awk '{print $2}')"

echo "Checking the system account..."
PW_SVC=$(getent passwd svc-batch 2>/dev/null)
check "the account svc-batch exists" test -n "$PW_SVC"
SVC_UID=$(printf '%s' "$PW_SVC" | cut -d: -f3)
SYSTEM_UID=no
[[ "$SVC_UID" =~ ^[0-9]+$ ]] && (( SVC_UID < 1000 )) && SYSTEM_UID=yes
check_eq "svc-batch has a system UID below 1000 (read '${SVC_UID:-none}')" "yes" "$SYSTEM_UID"
check_contains "svc-batch has a shell that refuses logins" "nologin" \
  "$(printf '%s' "$PW_SVC" | cut -d: -f7)"

echo "Checking the locked account..."
check_eq "bob's password is locked" "L" "$(passwd -S bob 2>/dev/null | awk '{print $2}')"
check "bob still exists as an account" getent passwd bob
check_eq "bob's shell is unchanged" "/bin/bash" "$(getent passwd bob 2>/dev/null | cut -d: -f7)"

echo ""
echo "Note: accounts persist by themselves. /etc/passwd, /etc/shadow and /etc/group"
echo "are the files that carry every check above across a reboot."

summary
