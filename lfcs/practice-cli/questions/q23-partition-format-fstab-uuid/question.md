# Q23. Partition a disk, format it, and mount it by UUID

A spare block device has been handed to this host. The setup printed its name, and `lsblk -f` shows it with no filesystem, no partitions and no mount point.

Prepare it for use:

- Put a GPT label on it and create **one** partition that spans the whole disk.
- Format that partition **ext4** with the filesystem label `data`.
- Mount it at `/data` with the `noatime` option.
- Make the mount permanent, and write the `/etc/fstab` line so that it refers to the filesystem by **UUID**, not by device name.

Do not touch any other disk. Only the device the setup named is spare.

The grader reads `blkid`, `findmnt` and `/etc/fstab` separately. A filesystem that is mounted but missing from `/etc/fstab` scores nothing, and neither does an `/etc/fstab` line that names `/dev/sdb1` instead of its UUID. The grader also runs `findmnt --verify`, so an fstab line that does not parse fails the question even if the mount is up.
