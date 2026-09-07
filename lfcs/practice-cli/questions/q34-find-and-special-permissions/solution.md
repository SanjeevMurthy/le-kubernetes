# Q34. Locate files by owner and size, list SUID binaries, set SGID and sticky (solution)

## Steps

**1. Find the files first, then act on them.**

```bash
find /opt/course/34/data -type f -user auditor -size +1M
```

Read that list before copying anything. When it looks right, add the action:

```bash
mkdir -p /opt/course/34/found
find /opt/course/34/data -type f -user auditor -size +1M -exec cp -p {} /opt/course/34/found/ \;
```

**2. List the SUID binaries.**

```bash
find /usr/bin -type f -perm -4000 > /opt/course/34/suid.txt
cat /opt/course/34/suid.txt
```

**3. Build the shared directory.**

```bash
chgrp devs /opt/course/34/shared
chmod 3775 /opt/course/34/shared
stat -c '%A %a %U:%G %n' /opt/course/34/shared
```

`chmod g+s,+t /opt/course/34/shared` sets the same two bits symbolically, on top of whatever mode the directory already has.

## Why

`-size +1M` counts in MiB units and rounds each file up, so `+1M` means strictly larger than one whole MiB and a 200 KiB file never matches. `-user auditor` matches by owner name, and `-type f` keeps directories out of the result, which matters because the action that follows would otherwise fire on a directory too.

`cp` without `-p` resets ownership, mode and timestamps on the copy. Any task that says "preserve" means `cp -p`, or `cp -a` when symbolic links and recursion are involved as well.

`-exec cmd {} \;` runs the command once per file, with the semicolon escaped so the shell does not eat it. `-exec cmd {} +` batches many paths into one invocation, which is faster but wrong for `cp` into a directory only in the sense that it changes nothing here; both forms work for this copy. For `rm` the batching form is the usual choice.

The three `-perm` forms are different questions. `-perm -4000` means "at least these bits are set" and is the one that finds SUID files. `-perm /4000` means "any of these bits". A bare `-perm 4000` means "exactly this mode" and matches almost nothing.

A numeric mode is absolute, so `chmod 775` would clear SUID, SGID and sticky. The fourth digit carries them: `1` is sticky, `2` is SGID, `4` is SUID, and `3775` is SGID plus sticky on top of `rwxrwxr-x`. SGID on a directory makes new files inherit the directory's group, which is what makes a shared project directory work at all. The sticky bit on a group-writable or world-writable directory stops one account deleting another account's file, and `/tmp` at mode `1777` is the model.

## Verify

```bash
ls -l /opt/course/34/found
stat -c '%a %U:%G %y %n' /opt/course/34/found/*

wc -l < /opt/course/34/suid.txt
find /usr/bin -type f -perm -4000 | wc -l        # the same number

stat -c '%A %a %U:%G %n' /opt/course/34/shared   # expect drwxrwsr-t and 3775
sudo -u auditor touch /opt/course/34/shared/probe
stat -c '%U:%G %n' /opt/course/34/shared/probe   # group devs
rm -f /opt/course/34/shared/probe
```

## Docs

- `man 1 find`, above all its EXPRESSION section for `-perm`, `-size`, `-user`, `-type` and the two `-exec` forms
- `man 1 cp` for `-p` and `-a`
- `man 1 chmod` for numeric and symbolic modes, and for the fourth digit
- `man 1 chgrp` and `man 1 chown`
- `man 1 stat` for the `%A`, `%a`, `%U` and `%G` format specifiers
- `man 7 inode` for what the SUID, SGID and sticky bits mean on files and on directories
