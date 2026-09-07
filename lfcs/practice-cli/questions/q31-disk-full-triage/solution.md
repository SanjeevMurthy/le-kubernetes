# Q31. Filesystem nearly full: recover space and find the hidden consumer (solution)

## Steps

**1. Confirm which filesystem is full, and by how much.**

```bash
df -hT /srv/data
df -i /srv/data          # inodes, in case space is free but writes still fail
```

**2. Find the big directories, staying on this one filesystem.**

```bash
du -xh --max-depth=1 /srv/data | sort -h
du -xh --max-depth=1 /srv/data/tmp | sort -h | tail
```

**3. Delete the scratch directory, which is what you were told you may remove.**

```bash
rm -rf /srv/data/tmp/*
df -h /srv/data          # better, but still not under 60%
```

**4. Ask why `df` and `du` now disagree.** Add up what `du` sees and compare it with what `df` reports as used. The difference is space held by files that have been unlinked but are still open.

```bash
lsof +L1 | grep /srv/data
```

Without `lsof`, the same answer comes out of `/proc`:

```bash
ls -l /proc/[0-9]*/fd/* 2>/dev/null | grep '(deleted)' | grep /srv/data
```

**5. Release it by stopping the process that holds the descriptor.**

```bash
lsof +L1 | grep /srv/data          # note the PID in the second column
kill <pid>
df -h /srv/data                    # the space comes back at once
```

For a real service, restart it rather than killing it: `systemctl restart <unit>`. The descriptor is closed either way.

**6. Find the largest remaining file and record it.**

```bash
find /srv/data -xdev -type f -printf '%s %p\n' | sort -rn | head -5
mkdir -p /opt/course/31
echo /srv/data/archive/backup.tar > /opt/course/31/biggest.txt
```

`find -printf` is GNU only. A portable alternative:

```bash
find /srv/data -xdev -type f -exec ls -s {} + | sort -rn | head -5
```

## Why

`df` asks the filesystem how many blocks are allocated. `du` walks the directory tree and adds up the files it can see. They normally agree, and the interesting cases are the ones where they do not.

A deleted file that a process still has open is the classic disagreement. Unlinking removes the name from the directory, so `du` can no longer find it, but the inode and every block it owns survive until the last descriptor closes. The space is genuinely consumed and genuinely invisible. `lsof +L1` lists exactly these files: `+L` filters on link count, and `1` means fewer than one link, which is the definition of unlinked. The output gives the PID, so the fix follows immediately.

`du -x` matters more than it looks. Without it, `du /` walks into every mounted filesystem it meets, so the numbers describe several filesystems at once and the minute you spent is wasted. `-x` keeps the walk on one device, which is the one `df` was complaining about. `find -xdev` is the same idea for `find`.

`df -i` is the other disagreement worth knowing. A filesystem with millions of tiny files can run out of inodes while `df -h` still shows free space. Writes fail with "No space left on device" and the block usage looks fine. Only `df -i` shows it, and the fix is to delete files rather than free bytes.

Killing the holder is the blunt version of the fix. Restarting the service is the version you would use in production, and it is what an exam task usually means by "make the space available again". Truncating the file through its descriptor is the third option when neither is possible: `: > /proc/<pid>/fd/<n>` empties it in place without disturbing the process.

## Verify

```bash
df -hT /srv/data
du -xh --max-depth=1 /srv/data | sort -h
lsof +L1 | grep /srv/data          # no output
cat /opt/course/31/biggest.txt
findmnt -no SOURCE,TARGET /srv/data
grep /srv/data /etc/fstab
findmnt --verify
```

## Docs

- `man 8 lsof` for `+L1` and the column layout
- `man 1 du` for `-x`, `--max-depth` and `-h`
- `man 1 df` for `-h`, `-i`, `-T` and `--output`
- `man 1 find` for `-xdev`, `-size`, `-printf` and `-exec`
- `man 1 sort` for `-h` and `-rn`
- `man 5 proc` for `/proc/<pid>/fd` and what the `(deleted)` suffix means
