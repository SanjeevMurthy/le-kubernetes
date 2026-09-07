#!/bin/bash
# Q45 LDAP client: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q45"

systemctl disable --now sssd >/dev/null 2>&1
rm -f /etc/sssd/sssd.conf
rm -f /var/lib/sss/db/* 2>/dev/null

restore_file /etc/nsswitch.conf q45

for dn in "uid=ldapuser,ou=People,dc=lab,dc=local" \
          "cn=ldapgroup,ou=Groups,dc=lab,dc=local" \
          "ou=Groups,dc=lab,dc=local" \
          "ou=People,dc=lab,dc=local"; do
  ldapdelete -x -D cn=admin,dc=lab,dc=local -w lfcs "$dn" >/dev/null 2>&1
done

systemctl disable --now slapd >/dev/null 2>&1
rm -rf "${LFCS_STATE_DIR:?}/q45"
rm -rf /home/ldapuser

echo "Cleanup complete. sssd.conf and its cache are gone, /etc/nsswitch.conf is restored,"
echo "the lab entries are deleted from the directory and slapd is stopped and disabled."
echo "The slapd and sssd packages themselves are left installed."
