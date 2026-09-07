# Q44. System-wide environment, skeleton, and per-user limits (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. The system-wide environment, in a new file under `/etc/profile.d/`.**

```bash
cat > /etc/profile.d/lab.sh <<'PROF'
export EDITOR=vim
export HISTSIZE=5000
export PATH="$HOME/bin:$PATH"
PROF
chmod 644 /etc/profile.d/lab.sh
```

**2. The skeleton directory, and an account that proves it works.**

```bash
mkdir -p /etc/skel/bin
useradd -m -s /bin/bash newbie
ls -ld /home/newbie/bin
```

**3. The per-user limits.**

```bash
cat > /etc/security/limits.d/90-ana.conf <<'LIM'
# <domain>  <type>  <item>   <value>
ana         soft    nproc    100
ana         hard    nproc    200
ana         soft    nofile   4096
LIM
chmod 644 /etc/security/limits.d/90-ana.conf
```

**4. Test as the account, not in the shell that wrote the files.**

```bash
su - ana -c 'echo "$EDITOR $HISTSIZE"; echo "$PATH"'
su - ana -c 'ulimit -Su; ulimit -Hu; ulimit -Sn'
```

## Why

A login shell reads `/etc/profile`, which sources every `*.sh` under `/etc/profile.d/`, and then the first of `~/.bash_profile`, `~/.bash_login` or `~/.profile` that exists. A non-login interactive shell reads `/etc/bash.bashrc` on Ubuntu or `/etc/bashrc` on Rocky, and then `~/.bashrc`. An ssh command with no tty reads neither, which is why an exported variable sometimes vanishes for a script that worked by hand.

Put system-wide changes in a new file under `/etc/profile.d/` rather than in `/etc/profile` itself, because a package update replaces `/etc/profile`. Both distributions source `/etc/profile.d/` after their own `HISTSIZE` assignment, so a value set there wins.

`$HOME/bin` inside the profile script expands at login, for whoever is logging in. Hardcoding `/home/ana/bin` would satisfy a test run as ana and fail the requirement, which asks for a rule that works for any account.

`/etc/environment` is the other place a variable can live, but it is not a script. `pam_env` parses plain `KEY=value` lines: no `export`, no `$VAR` expansion, no command substitution, so a `PATH` line that references `$HOME` cannot go there.

`/etc/skel` is copied into a home directory at the moment the account is created, and never again. Adding a file to it does nothing for accounts that already exist, which is why the task also asks for a new account as proof.

Limits come from a file under `/etc/security/limits.d/` in the form `domain type item value`, applied by `pam_limits` at the next login. `@name` is a group, a bare name is an account, and `*` is the fallback that does not cover root. The soft limit is what a session starts with, the hard limit is the ceiling it may raise itself to, and only root can raise a hard limit. Set both when lowering a hard limit below the current soft value, because a hard limit under the running soft limit is rejected outright.

Two more limits facts worth carrying into the exam: the item is `nproc` for processes and `nofile` for open files, so the `nproc` here has nothing to do with the `nproc` command that counts CPUs; and services started by systemd never read this file at all, because they have no login session. Their limits are a unit drop-in, which is Q40.

The persistence in this whole task is the two files, one under `/etc/profile.d/` and one under `/etc/security/limits.d/`. An `export` typed at a prompt or a `ulimit` call in a shell dies with that shell.

## Verify

```bash
su - ana -c 'echo "$EDITOR"'        # vim
su - ana -c 'echo "$HISTSIZE"'      # 5000
su - ana -c 'echo "$PATH"'          # begins with /home/ana/bin
su - ana -c 'ulimit -Su; ulimit -Hu; ulimit -Sn'   # 100, 200, 4096

ls -ld /etc/skel/bin /home/newbie/bin
grep -rn 'EDITOR\|HISTSIZE\|bin' /etc/profile.d/lab.sh
grep -rn ana /etc/security/limits.conf /etc/security/limits.d/
grep -rn pam_limits /etc/pam.d/
```

## Docs

- `man 1 bash`, its INVOCATION section, for which startup file each kind of shell reads
- `man 5 environment` and `man 8 pam_env` for `/etc/environment`
- `man 8 useradd` for the `SKEL` setting, and `man 5 login.defs` for `CREATE_HOME` and `UMASK`
- `man 5 limits.conf` and its worked examples, and `man 8 pam_limits`
- `man 1 bash` under the `ulimit` builtin for `-S`, `-H`, `-n` and `-u`
- `man 1 su` for why `su -` is the only honest way to test a login change
