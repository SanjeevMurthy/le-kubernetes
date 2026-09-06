# LFCS Users and Groups (10%)

Users and Groups is 10 percent of the LFCS exam, which is roughly two of the 17 to 20 tasks. The exam runs for 2 hours and 67 percent is the pass mark, so a two-task domain is worth about a tenth of the score and every parameter in the prompt is graded separately.

The only documentation allowed is man pages, the documents the distribution installs under `/usr/share/doc`, and packages that are part of the distribution. There is no browser and no internet, so every `**Docs.**` line below names a man page and its section. This domain is unusually well served by man pages: `man 5 sudoers`, `man 5 limits.conf` and `man 1 setfacl` all carry worked examples that can be copied straight into an answer.

Each task runs on its own designated host reached with `ssh <nodename>` from `base`, which must never be rebooted. Nested SSH is not supported. `sudo -i` gives root. Never block ports 8080, 4505 or 4506.

Accounts, sudo rules, limits and ACLs are all file-backed, so persistence here means writing the right file rather than running the right command. Every recipe names the file that makes the change survive a reboot.

<!-- toc -->
## Table of Contents

- [What the exam asks](#what-the-exam-asks)
- [Recipe 1: Create a local account with exact attributes](#recipe-1-create-a-local-account-with-exact-attributes)
- [Recipe 2: Grant sudo rights through /etc/sudoers.d](#recipe-2-grant-sudo-rights-through-etcsudoersd)
- [Recipe 3: Personal and system-wide environment profiles](#recipe-3-personal-and-system-wide-environment-profiles)
- [Recipe 4: User resource limits](#recipe-4-user-resource-limits)
- [Recipe 5: Configure and manage ACLs](#recipe-5-configure-and-manage-acls)
- [Recipe 6: LDAP user and group accounts](#recipe-6-ldap-user-and-group-accounts)
- [Ubuntu vs Rocky](#ubuntu-vs-rocky)
- [Quick reference](#quick-reference)
- [Memorise](#memorise)

<!-- toc stop -->

## What the exam asks

| Task type | Sources | Drill |
|---|---|---|
| Users and groups with a specific UID, GID, shell, home and expiry; password ageing; sudoers | 1 | Q41, Q42 (planned) |
| ACLs with `setfacl` and `getfacl` | 1 | Q43 (planned) |
| Resource limits with `ulimit` and `limits.conf` | 1 | Q44 (planned) |
| SUID, SGID and sticky bits on shared directories | 1 | Q34 (planned, note 04) |
| LDAP client with sssd or nslcd | 0 exam reports, 1 practice source | Q45 (planned) |
| Personal and system-wide environment profiles | no standalone row, named curriculum bullet | Q44 (planned) |

Sources are distinct candidate write-ups counted in the exam research report, section 3. No single row here is heavily reported, which is the point: this domain is small, mechanical and fully recoverable in five minutes per task if the flags are memorised.

## Recipe 1: Create a local account with exact attributes

**Goal.** A user with the exact UID, primary group, supplementary group, shell, home directory, comment and expiry date the task names, with each attribute provable afterwards.

**Frequency.** 1 candidate source (research section 3, users and groups row). Drill: Q41 (planned).

**Commands.**
```bash
sudo -i
groupadd -g 3001 devs                 # the primary group must exist first
groupadd -r svcaccts                  # system group, GID below SYS_GID_MAX

# Everything the task names, in one command.
useradd -u 2001 -g devs -G wheel,qa -s /bin/bash -m -d /home/ana \
        -c 'Ana Diaz' -e 2027-06-30 ana
echo 'ana:S3cretPass' | chpasswd       # or: passwd ana

# Change an existing account.
usermod -aG qa ana                    # -a appends; without it -G replaces every group
usermod -s /usr/sbin/nologin ana
usermod -L ana                        # lock the password
usermod -U ana                        # unlock it again
usermod -e 2027-12-31 ana

# Password ageing.
chage -M 90 -m 7 -W 14 -I 30 ana      # max, min, warning and inactive days
chage -E 2027-06-30 ana               # account expiry date
chage -d 0 ana                        # force a password change at next login
gpasswd -a ana devs && gpasswd -d ana qa

useradd -r -s /usr/sbin/nologin -M svcapp    # system account, no home, no login
userdel -r bob                        # -r also removes the home directory and mail spool
```
**Verify.**
```bash
id ana                     # uid=2001(ana) gid=3001(devs) groups=3001(devs),...
getent passwd ana          # ana:x:2001:3001:Ana Diaz:/home/ana:/bin/bash
getent group devs qa
chage -l ana
ls -ld /home/ana           # expect drwx------ or drwxr-x--- owned by ana:devs
```

Each flag has one command that proves it.

| Attribute | Flag used | Proof |
|---|---|---|
| UID | `-u 2001` | `id -u ana` |
| Primary group | `-g devs` | `id -gn ana` |
| Supplementary groups | `-G wheel,qa` | `id -nG ana` |
| Shell | `-s /bin/bash` | `getent passwd ana \| cut -d: -f7` |
| Home directory | `-m -d /home/ana` | `getent passwd ana \| cut -d: -f6` then `ls -ld /home/ana` |
| Comment | `-c 'Ana Diaz'` | `getent passwd ana \| cut -d: -f5` |
| Account expiry | `-e 2027-06-30` | `chage -l ana \| grep -i 'Account expires'` |
| Password state | `chpasswd` | `passwd -S ana` shows `P`, `L` or `NP` |

**Gotchas.**
- `usermod -G` without `-a` replaces every supplementary group the user had. Dropping the `-a` is how a user silently loses sudo.
- `-m` creates the home directory and copies `/etc/skel` into it. Rocky sets `CREATE_HOME yes` in `/etc/login.defs` so it happens anyway, and Ubuntu does not, so always type `-m`.
- The date format for `useradd -e` and `chage -E` is `YYYY-MM-DD`. `chage -l` prints it back in a different format, which is normal and not an error.
- `-e` expires the account and `chage -M` expires the password. A task that names a calendar date almost always means the account.
- A new account created without a password has `!` in `/etc/shadow` and cannot log in at all. Set the password or the task is unfinished.
- Defaults come from `/etc/default/useradd` and `/etc/login.defs`. `useradd -D` prints them, and editing `/etc/default/useradd` is how a task that says "for all future users" is answered.
- Persistence is automatic here. The account lives in `/etc/passwd`, `/etc/shadow` and `/etc/group`, and nothing needs restarting.

**Docs.** `man 8 useradd`, `man 8 usermod`, `man 8 userdel`, `man 8 groupadd`, `man 1 chage`, `man 1 gpasswd`, `man 1 passwd`, `man 5 passwd`, `man 5 shadow`, `man 5 group`, `man 5 login.defs`.

## Recipe 2: Grant sudo rights through /etc/sudoers.d

**Goal.** A user or a group with exactly the sudo rights the task names, in a validated drop-in file, with `/etc/sudoers` untouched.

**Frequency.** 1 candidate source (research section 3, users and groups row, which names sudoers as a gotcha). Drill: Q42 (planned).

**Commands.**
```bash
sudo -i
# Never open /etc/sudoers in a plain editor. visudo refuses to save a broken file.
visudo -f /etc/sudoers.d/ops

# Non-interactive equivalent, followed immediately by validation.
cat > /etc/sudoers.d/ops <<'SUDO'
# Group ops may restart nginx with no password prompt.
%ops    ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx
# User ana gets full sudo, with a password.
ana     ALL=(ALL:ALL) ALL
# An alias keeps a long command list readable.
Cmnd_Alias SVC = /usr/bin/systemctl start nginx, /usr/bin/systemctl stop nginx
%web    ALL=(root) NOPASSWD: SVC
SUDO
chown root:root /etc/sudoers.d/ops
chmod 440 /etc/sudoers.d/ops
visudo -c -f /etc/sudoers.d/ops     # parse this one file
visudo -c                           # parse /etc/sudoers and every include

usermod -aG sudo ana                # Ubuntu administrators group
usermod -aG wheel ana               # Rocky administrators group
```
**Verify.**
```bash
visudo -c                                  # every file must report "parsed OK"
sudo -l -U ana                             # exactly the rules that apply to ana
stat -c '%a %U:%G %n' /etc/sudoers.d/ops   # expect 440 root:root
sudo -u ana sudo -n /usr/bin/systemctl restart nginx; echo "exit=$?"
grep -E '^[#@]includedir' /etc/sudoers     # the drop-in directory must be included
id -nG ana | tr ' ' '\n' | grep -x -e sudo -e wheel
```
**Gotchas.**
- A syntax error in `/etc/sudoers` locks every user out of sudo on that host. `visudo` is the only safe editor because it parses before it saves, and `visudo -c` re-checks afterwards.
- Files in `/etc/sudoers.d/` must be mode 0440 and owned by `root:root`. Any other mode is ignored silently, with no warning anywhere.
- A filename containing a dot, or ending in `~`, is skipped entirely. Use plain names such as `ops` or `10-ops`.
- The directory is read only because `/etc/sudoers` ends with an include directive. Ubuntu writes `@includedir /etc/sudoers.d` and Rocky writes `#includedir /etc/sudoers.d`. The leading `#` there is the directive, not a comment.
- Command paths must be absolute. `NOPASSWD: systemctl` never matches anything.
- Last match wins, so a later blanket `ALL` rule overrides an earlier restriction. Order the lines deliberately and read `sudo -l -U` rather than the file.
- `%name` is a group and a bare name is a user. `(ALL:ALL)` names the run-as user and the run-as group.
- The drop-in file itself is the persistence. Nothing needs reloading or restarting.

**Docs.** `man 5 sudoers`, especially SUDOERS FILE FORMAT and the EXAMPLES section at the end, `man 8 visudo` for `-c` and `-f`, `man 8 sudo` for `-l`, `-U` and `-n`.

## Recipe 3: Personal and system-wide environment profiles

**Goal.** A variable, PATH entry, alias or umask in place for every login, or for one user only, still there after a reboot.

**Frequency.** No standalone row in research section 3. It is a named curriculum bullet under Users and Groups. Drill: Q44 (planned).

**Commands.**
```bash
sudo -i
# System wide, login shells. The right place for a new variable or PATH entry.
cat > /etc/profile.d/company.sh <<'PROF'
export COMPANY_ENV=production
export PATH="$PATH:/opt/company/bin"
umask 0027
PROF
chmod 644 /etc/profile.d/company.sh

# System wide, non-login interactive shells. Aliases and prompts belong here.
vi /etc/bash.bashrc        # Ubuntu
vi /etc/bashrc             # Rocky

# Simple key=value pairs read by PAM for every session, login or not.
# No shell syntax at all: no export, no $VAR expansion, no command substitution.
echo 'EDITOR=vim' >> /etc/environment

# Per user.
vi /home/ana/.bashrc         # every interactive shell
vi /home/ana/.profile        # login shells, the Ubuntu default dotfile
vi /home/ana/.bash_profile   # login shells, the Rocky default dotfile

# What every future account receives at creation time.
ls -la /etc/skel
cp /etc/skel/.bashrc /home/newuser/.bashrc && chown newuser: /home/newuser/.bashrc

source /etc/profile.d/company.sh     # apply in the current shell without logging out
```
**Verify.**
```bash
su - ana -c 'echo "$COMPANY_ENV"; echo "$PATH"; umask'
bash -lc 'env | grep COMPANY_ENV'
grep -rn COMPANY_ENV /etc/profile.d/ /etc/environment
sudo -u ana bash -ic 'alias' | head
```
**Gotchas.**
- A login shell reads `/etc/profile` and then the first of `~/.bash_profile`, `~/.bash_login` or `~/.profile` that exists. A non-login interactive shell reads `/etc/bash.bashrc` or `/etc/bashrc` and then `~/.bashrc`. An ssh command with no tty reads neither, which is why an exported variable sometimes vanishes for a script.
- Put system-wide changes in a new file under `/etc/profile.d/`, not in `/etc/profile` itself, because a package update overwrites the latter.
- `/etc/environment` is not a script. `pam_env` parses it, so `export`, `$PATH` expansion and shell comments do not work there.
- Changes take effect at the next login. Test with `su - user` or `bash -lc`, never by echoing a variable in the shell that just wrote the file.
- `/etc/skel` is copied only at account creation. Adding a file there later does nothing for users who already exist.
- The file under `/etc/profile.d/` or in the user's home directory is the persistence. An `export` typed at a prompt dies with the shell.

**Docs.** `man 1 bash` and its INVOCATION section for the startup file order, `man 5 environment`, `man 8 pam_env`, `man 8 useradd` for the `SKEL` setting, `man 5 login.defs` for `UMASK`.

## Recipe 4: User resource limits

**Goal.** A user or group that cannot exceed a named number of processes or open files, enforced at login and surviving a reboot.

**Frequency.** 1 candidate source (research section 3, resource limits row). Drill: Q44 (planned).

**Commands.**
```bash
sudo -i
cat > /etc/security/limits.d/90-devs.conf <<'LIM'
# <domain>   <type>   <item>    <value>
ana          soft     nofile    4096
ana          hard     nofile    8192
@devs        soft     nproc     100
@devs        hard     nproc     200
*            hard     core      0
LIM
chmod 644 /etc/security/limits.d/90-devs.conf

grep -rn pam_limits /etc/pam.d/       # must appear in the login stacks

ulimit -a          # every limit in the current shell
ulimit -Hn         # hard open files
ulimit -Su         # soft process count
ulimit -n 4096     # raise the soft limit, current shell only

# Services never read limits.conf. For a unit, use a drop-in.
mkdir -p /etc/systemd/system/app.service.d
printf '[Service]\nLimitNOFILE=8192\n' > /etc/systemd/system/app.service.d/limits.conf
systemctl daemon-reload && systemctl restart app.service
grep -n DefaultLimitNOFILE /etc/systemd/system.conf    # systemd-wide default
```
**Verify.**
```bash
su - ana -c 'ulimit -Sn; ulimit -Hn'       # expect 4096 then 8192
sudo -u ana bash -lc 'ulimit -Hu'
grep -rn nofile /etc/security/limits.conf /etc/security/limits.d/
grep -E 'open files|processes' /proc/"$(pgrep -u ana -n .)"/limits
```
**Gotchas.**
- Limits apply from the next login onward. An open session keeps its old values, so test with `su - user` rather than in the shell that wrote the file.
- The soft limit is the value a session starts with and the hard limit is the ceiling. A user may raise the soft limit up to the hard limit; only root raises the hard limit.
- `@name` is a group and a bare name is a user. `*` is the fallback for everyone and does not cover root, which needs an explicit line.
- The items are `nofile` for open files, `nproc` for processes, `fsize` for file size and `core` for core dumps. `nproc` here counts processes, unlike the `nproc` command that counts CPUs.
- Enforcement depends on `pam_limits.so` in the PAM stack of the login service. It is present by default on both distributions, so check before adding a duplicate line.
- Services started by systemd bypass this file entirely. Their limits are a unit drop-in, covered in Recipe 4 of note `04-essential-commands.md`.
- A file under `/etc/security/limits.d/` is what makes the limit persist. `ulimit` at a prompt does not survive logout.

**Docs.** `man 5 limits.conf` and its worked examples, `man 8 pam_limits`, `man 1 bash` under the `ulimit` builtin, `man 5 systemd-system.conf` for `DefaultLimitNOFILE`.

## Recipe 5: Configure and manage ACLs

**Goal.** Per-user or per-group access on a path beyond what the owner, group and other bits can express, including files created later.

**Frequency.** 1 candidate source (research section 3, ACL row). Drill: Q43 (planned).

**Commands.**
```bash
# Access ACL: applies to the file or directory itself.
setfacl -m u:ana:rwx /srv/project
setfacl -m g:qa:r-x /srv/project
setfacl -R -m u:ana:rX /srv/project     # capital X adds execute on directories only

# Default ACL: inherited by anything created inside afterwards.
setfacl -m d:u:ana:rwx /srv/project
setfacl -d -m g:qa:r-x /srv/project     # the -d form of the same thing

# Copy an ACL from one tree to another.
getfacl -p /srv/project | setfacl --set-file=- /srv/project2

setfacl -x u:ana /srv/project           # remove one named entry
setfacl -k /srv/project                 # remove only the default ACLs
setfacl -b /srv/project                 # remove every ACL entry
setfacl -m m::rx /srv/project           # set the mask explicitly

# The traditional alternative when the task only needs one group.
chgrp devs /srv/shared && chmod 2775 /srv/shared    # SGID keeps the group on new files
```
**Verify.**
```bash
getfacl -p /srv/project
ls -ld /srv/project                     # a trailing + in the mode means an ACL exists
sudo -u ana test -w /srv/project && echo WRITABLE
sudo -u ana touch /srv/project/new && getfacl -p /srv/project/new
getfacl /srv/project | grep -E '^mask|effective'
```
**Gotchas.**
- The `+` at the end of the mode in `ls -l` is the only visible sign that a file carries an ACL. Read it before trusting the nine permission bits.
- The mask is the ceiling for every named user, every named group and the owning group. An entry can grant `rwx` and still be effective `r--`, and `getfacl` marks that with `#effective:`.
- A `chmod` on the group bits rewrites the mask and silently reduces every named entry. Run `chmod` first and set the ACL afterwards.
- A default ACL affects only files created after it is set. Existing files need `setfacl -R` as well, so most tasks need both `-R` and a `d:` entry.
- `getfacl -p` keeps the leading slash on the path, which matters when the output is piped into `setfacl --set-file=-`.
- An ACL lives in an extended attribute on the filesystem, so it persists on its own. `cp` drops it unless `-a` or `--preserve=xattr` is used, and `tar` needs `--acls`.
- The filesystem must support ACLs. ext4 and xfs enable them by default on current kernels, and `tune2fs -l /dev/sdX | grep 'Default mount options'` confirms it on ext4.

**Docs.** `man 1 setfacl` and its EXAMPLES section, `man 1 getfacl`, `man 5 acl` for the mask and inheritance rules, `man 1 chmod`.

## Recipe 6: LDAP user and group accounts

**Goal.** The host resolves users and groups from an LDAP directory, they can log in, and a home directory appears on first login.

**Frequency.** No exam report in research section 3, and 1 practice source (a KodeKloud mock task built around a missing `/etc/nslcd.conf`). It is a named curriculum bullet. Drill: Q45 (planned).

**Commands.**
```bash
sudo -i
apt install -y sssd-ldap ldap-utils                 # Ubuntu
dnf install -y sssd sssd-ldap openldap-clients      # Rocky

cat > /etc/sssd/sssd.conf <<'SSSD'
[sssd]
domains = example
services = nss, pam
config_file_version = 2

[domain/example]
id_provider = ldap
auth_provider = ldap
ldap_uri = ldap://ldap.example.com
ldap_search_base = dc=example,dc=com
ldap_tls_reqcert = demand
cache_credentials = true
enumerate = false
SSSD
chown root:root /etc/sssd/sssd.conf
chmod 600 /etc/sssd/sssd.conf          # sssd refuses to start on any other mode
systemctl enable --now sssd

# Point the name service switch at sssd.
grep -E '^(passwd|group|shadow):' /etc/nsswitch.conf
# passwd:  files sss
# group:   files sss
# shadow:  files sss

pam-auth-update --enable mkhomedir                   # Ubuntu
authselect select sssd with-mkhomedir --force        # Rocky
systemctl enable --now oddjobd                       # Rocky, creates the directory

ldapsearch -x -H ldap://ldap.example.com -b dc=example,dc=com '(uid=ana)'
```
**Verify.**
```bash
getent passwd ana              # resolves through sss, and is absent from /etc/passwd
getent group developers
id ana
systemctl is-active sssd; systemctl is-enabled sssd
sssctl domain-status example
journalctl -u sssd -b --no-pager | tail -20
```
**Gotchas.**
- `/etc/sssd/sssd.conf` must be mode 0600 owned by root. Any other mode makes sssd exit at startup, and the journal says exactly that.
- `getent passwd` with no argument lists nothing from LDAP while `enumerate = false`, which is the default and is not a fault. Always query a specific name.
- sssd caches aggressively. After a configuration change run `systemctl stop sssd`, then `rm -f /var/lib/sss/db/*`, then `systemctl start sssd`.
- `/etc/nsswitch.conf` must list `sss` for `passwd`, `group` and `shadow`. Without it the daemon runs happily and nothing resolves.
- Home directory creation is a separate PAM module. Without `pam_mkhomedir` the user authenticates, lands in `/`, and the login looks broken.
- `ldap_tls_reqcert = demand` needs the CA certificate in the host trust store. Lowering it to `allow` to get past a certificate error is a change the task almost certainly did not ask for.
- The configuration file plus `systemctl enable sssd` is the persistence. `enable` is the half that gets forgotten, and `is-enabled` is what a grader checks.

**Docs.** `man 5 sssd.conf`, `man 5 sssd-ldap`, `man 8 sssd`, `man 5 nsswitch.conf`, `man 8 pam_mkhomedir`, `man 1 ldapsearch`, plus `man 8 authselect` on Rocky and `man 8 pam-auth-update` on Ubuntu. Example configurations ship under `/usr/share/doc/sssd*/`.

## Ubuntu vs Rocky

| Item | Ubuntu | Rocky |
|---|---|---|
| Administrators group | `sudo`, so `usermod -aG sudo ana` | `wheel`, so `usermod -aG wheel ana` |
| `useradd` creates a home by default | no, always pass `-m` | yes, `CREATE_HOME yes` in `/etc/login.defs` |
| Default shell when `-s` is omitted | `/bin/sh` | `/bin/bash` |
| System-wide interactive shell rc | `/etc/bash.bashrc` | `/etc/bashrc` |
| Login dotfile created from skel | `~/.profile` | `~/.bash_profile` |
| sudoers include directive | `@includedir /etc/sudoers.d` | `#includedir /etc/sudoers.d` |
| `/etc/shadow` ownership and mode | `root:shadow`, 640 | `root:root`, 000 |
| Password quality | `apt install libpam-pwquality`, then `/etc/security/pwquality.conf` | already installed, same file |
| Enable a PAM feature | `pam-auth-update --enable mkhomedir` | `authselect select sssd with-mkhomedir --force` |
| LDAP client packages | `sssd-ldap ldap-utils` | `sssd sssd-ldap openldap-clients` |
| ACL tools | `apt install acl` if missing | `dnf install acl` if missing |

## Quick reference

```bash
# accounts
useradd -u 2001 -g devs -G wheel -s /bin/bash -m -d /home/ana -c 'Ana' -e 2027-06-30 ana
echo 'ana:pass' | chpasswd; usermod -aG qa ana; usermod -L ana; userdel -r bob
groupadd -g 3001 devs; gpasswd -a ana devs; gpasswd -d ana qa
chage -M 90 -m 7 -W 14 -I 30 ana; chage -E 2027-06-30 ana; chage -d 0 ana
id ana; getent passwd ana; getent group devs; chage -l ana; passwd -S ana

# sudo
visudo -f /etc/sudoers.d/ops; chmod 440 /etc/sudoers.d/ops; chown root:root /etc/sudoers.d/ops
visudo -c; visudo -c -f /etc/sudoers.d/ops; sudo -l -U ana
%ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx

# profiles
/etc/profile.d/x.sh   system wide login shells, export and PATH and umask
/etc/bash.bashrc or /etc/bashrc   system wide interactive shells, aliases
/etc/environment      key=value only, parsed by pam_env, no shell syntax
~/.profile or ~/.bash_profile     per-user login;  ~/.bashrc  per-user interactive
/etc/skel             copied into the home directory at account creation only
su - ana -c 'echo $VAR; umask'    the only honest test

# limits
/etc/security/limits.d/90-x.conf  ->  ana soft nofile 4096   /   @devs hard nproc 200
ulimit -a; ulimit -Hn; ulimit -Su; su - ana -c 'ulimit -Sn'
grep -E 'open files|processes' /proc/PID/limits

# acls
setfacl -m u:ana:rwx PATH; setfacl -m d:g:qa:r-x PATH; setfacl -R -m u:ana:rX PATH
setfacl -x u:ana PATH; setfacl -k PATH; setfacl -b PATH
getfacl -p PATH; ls -ld PATH   # trailing + means an ACL is present

# ldap
/etc/sssd/sssd.conf mode 600 root:root; systemctl enable --now sssd
/etc/nsswitch.conf: passwd/group/shadow each "files sss"
getent passwd ana; id ana; sssctl domain-status example
```

## Memorise

- `useradd -u UID -g GROUP -G EXTRA -s SHELL -m -d HOME -c 'COMMENT' -e YYYY-MM-DD name` is the one-line answer, and every flag has a matching proof with `id`, `getent passwd` or `chage -l`.
- `usermod -aG` appends and `usermod -G` replaces. Forgetting `-a` removes every other group the user had.
- Always pass `-m`, because Ubuntu does not create a home directory without it.
- `-e` and `chage -E` expire the account; `chage -M` expires the password. Dates are `YYYY-MM-DD`.
- An account with no password set cannot log in at all, so `chpasswd` or `passwd` finishes the task.
- Sudo rights go in a file under `/etc/sudoers.d/`, mode 0440 owned by root, created or checked with `visudo -f`, and never by editing `/etc/sudoers`.
- `visudo -c` after every sudoers change, and `sudo -l -U user` to prove the result. A dot in the filename means the file is ignored.
- Administrators are the `sudo` group on Ubuntu and the `wheel` group on Rocky.
- System-wide environment goes in a new file under `/etc/profile.d/`; `/etc/environment` takes plain `KEY=value` with no shell syntax; `/etc/skel` applies only to accounts created afterwards.
- Test a profile change with `su - user -c '...'`, because the current shell already read its startup files.
- Login limits are a file under `/etc/security/limits.d/` with `domain type item value`, enforced by `pam_limits` at the next login. `ulimit` alone never persists, and services need a systemd drop-in instead.
- `setfacl -m u:name:rwx` sets an access ACL and `setfacl -m d:u:name:rwx` sets the inherited default. Most tasks need `-R` for existing files and a `d:` entry for future ones.
- The ACL mask caps every named entry, `getfacl` flags the result as `#effective:`, and a later `chmod` on the group bits quietly rewrites the mask.
- A trailing `+` in `ls -l` is the only sign an ACL exists.
- sssd needs `/etc/sssd/sssd.conf` at mode 0600, `sss` in the three `nsswitch.conf` lines, `pam_mkhomedir` enabled, and `systemctl enable --now sssd`.
- Every change in this domain persists through a file. If no file changed, nothing was done.
