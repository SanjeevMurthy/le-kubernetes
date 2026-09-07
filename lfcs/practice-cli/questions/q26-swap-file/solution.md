# Q26. Add a swap file with a priority, persistent (solution)

## Steps

**1. Create the file.**

```bash
fallocate -l 512M /swapfile2
```

If `fallocate` is unavailable or the filesystem refuses it, fall back to `dd`:

```bash
dd if=/dev/zero of=/swapfile2 bs=1M count=512 status=progress
```

**2. Lock the permissions down before anything else touches it.**

```bash
chmod 600 /swapfile2
chown root:root /swapfile2
```

**3. Format it as swap and turn it on at the priority the task named.**

```bash
mkswap /swapfile2
swapon -p 10 /swapfile2
swapon --show
```

**4. Make it come back after a reboot.**

```bash
echo "/swapfile2  none  swap  sw,pri=10  0  0" >> /etc/fstab
findmnt --verify
```

**5. Prove the fstab line works, without rebooting.**

```bash
swapoff /swapfile2
swapon -a
swapon --show=NAME,TYPE,SIZE,PRIO
```

## Why

A swap file is a plain file the kernel treats as swap space. `mkswap` writes a header into it, `swapon` hands it to the kernel, and from then on `/proc/swaps` lists it beside any swap partitions.

`chmod 600` comes first for a reason worth stating plainly: swap holds pages evicted from memory, so a readable swap file is a readable copy of whatever was in RAM. `mkswap` warns about insecure permissions, and `swapon` on some kernels refuses the file outright. Doing it before `mkswap` avoids both.

The priority decides which swap area the kernel fills first. Higher wins, and areas of equal priority are used round robin. Without `-p`, the kernel assigns a negative priority, counting down from -2 for each new area, so an unprioritised file lands behind everything already there. That is why the task names a number.

The persistence half is where the marks are. `swapon -p 10` sets the priority for this boot only. In `/etc/fstab` the priority is not a field of its own; it is an option in the fourth field, written `pri=10` next to `sw`. The second field is the mount point, and swap has none, so it is `none`. The last two fields are the dump and fsck flags, both `0`, because neither applies to swap.

`swapon -a` activates every swap entry in `/etc/fstab`, which makes it the honest test of the line you just wrote. Turning the file off and back on with `-a` proves the reboot will do the same thing.

## Verify

```bash
swapon --show=NAME,TYPE,SIZE,PRIO
cat /proc/swaps
free -h
stat -c '%a %U %s' /swapfile2      # 600 root 536870912
grep swapfile2 /etc/fstab
findmnt --verify
```

## Docs

- `man 8 mkswap` for making the swap header, and its warning about permissions
- `man 8 swapon` for `-p`, `-a`, `--show` and the priority rules
- `man 5 fstab` for where `pri=` goes and why the mount point is `none`
- `man 1 fallocate` for allocating the file, and `man 1 dd` for the fallback
- `man 5 proc` for the `/proc/swaps` columns
