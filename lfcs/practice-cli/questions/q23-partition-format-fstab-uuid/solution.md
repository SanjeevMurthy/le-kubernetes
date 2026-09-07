# Q23. Partition a disk, format it, and mount it by UUID (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Find the disk and prove it is the spare one.**

```bash
lsblk -f
```

The spare device has no `FSTYPE`, no `MOUNTPOINT` and no children. The setup printed its name; treat that name as the only device you may touch. Set it once so the rest of the commands cannot go to the wrong place:

```bash
DISK=/dev/sdb          # use the device the setup printed
```

**2. Label the disk and create one partition across all of it.**

```bash
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart primary ext4 1MiB 100%
partprobe "$DISK"
lsblk "$DISK"
```

The partition is `${DISK}1` on a normal disk and `${DISK}p1` on a loop device, so read the name from `lsblk` rather than assuming:

```bash
PART=$(lsblk -lnpo NAME,TYPE "$DISK" | awk '$2=="part" {print $1}')
echo "$PART"
```

**3. Make the filesystem with the label the task asked for.**

```bash
mkfs.ext4 -L data "$PART"
```

**4. Mount it and read the UUID.**

```bash
mkdir -p /data
blkid -s UUID -o value "$PART"
```

**5. Write the fstab line, then let fstab do the mounting.**

```bash
UUID=$(blkid -s UUID -o value "$PART")
echo "UUID=$UUID  /data  ext4  defaults,noatime  0  2" >> /etc/fstab

findmnt --verify
mount -a
findmnt -no SOURCE,TARGET,FSTYPE,OPTIONS /data
```

Mounting with `mount -a` rather than `mount /dev/sdb1 /data` is deliberate. It proves the line you just wrote is the line that works.

## Why

The fstab line is the answer to this task. A `mount` command that worked in front of the grader is gone after the reboot, and the exam is explicit that changes must persist.

The UUID matters for the same reason. Device names come from the order in which the kernel finds disks. Add a controller, move a cable, or attach one more virtual disk, and yesterday's `/dev/sdb` is today's `/dev/sdc`. The filesystem UUID is written inside the filesystem itself, so it follows the data. `blkid -s UUID -o value` prints the bare value with nothing to trim, which is why it is better here than plain `blkid`.

`noatime` goes in the fourth field with the other options. It stops the kernel writing an access timestamp on every read, and this is one of the standard options a task names to check you know where options live. `defaults` on its own is `rw,suid,dev,exec,auto,nouser,async`, so `defaults,noatime` keeps all of those and adds one.

The last two fields are the dump flag and the fsck pass. Use `0 2` for a data filesystem: never dumped, checked after the root filesystem. Pass `1` belongs to root alone.

`findmnt --verify` parses `/etc/fstab` and reports lines that cannot work: an unknown filesystem type, a missing mount point, a target that is not a directory. Run it before you walk away. A broken fstab line does not fail quietly, it stops the next boot, and repairing that from a rescue prompt costs far more time than the check.

## Verify

```bash
lsblk -f "$DISK"
blkid -s TYPE -o value "$PART"      # ext4
blkid -s LABEL -o value "$PART"     # data
findmnt -no SOURCE,TARGET,FSTYPE,OPTIONS /data
grep /data /etc/fstab
findmnt --verify
```

To be certain the persistence really works, unmount and let fstab remount:

```bash
umount /data && mount -a && findmnt -no TARGET /data
```

## Docs

- `man 5 fstab` for the six fields and the option list
- `man 8 parted` for `mklabel`, `mkpart` and the `1MiB` alignment convention
- `man 8 mkfs.ext4` for `-L` and the other filesystem options
- `man 8 blkid` for `-s` and `-o value`
- `man 8 findmnt` for `--verify` and the output columns
- `man 8 lsblk` for `-f`, `-p` and the column list
