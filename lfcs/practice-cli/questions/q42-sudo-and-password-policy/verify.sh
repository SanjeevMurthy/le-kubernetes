#!/bin/bash
# Q42 sudo and ageing: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

SUDOERS_BACKUP="$LFCS_STATE_DIR/backup/q42/_etc_sudoers"

echo "Checking the sudo files parse..."
check "visudo -c reports every sudo file parsed OK" visudo -c
check "/etc/sudoers itself is unchanged" diff -q "$SUDOERS_BACKUP" /etc/sudoers

echo "Checking what sudo actually grants..."
ANA_RULES=$(sudo -l -U ana 2>/dev/null)
OPS_RULES=$(sudo -l -U opsman 2>/dev/null)
check_contains "ana may run any command as any user" "ALL) ALL" "$ANA_RULES"
check_contains "opsman may restart nginx without a password" \
  "NOPASSWD: /usr/bin/systemctl restart nginx" "$OPS_RULES"
check_not "opsman was not given blanket sudo rights" \
  grep -q 'ALL) ALL' <<< "$OPS_RULES"

echo "Checking the rules live in /etc/sudoers.d and will be read..."
check_persisted "ana's rule is in a file under /etc/sudoers.d" \
  '^[[:space:]]*ana[[:space:]]+ALL[[:space:]]*=' /etc/sudoers.d/*
check_persisted "the ops group rule is in a file under /etc/sudoers.d" \
  '^[[:space:]]*%ops[[:space:]]+ALL[[:space:]]*=.*NOPASSWD:[[:space:]]*/usr/bin/systemctl restart nginx' \
  /etc/sudoers.d/*

BADFILE=""
for f in /etc/sudoers.d/*; do
  [[ -f "$f" ]] || continue
  grep -Eq '^[[:space:]]*(ana|%ops)[[:space:]]' "$f" || continue
  case "${f##*/}" in *.*|*'~') BADFILE="$BADFILE ${f##*/} (sudo skips this name)" ;; esac
  [[ "$(stat -c '%a %U:%G' "$f")" == "440 root:root" ]] || BADFILE="$BADFILE ${f##*/} ($(stat -c '%a %U:%G' "$f"))"
done
check_eq "every rule file is mode 440 root:root with a name sudo will read" "" "$BADFILE"

echo "Checking the system-wide password default..."
check_persisted "PASS_MAX_DAYS is 90 in /etc/login.defs" \
  '^[[:space:]]*PASS_MAX_DAYS[[:space:]]+90[[:space:]]*$' /etc/login.defs

echo "Checking ana's own password ageing..."
AGE=$(LC_ALL=C chage -l ana 2>/dev/null)
agefield() { printf '%s\n' "$AGE" | awk -F: -v k="$1" '$0 ~ k {gsub(/[[:space:]]/, "", $2); print $2; exit}'; }
check_eq "ana's password expires after 60 days" "60" "$(agefield 'Maximum number of days')"
check_eq "ana may not change her password more often than every 7 days" "7" "$(agefield 'Minimum number of days')"
check_eq "ana is warned 14 days ahead" "14" "$(agefield 'Number of days of warning')"

echo "Checking the minimum password length..."
check_persisted "minlen is 12 in /etc/security/pwquality.conf" \
  '^[[:space:]]*minlen[[:space:]]*=[[:space:]]*12[[:space:]]*$' /etc/security/pwquality.conf

summary
