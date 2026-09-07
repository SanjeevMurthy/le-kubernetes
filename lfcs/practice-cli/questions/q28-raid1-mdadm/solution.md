# Q28. Mirror two disks with mdadm and mount the array (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Name the devices and confirm they are empty.**

```bash
A=/dev/loop0
B=/dev/loop1
lsblk -f "$A" "$B"
cat /proc/mdstat
```

**2. Create the mirror.**

```bash
mdadm --create /dev/md0 --level=1 --raid-devices=2 "$A" "$B"
```

`mdadm` asks for confirmation when the devices could be part of a boot array; answer `y`. Watch it come up:

```bash
cat /proc/mdstat
mdadm --detail /dev/md0
```

**3. Format and mount it.**

```bash
mkfs.ext4 /dev/md0
mkdir -p /mnt/raid
```

**4. Record the array in the mdadm configuration file.** The path differs by distribution.

```bash
# Ubuntu
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
update-initramfs -u

# Rocky
mdadm --detail --scan >> /etc/mdadm.conf
dracut -f
```

**5. Persist the mount and bring it up from fstab.**

```bash
echo "/dev/md0  /mnt/raid  ext4  defaults  0  2" >> /etc/fstab
findmnt --verify
mount -a
findmnt -no SOURCE,TARGET,FSTYPE /mnt/raid
```

## Why

RAID 1 writes every block to both members, so either device alone still holds a complete copy. `--level=1 --raid-devices=2` says exactly that, and `mdadm --detail` reports it back as `Raid Level : raid1` with two active devices. The array size is the size of the smaller member, not the sum, which is the point of a mirror rather than a stripe.

The configuration file is what this question is really about. Each member carries a RAID superblock, so the kernel finds the array at boot whether or not any file mentions it. What the file decides is the **name**. With no `ARRAY` line, the array is assembled under an arbitrary name, usually `/dev/md127`, and an `/etc/fstab` line that says `/dev/md0` then fails at boot. `mdadm --detail --scan` prints the line for you, complete with the array UUID, and appending it is the whole fix.

Rebuilding the initramfs matters for the same reason. The early boot environment carries its own copy of `mdadm.conf`, and on a system where the array is needed early, the stale copy is what assembles it. `update-initramfs -u` on Ubuntu and `dracut -f` on Rocky refresh that copy.

Two commands are worth keeping apart. `mdadm --detail /dev/md0` reports on a running array. `mdadm --examine /dev/loop0` reads the superblock on one member, which is what you use when the array is not running and you need to find out what the device belongs to. `/proc/mdstat` is the fastest overall view and the only one that shows resync progress as a percentage.

## Verify

```bash
cat /proc/mdstat
mdadm --detail /dev/md0 | grep -E 'Raid Level|Active Devices|State'
mdadm --detail --export /dev/md0
grep ARRAY /etc/mdadm/mdadm.conf /etc/mdadm.conf 2>/dev/null
findmnt -no SOURCE,TARGET,FSTYPE /mnt/raid
grep /mnt/raid /etc/fstab
findmnt --verify
```

To watch the mirror survive a failure, fail and remove one member, then add it back:

```bash
mdadm /dev/md0 --fail /dev/loop1 --remove /dev/loop1
cat /proc/mdstat                       # still running, degraded
mdadm /dev/md0 --add /dev/loop1
cat /proc/mdstat                       # resyncing
```

## Docs

- `man 8 mdadm` for `--create`, `--detail`, `--examine`, `--scan`, `--fail` and `--add`
- `man 5 mdadm.conf` for the `ARRAY` line and where the file lives
- `man 4 md` for the driver, the levels and `/proc/mdstat`
- `man 8 update-initramfs` on Ubuntu, `man 8 dracut` on Rocky
- `man 5 fstab` for the mount line
