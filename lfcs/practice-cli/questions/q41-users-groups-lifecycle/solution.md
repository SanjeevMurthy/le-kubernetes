# Q41. Create users with exact attributes, a system account, and lock one (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. The groups first, because a primary group must exist before the user does.**

```bash
groupadd -g 3001 devs
groupadd -g 3002 qa
```

**2. Every attribute of ana in one command.**

```bash
useradd -u 2001 -g devs -G qa -s /bin/bash -m -d /home/ana \
        -c 'Ana Diaz' -e 2027-06-30 ana
echo 'ana:Lfcs2026Pass' | chpasswd
```

**3. The system account.**

```bash
useradd -r -M -s /usr/sbin/nologin svc-batch     # Ubuntu
useradd -r -M -s /sbin/nologin svc-batch         # Rocky
```

**4. Lock bob.**

```bash
usermod -L bob
passwd -S bob        # the second field becomes L
```

`passwd -l bob` does the same thing. `usermod -U bob` or `passwd -u bob` unlocks it again.

## Why

Each flag has exactly one command that proves it, and a task like this is graded flag by flag:

| Attribute | Flag | Proof |
|---|---|---|
| UID | `-u 2001` | `id -u ana` |
| Primary group | `-g devs` | `id -gn ana` |
| Supplementary group | `-G qa` | `id -nG ana` |
| Shell | `-s /bin/bash` | `getent passwd ana \| cut -d: -f7` |
| Home | `-m -d /home/ana` | `getent passwd ana \| cut -d: -f6`, then `ls -ld` |
| Comment | `-c 'Ana Diaz'` | `getent passwd ana \| cut -d: -f5` |
| Expiry | `-e 2027-06-30` | `chage -l ana` |
| Password set | `chpasswd` | `passwd -S ana` shows `P` |

`-m` creates the home directory and copies `/etc/skel` into it. Rocky sets `CREATE_HOME yes` in `/etc/login.defs` so it happens without the flag, and Ubuntu does not, so always type `-m`.

`usermod -G` replaces every supplementary group the account had; `usermod -aG` appends. Dropping the `-a` is the usual way an account silently loses its administrator group. On a fresh `useradd`, plain `-G` is correct because there is nothing to lose yet.

`-e` and `chage -E` expire the account, and both take `YYYY-MM-DD`. `chage -M` expires the password instead, which is a different thing: a task that names a calendar date almost always means the account. `chage -l` prints the date back in a different format, which is normal.

`-r` creates a system account, taking a UID from the range below `UID_MIN` in `/etc/login.defs` and creating no home directory by default. A service account also needs a shell that refuses logins, and the path differs: `/usr/sbin/nologin` on Ubuntu, `/sbin/nologin` on Rocky.

Locking puts a `!` in front of the password hash in `/etc/shadow`, so no password can ever match. It does not stop key based ssh logins, which is why hardening tasks also set the shell to `nologin` or expire the account.

None of this needs a service restart. The accounts live in `/etc/passwd`, `/etc/shadow` and `/etc/group`, which is where the change persists.

## Verify

```bash
getent group devs qa
id ana
getent passwd ana
ls -ld /home/ana
LC_ALL=C chage -l ana | grep -i 'Account expires'
passwd -S ana                    # P in the second field

getent passwd svc-batch
passwd -S bob                    # L in the second field
```

## Docs

- `man 8 useradd` for `-u`, `-g`, `-G`, `-s`, `-m`, `-d`, `-c`, `-e`, `-r` and `-M`
- `man 8 usermod` for `-aG`, `-L` and `-U`, and `man 8 userdel` for `-r`
- `man 8 groupadd` for `-g` and `-r`
- `man 1 chage` for `-E`, `-M`, `-m`, `-W` and `-l`
- `man 1 passwd` for `-S`, `-l` and `-u`, and `man 8 chpasswd` for setting a password non-interactively
- `man 5 passwd`, `man 5 shadow`, `man 5 group` and `man 5 login.defs` for the files behind all of it
