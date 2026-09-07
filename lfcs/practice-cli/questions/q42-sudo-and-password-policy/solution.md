# Q42. Sudo rules and password ageing (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. The full sudo rule for ana, in its own drop-in file.**

```bash
visudo -f /etc/sudoers.d/ana
```

```
ana     ALL=(ALL:ALL) ALL
```

The same file written without an editor, then validated immediately:

```bash
cat > /etc/sudoers.d/ana <<'SUDO'
ana     ALL=(ALL:ALL) ALL
SUDO
chown root:root /etc/sudoers.d/ana
chmod 440 /etc/sudoers.d/ana
visudo -c -f /etc/sudoers.d/ana
```

**2. The restricted rule for the ops group.**

```bash
cat > /etc/sudoers.d/ops <<'SUDO'
%ops    ALL=(root) NOPASSWD: /usr/bin/systemctl restart nginx
SUDO
chown root:root /etc/sudoers.d/ops
chmod 440 /etc/sudoers.d/ops
visudo -c
```

**3. The system-wide default password age.**

```bash
sed -i.bak -E 's/^[#[:space:]]*PASS_MAX_DAYS.*/PASS_MAX_DAYS\t90/' /etc/login.defs
grep '^PASS_MAX_DAYS' /etc/login.defs
```

**4. ana's own ageing.**

```bash
chage -M 60 -m 7 -W 14 ana
LC_ALL=C chage -l ana
```

**5. The minimum password length.**

```bash
sed -i -E 's/^[#[:space:]]*minlen[[:space:]]*=.*/minlen = 12/' /etc/security/pwquality.conf
grep '^minlen' /etc/security/pwquality.conf
```

If the line is not in the file at all, append `minlen = 12`.

## Why

`/etc/sudoers` is read as a whole, so one syntax error in it locks every account out of sudo on that host. `visudo` is the only safe way to touch any sudo file, because it parses before it saves and refuses to write a broken result. `visudo -c` re-checks `/etc/sudoers` and every file it includes; `visudo -c -f <file>` checks one file on its own.

A drop-in under `/etc/sudoers.d/` is read only because `/etc/sudoers` ends with an include directive: `@includedir /etc/sudoers.d` on Ubuntu, `#includedir /etc/sudoers.d` on Rocky. The leading `#` there is the directive itself, not a comment, which surprises people who delete it while tidying.

Three ways to make a drop-in file silently do nothing, all of them without a warning anywhere:

- any mode other than `0440`, or an owner other than `root:root`
- a dot anywhere in the filename, so `ana.conf` and `10-ops.rules` are both skipped
- a name ending in `~`, which is why an editor backup left behind is harmless but a renamed original is not

Command paths in a rule must be absolute. `NOPASSWD: systemctl` matches nothing at all. `%name` is a group and a bare name is a user. `(ALL:ALL)` names the run-as user and the run-as group. Rules are evaluated in order and the last match wins, so a later blanket rule quietly overrides an earlier restriction; read `sudo -l -U user` rather than the files when checking what a person can actually do.

`/etc/login.defs` sets defaults for accounts created afterwards. It does not touch an account that already exists, which is why `chage` is a separate step for ana rather than a consequence of step 3. `chage -M` is the password age and `chage -E` is the account expiry date, and mixing them up answers a different question than the one asked.

`pwquality.conf` is read by `pam_pwquality` when a password is set, so it constrains new passwords only. Existing short passwords keep working until they are changed. On Ubuntu the module comes from `libpam-pwquality`; on Rocky it is installed already.

Every change here is a file. Nothing needs restarting, and if no file changed then nothing was done.

## Verify

```bash
visudo -c
sudo -l -U ana
sudo -l -U opsman
stat -c '%a %U:%G %n' /etc/sudoers.d/*
grep -E '^[#@]includedir' /etc/sudoers

grep '^PASS_MAX_DAYS' /etc/login.defs
LC_ALL=C chage -l ana
grep '^minlen' /etc/security/pwquality.conf
```

## Docs

- `man 5 sudoers`, above all SUDOERS FILE FORMAT and the EXAMPLES section at the end
- `man 8 visudo` for `-c` and `-f`
- `man 8 sudo` for `-l`, `-U` and `-n`
- `man 1 chage` for `-M`, `-m`, `-W`, `-I` and `-l`
- `man 5 login.defs` for `PASS_MAX_DAYS`, `PASS_MIN_DAYS` and `PASS_WARN_AGE`
- `man 5 pwquality.conf` and `man 8 pam_pwquality` for `minlen` and the credit options
