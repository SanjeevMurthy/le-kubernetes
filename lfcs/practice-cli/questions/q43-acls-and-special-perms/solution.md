# Q43. Group collaboration directory with ACLs (solution)

## Steps

**1. The mode bits first, because a later `chmod` rewrites the ACL mask.**

```bash
chgrp devs /srv/projects
chmod 2770 /srv/projects
stat -c '%A %a %U:%G %n' /srv/projects     # drwxrws--- 2770
```

**2. Give the qa group read and traverse, now and on everything created later.**

```bash
setfacl -m g:qa:r-x /srv/projects          # the directory itself
setfacl -m d:g:qa:r-x /srv/projects        # inherited by new files and directories
```

`setfacl -d -m g:qa:r-x /srv/projects` is the same thing written the other way.

**3. Give ana full access to the existing project directory.**

```bash
setfacl -m u:ana:rwx /srv/projects/alpha
```

**4. Read the result, mask included.**

```bash
getfacl -p /srv/projects
getfacl -p /srv/projects/alpha
```

If any line comes back with `#effective:` showing less than was granted, raise the mask:

```bash
setfacl -m m::rwx /srv/projects/alpha
```

## Why

Mode `2770` is SGID plus `rwxrwx---`. The SGID bit on a directory makes every new entry inherit the directory's group instead of the creator's primary group, which is the whole mechanism behind a shared project directory. Others get nothing, so the only way `qa` can reach anything inside is an ACL.

An access ACL applies to the object it is set on. A default ACL applies to entries created inside it afterwards, and to nothing that already exists. That is why this task needs both: `g:qa:r-x` so `qa` can traverse the directory today, and `d:g:qa:r-x` so files made tomorrow carry the same entry. Existing files inside would need `setfacl -R -m g:qa:r-x` as well, which is the third form most tasks end up using.

The mask is a ceiling over every named user, every named group and the owning group. An entry can grant `rwx` and still take effect as `r--`, and `getfacl` marks that with `#effective:` on the line. Setting the mask explicitly with `m::rwx` is the fix, and `setfacl` also recalculates it automatically whenever an entry is added, which is why the mask is usually right until a `chmod` touches the group bits and quietly narrows it again. Run `chmod` first and the ACLs afterwards.

A trailing `+` in `ls -l` is the only visible sign that an object carries an ACL at all, so read `ls -ld` before trusting the nine permission bits in front of it.

ACLs live in an extended attribute on the filesystem, so they persist by themselves with no configuration file anywhere. `cp` drops them unless `-a` or `--preserve=xattr` is used, and `tar` needs `--acls`. ext4 and xfs support ACLs by default on current kernels.

## Verify

```bash
stat -c '%A %a %U:%G %n' /srv/projects
ls -ld /srv/projects /srv/projects/alpha    # trailing + on both

getfacl -p /srv/projects
getfacl -p /srv/projects/alpha
getfacl /srv/projects | grep -E '^mask|effective'

touch /srv/projects/probe
stat -c '%G %n' /srv/projects/probe         # devs, from the SGID bit
sudo -u qauser test -r /srv/projects/probe && echo QA-CAN-READ
sudo -u ana test -w /srv/projects/alpha && echo ANA-CAN-WRITE
rm -f /srv/projects/probe
```

## Docs

- `man 1 setfacl` and its EXAMPLES section for `-m`, `-d`, `-R`, `-x`, `-k`, `-b` and `m::`
- `man 1 getfacl` for `-p` and for reading the `#effective:` annotations
- `man 5 acl` for the mask rules and how default ACLs are inherited
- `man 1 chmod` for the SGID bit and for what a numeric mode does to the mask
- `man 1 stat` and `man 7 inode` for the mode bits themselves
