# Q42. Sudo rules and password ageing

The accounts `ana` and `opsman` exist. `opsman` is a member of the group `ops`.

Sudo rules. Put both of these in files under `/etc/sudoers.d/`. `/etc/sudoers` itself must not change, and `visudo -c` must report every file parsed OK when you are done.

1. `ana` may run any command as any user, and she is prompted for her own password when she does.
2. Members of the group `ops` may run exactly `/usr/bin/systemctl restart nginx` as root, with no password prompt, and nothing else.

Password policy.

3. Accounts created from now on must get a maximum password age of 90 days by default. That is a system-wide setting in `/etc/login.defs`.
4. `ana`'s own password must expire after 60 days, may not be changed more often than every 7 days, and must warn her 14 days ahead.
5. A new password anywhere on this host must be at least 12 characters. That is `minlen` in `/etc/security/pwquality.conf`.

The grader runs `visudo -c`, reads `sudo -l -U ana` and `sudo -l -U opsman`, compares `/etc/sudoers` with the copy taken before you started, checks the mode and owner of the files you added, and reads `chage -l ana`, `/etc/login.defs` and `/etc/security/pwquality.conf`.
