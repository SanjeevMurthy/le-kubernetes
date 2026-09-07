# Q45. Resolve users from an LDAP directory (solution)

## Steps

**1. Confirm the directory answers before configuring anything against it.**

```bash
ldapsearch -x -H ldap://localhost -b dc=lab,dc=local '(uid=ldapuser)' uid uidNumber
```

**2. Install the client packages if they are missing.**

```bash
apt install -y sssd sssd-ldap ldap-utils        # Ubuntu
dnf install -y sssd sssd-ldap openldap-clients  # Rocky
```

**3. Write the configuration.**

```bash
cat > /etc/sssd/sssd.conf <<'SSSD'
[sssd]
domains = lab
services = nss, pam
config_file_version = 2

[domain/lab]
id_provider = ldap
auth_provider = ldap
ldap_uri = ldap://localhost
ldap_search_base = dc=lab,dc=local
ldap_id_use_start_tls = false
ldap_auth_disable_tls_never_use_in_production = true
cache_credentials = true
enumerate = false
SSSD

chown root:root /etc/sssd/sssd.conf
chmod 600 /etc/sssd/sssd.conf
```

**4. Point the name service switch at sssd.**

```bash
sed -i -E 's/^(passwd:.*)$/\1 sss/; s/^(group:.*)$/\1 sss/; s/^(shadow:.*)$/\1 sss/' /etc/nsswitch.conf
grep -E '^(passwd|group|shadow):' /etc/nsswitch.conf
```

```
passwd:         files systemd sss
group:          files systemd sss
shadow:         files sss
```

**5. Start it, enable it, and prove the lookup.**

```bash
systemctl enable --now sssd
systemctl is-active sssd
getent passwd ldapuser
id ldapuser
```

**6. If the lookup fails, clear the cache before changing anything else.**

```bash
systemctl stop sssd
rm -f /var/lib/sss/db/*
systemctl start sssd
journalctl -u sssd -b --no-pager | tail -20
```

**7. Home directories on first login.**

```bash
pam-auth-update --enable mkhomedir              # Ubuntu
authselect select sssd with-mkhomedir --force   # Rocky
systemctl enable --now oddjobd                  # Rocky only
```

## Why

Four separate things have to be right, and each one fails in its own way.

The configuration file mode is first because it is the most surprising. sssd refuses to start when `/etc/sssd/sssd.conf` is anything other than `0600` owned by root, and the journal says so plainly. A file created with the default umask is `0644` and the daemon never comes up.

`/etc/nsswitch.conf` is second. Without `sss` on the `passwd` line, sssd runs perfectly, connects to the directory, caches nothing that anybody asks for, and `getent passwd ldapuser` returns nothing. Nothing anywhere reports an error, because no component is broken; the lookup simply never reaches sssd.

`enumerate = false` is the default and means `getent passwd` with no argument lists nothing from the directory. That is not a fault: enumeration is expensive and is off deliberately, so always query a specific name.

sssd caches aggressively, which is what makes it useful on a laptop and confusing on a lab host. After a configuration change, stop the daemon, delete `/var/lib/sss/db/*` and start it again, otherwise a stale negative answer keeps coming back.

Plain LDAP is a lab-only choice. `ldap_id_use_start_tls = false` and `ldap_auth_disable_tls_never_use_in_production = true` are the settings that say so out loud. On a real host, `ldap_tls_reqcert = demand` with the CA certificate in the trust store is the answer, and lowering `reqcert` to get past a certificate error is a change no task asks for.

Home directories on first login are a separate PAM module. Without `pam_mkhomedir` the account authenticates, lands in `/`, and the login looks broken while every lookup works.

The persistence here is the configuration file plus `systemctl enable sssd`. `enable` is the half that gets forgotten, and `systemctl is-enabled` is what a grader reads.

## Verify

```bash
getent passwd ldapuser
id ldapuser
grep -c '^ldapuser:' /etc/passwd          # expect 0, it is not a local account

systemctl is-active sssd
systemctl is-enabled sssd
stat -c '%a %U:%G %n' /etc/sssd/sssd.conf # expect 600 root:root
grep -E '^(passwd|group|shadow):' /etc/nsswitch.conf
sssctl domain-status lab
journalctl -u sssd -b --no-pager | tail -20
```

## Docs

- `man 5 sssd.conf` for the `[sssd]` and `[domain/NAME]` sections and every option above
- `man 5 sssd-ldap` for `ldap_uri`, `ldap_search_base`, `ldap_id_use_start_tls` and the TLS options
- `man 8 sssd` and `man 8 sssctl` for running and inspecting the daemon
- `man 5 nsswitch.conf` for the lookup order
- `man 8 pam_mkhomedir`, plus `man 8 pam-auth-update` on Ubuntu and `man 8 authselect` on Rocky
- `man 1 ldapsearch` for querying the directory directly, and `/usr/share/doc/sssd*/` for example configurations
