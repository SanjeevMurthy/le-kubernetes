#!/bin/bash
# Q45 LDAP client: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

echo "Checking the directory is still serving..."
check "the local directory answers on ldap://localhost" \
  ldapsearch -x -H ldap://localhost -b dc=lab,dc=local -s base
if ! ldapsearch -x -H ldap://localhost -b dc=lab,dc=local -s base >/dev/null 2>&1; then
  echo "  The directory is down, so nothing below can be graded. Run setup again."
  summary
  exit $?
fi

echo "Checking the lookup..."
PW=$(getent passwd ldapuser 2>/dev/null)
check "getent passwd ldapuser resolves" test -n "$PW"
check_eq "ldapuser has UID 5001" "5001" "$(printf '%s' "$PW" | cut -d: -f3)"
check "id ldapuser works" id ldapuser
check "grep can read /etc/passwd" grep -q '^root:' /etc/passwd
# The control case above proves the grep works, so a non-zero exit below really
# means ldapuser is absent from /etc/passwd and the answer came from the directory.
check_not "ldapuser is not a local account in /etc/passwd" grep -q '^ldapuser:' /etc/passwd

echo "Checking the daemon..."
check "sssd is running" systemctl is-active --quiet sssd
check_eq "/etc/sssd/sssd.conf is mode 600" "600" "$(stat -c %a /etc/sssd/sssd.conf 2>/dev/null)"
check_eq "/etc/sssd/sssd.conf is owned by root" "root:root" \
  "$(stat -c '%U:%G' /etc/sssd/sssd.conf 2>/dev/null)"

echo "Checking the change survives a reboot..."
check_eq "sssd is enabled" "enabled" "$(systemctl is-enabled sssd 2>/dev/null)"
check_persisted "id_provider = ldap is written in sssd.conf" \
  '^[[:space:]]*id_provider[[:space:]]*=[[:space:]]*ldap[[:space:]]*$' /etc/sssd/sssd.conf
check_persisted "ldap_uri points at the local directory in sssd.conf" \
  '^[[:space:]]*ldap_uri[[:space:]]*=[[:space:]]*ldap://localhost' /etc/sssd/sssd.conf
check_persisted "ldap_search_base is dc=lab,dc=local in sssd.conf" \
  '^[[:space:]]*ldap_search_base[[:space:]]*=[[:space:]]*dc=lab,dc=local[[:space:]]*$' /etc/sssd/sssd.conf
check_persisted "the passwd line of nsswitch.conf consults sss" \
  '^passwd:.*[[:space:]]sss([[:space:]]|$)' /etc/nsswitch.conf
check_persisted "the group line of nsswitch.conf consults sss" \
  '^group:.*[[:space:]]sss([[:space:]]|$)' /etc/nsswitch.conf
check_persisted "the shadow line of nsswitch.conf consults sss" \
  '^shadow:.*[[:space:]]sss([[:space:]]|$)' /etc/nsswitch.conf

summary
