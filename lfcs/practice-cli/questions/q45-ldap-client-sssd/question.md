# Q45. Resolve users from an LDAP directory

An LDAP directory is running on this host at `ldap://localhost`. Its base is `dc=lab,dc=local` and it holds one account, `ldapuser`, with UID `5001` under `ou=People`. Anonymous read access is allowed, so no bind credentials are needed. This host does not resolve that account yet.

1. Configure `sssd` so this host looks accounts up in that directory. Use `id_provider = ldap`, `ldap_uri = ldap://localhost` and `ldap_search_base = dc=lab,dc=local`.
2. `/etc/sssd/sssd.conf` must be owned by root with mode `0600`. sssd refuses to start with any other mode.
3. `sssd` must be running now and must start at the next boot.
4. `/etc/nsswitch.conf` must consult `sss` for `passwd`, `group` and `shadow`.
5. The proof is that `getent passwd ldapuser` returns the account with UID `5001`, while `ldapuser` still does not appear anywhere in `/etc/passwd`.

The directory has no TLS certificate, so the connection is plain LDAP. Say so in the configuration rather than leaving sssd to fail quietly.

The grader reads `getent passwd`, `id`, `systemctl is-active`, `systemctl is-enabled`, `stat` on the configuration file, `/etc/sssd/sssd.conf` and `/etc/nsswitch.conf`.
