# Q28. Mirror two disks with mdadm and mount the array

Two spare block devices have been handed to this host. The setup printed both names. Neither carries a filesystem or a RAID superblock.

Build a mirror on them:

- Create a **RAID 1** array called `/dev/md0` from both devices, with 2 active devices.
- Format the array ext4 and mount it at `/mnt/raid`.
- Make the mount permanent.
- Make sure the array itself is defined in the mdadm configuration file for this distribution, so it comes back as `/dev/md0` rather than under some other name.

The configuration file is `/etc/mdadm/mdadm.conf` on Ubuntu and `/etc/mdadm.conf` on Rocky.

The grader reads `/sys/block/md0`, `mdadm --detail`, `findmnt`, the mdadm configuration file and `/etc/fstab`, and it runs `findmnt --verify`. An array that is running but undefined in the configuration file scores nothing, because it is the case that breaks on the next boot.
