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

LAB_BASE="dc=lab,dc=local"

# Every suffix this host serves, read from the running server and from the
# configuration on disk so a slapd that is down is still seen.
slapd_suffixes() {
  ldapsearch -Y EXTERNAL -H ldapi:/// -LLL -b cn=config '(olcSuffix=*)' olcSuffix 2>/dev/null |
    sed -n 's/^olcSuffix:[[:space:]]*//p'
  ldapsearch -x -H ldap://localhost -LLL -b '' -s base namingContexts 2>/dev/null |
    sed -n 's/^namingContexts:[[:space:]]*//p'
  grep -rhs '^olcSuffix:' /etc/ldap/slapd.d 2>/dev/null |
    sed -E 's/^olcSuffix:[[:space:]]*//'
  grep -hsE '^[[:space:]]*suffix[[:space:]]+' /etc/ldap/slapd.conf 2>/dev/null |
    sed -E 's/^[[:space:]]*suffix[[:space:]]+//; s/^"//; s/"$//'
}

# True only for the empty database the Debian package writes at install time,
# which holds nothing but its own root entry and cn=admin. A directory that
# cannot be read anonymously counts as real, because it cannot be proven empty.
suffix_is_empty_default() {
  local s="$1" dns d
  dns=$(ldapsearch -x -H ldap://localhost -LLL -b "$s" -s sub dn 2>/dev/null) || return 1
  while IFS= read -r d; do
    case "$d" in
      ""|"$s"|"cn=admin,$s") ;;
      *) return 1 ;;
    esac
  done <<< "$(printf '%s\n' "$dns" | sed -n 's/^dn:[[:space:]]*//p')"
  return 0
}

# Point the directory at dc=lab,dc=local with a known admin password. Reconfiguring
# slapd rebuilds its database, which is exactly what a repeatable lab wants and is
# exactly what must never happen to a directory this question did not create:
# slapd/purge_database deletes whatever database it finds. So before purging,
# refuse outright if this host already serves any base other than the lab's.
if ! ldapsearch -x -H ldap://localhost -b "$LAB_BASE" -s base >/dev/null 2>&1; then
  FOREIGN=""
  while IFS= read -r s; do
    [[ -z "$s" ]] && continue
    case "$(printf '%s' "$s" | tr '[:upper:]' '[:lower:]')" in
      "$LAB_BASE"|cn=config|cn=monitor) continue ;;
    esac
    suffix_is_empty_default "$s" && continue
    FOREIGN="$FOREIGN    $s"$'\n'
  done <<< "$(slapd_suffixes | sed '/^$/d' | sort -u)"

  if [[ -n "$FOREIGN" ]]; then
    echo "This host already serves an OpenLDAP directory that is not this lab's:"
    printf '%s' "$FOREIGN"
    echo "Setting this question up rebuilds the slapd database with"
    echo "'dpkg-reconfigure slapd' and slapd/purge_database, which would delete it."
    echo "Refusing. Q45 will not run on a host that carries somebody else's directory."
    echo "Run it on a lab VM with no directory of its own, or move that directory off"
    echo "this host first. No directory data was changed."
    exit 1
  fi

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

if ! ldapsearch -x -H ldap://localhost -b "$LAB_BASE" -s base >/dev/null 2>&1; then
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
