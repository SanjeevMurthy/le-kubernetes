#!/bin/bash
# Q45 LDAP client: run a small local directory so the question is self-contained,
# load one account into it, and remove every piece of client configuration so the
# candidate writes it. If the directory cannot be brought up, stop with an error
# rather than leaving a half configured host behind.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

require_distro ubuntu || exit 1

STATE="$LFCS_STATE_DIR/q45"
mkdir -p "$STATE"

backup_file /etc/nsswitch.conf q45

if ! command -v slapd >/dev/null 2>&1 || ! command -v ldapsearch >/dev/null 2>&1; then
  pkg_install slapd ldap-utils
fi
if ! command -v slapd >/dev/null 2>&1; then
  echo "slapd is not installed and could not be installed. This question needs a local"
  echo "directory server; install the slapd package and run setup again."
  exit 1
fi
command -v sssd >/dev/null 2>&1 || pkg_install sssd sssd-ldap

systemctl enable --now slapd >/dev/null 2>&1
sleep 1

# Point the directory at dc=lab,dc=local with a known admin password. Reconfiguring
# slapd rebuilds its database, which is exactly what a repeatable lab wants.
if ! ldapsearch -x -H ldap://localhost -b dc=lab,dc=local -s base >/dev/null 2>&1; then
  debconf-set-selections <<'SEL'
slapd slapd/domain string lab.local
slapd shared/organization string LFCS Lab
slapd slapd/password1 password lfcs
slapd slapd/password2 password lfcs
slapd slapd/no_configuration boolean false
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
SEL
  DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive slapd >/dev/null 2>&1
  systemctl restart slapd >/dev/null 2>&1
  sleep 2
fi

if ! ldapsearch -x -H ldap://localhost -b dc=lab,dc=local -s base >/dev/null 2>&1; then
  echo "The local directory did not come up with the base dc=lab,dc=local."
  echo "Check 'systemctl status slapd' and 'journalctl -u slapd -b', then run setup again."
  exit 1
fi

cat > "$STATE/lab.ldif" <<'LDIF'
dn: ou=People,dc=lab,dc=local
objectClass: organizationalUnit
ou: People

dn: ou=Groups,dc=lab,dc=local
objectClass: organizationalUnit
ou: Groups

dn: cn=ldapgroup,ou=Groups,dc=lab,dc=local
objectClass: posixGroup
cn: ldapgroup
gidNumber: 5001

dn: uid=ldapuser,ou=People,dc=lab,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: ldapuser
sn: User
cn: LDAP User
uidNumber: 5001
gidNumber: 5001
homeDirectory: /home/ldapuser
loginShell: /bin/bash
LDIF

ldapadd -x -D cn=admin,dc=lab,dc=local -w lfcs -f "$STATE/lab.ldif" >/dev/null 2>&1

if ! ldapsearch -x -H ldap://localhost -b dc=lab,dc=local '(uid=ldapuser)' uid \
     2>/dev/null | grep -q '^uid: ldapuser'; then
  echo "The account ldapuser could not be loaded into the directory."
  echo "Check 'journalctl -u slapd -b', then run setup again."
  exit 1
fi

# Now take the client side apart so the candidate has real work to do.
systemctl disable --now sssd >/dev/null 2>&1
rm -f /etc/sssd/sssd.conf
rm -f /var/lib/sss/db/* 2>/dev/null
userdel -r ldapuser >/dev/null 2>&1
sed -i -E 's/^(passwd:.*)[[:space:]]+sss(.*)$/\1\2/; s/^(group:.*)[[:space:]]+sss(.*)$/\1\2/; s/^(shadow:.*)[[:space:]]+sss(.*)$/\1\2/' /etc/nsswitch.conf

echo "Setup complete."
echo "  Directory: ldap://localhost, base dc=lab,dc=local, anonymous read allowed"
echo "  Account in the directory: ldapuser, uid 5001 (it is not in /etc/passwd)"
echo "  Client state: no /etc/sssd/sssd.conf, sssd $(systemctl is-active sssd 2>/dev/null), no sss in nsswitch.conf"
echo "  getent passwd ldapuser currently returns: '$(getent passwd ldapuser 2>/dev/null)'"
echo "  /etc/nsswitch.conf is backed up under $LFCS_STATE_DIR/backup/q45"
