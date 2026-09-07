# Q27. User quota on a filesystem (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Add the mount option to `/etc/fstab` first.** Nothing else works before this.

```bash
grep /quota /etc/fstab
sed -i 's|\(^[^#]*[[:space:]]/quota[[:space:]]\+ext4[[:space:]]\+\)defaults|\1defaults,usrquota|' /etc/fstab
grep /quota /etc/fstab
```

Editing the line by hand in `vi` is just as good. The fourth field has to end up as `defaults,usrquota`.

**2. Apply the option to the running system without a reboot.**

```bash
mount -o remount /quota
findmnt -no OPTIONS /quota | tr ',' '\n' | grep quota
```

**3. Build the quota accounting file and switch quotas on.**

```bash
quotacheck -cum /quota
quotaon /quota
quotaon -p -u /quota
```

**4. Set the limits for the user.**

```bash
setquota -u qa 51200 102400 0 0 /quota
repquota -u /quota
```

## Why

Quotas are a property of the mount, not of the filesystem tools. Until the filesystem carries `usrquota`, the kernel does no per-user accounting, and `quotaon` fails with a message about the option being missing. That is why the fstab edit comes first and the remount comes second: the fstab line is what the grader marks, and `mount -o remount` is what makes the same change take effect now, without a reboot and without unmounting anything that is in use.

`quotacheck -cum` creates the accounting file. `-c` creates a new one, `-u` says user quotas, and `-m` skips remounting the filesystem read-only, which matters because a busy filesystem cannot be remounted read-only and the command would otherwise stop. The file appears as `/quota/aquota.user` and holds the usage and limits for every user on that filesystem.

`setquota` takes its four numbers in a fixed order: block soft, block hard, inode soft, inode hard, then the filesystem. Blocks are 1 KB units, so 51200 is 50 MB and 102400 is 100 MB. Passing `0` means no limit, which is why both inode limits are `0` here. `edquota -u qa` opens the same values in an editor and is the interactive equivalent; `setquota` is faster and scriptable, and it does not depend on which editor the exam host has.

Soft and hard differ in what they do when a user reaches them. The hard limit is a wall: the write fails. The soft limit can be exceeded for a grace period, after which it behaves like a hard limit. `repquota` prints both, along with the grace column, which is empty until a soft limit is crossed.

## Verify

```bash
findmnt -no SOURCE,TARGET,OPTIONS /quota
quotaon -p -u /quota                 # user quota on /quota (...) is on
repquota -u /quota
grep /quota /etc/fstab
findmnt --verify
```

To see a limit bite, write as the user until the hard limit stops the write:

```bash
su - qa -c 'dd if=/dev/zero of=/quota/qa.bin bs=1M count=200'
```

## Docs

- `man 5 fstab` for where `usrquota` and `grpquota` go
- `man 8 quotacheck` for `-c`, `-u`, `-g` and `-m`
- `man 8 quotaon` for turning quotas on and for `-p`
- `man 8 setquota` for the argument order, and `man 8 edquota` for the editor form
- `man 8 repquota` for the report columns
- `man 1 quota` for what a single user sees
