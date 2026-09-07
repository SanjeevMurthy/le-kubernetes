# Q24. Volume group with a custom extent size and a mounted logical volume

Two spare block devices have been handed to this host. The setup printed both names. Neither carries a partition table, a filesystem or LVM metadata.

Build LVM storage on them:

- Make both devices physical volumes.
- Create a volume group named `vg_data` that spans **both** devices, with a physical extent size of **16 MB**.
- Create a logical volume named `lv_app` of exactly **1.5 GB** in that group.
- Format it ext4 and mount it at `/app`.
- Make the mount permanent.

Neither device alone is large enough for the logical volume, so the volume group has to cover both.

The grader reads `vgs`, `lvs`, `findmnt` and `/etc/fstab` separately, and runs `findmnt --verify`. The extent size and the volume size are read as exact values: `16.00m` and `1.50g`.
