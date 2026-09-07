# Q24. Volume group with a custom extent size and a mounted logical volume (solution)

## Steps

**1. Name the two devices once.** Use the names the setup printed.

```bash
A=/dev/loop0
B=/dev/loop1
lsblk "$A" "$B"
```

**2. Make them physical volumes.**

```bash
pvcreate "$A" "$B"
pvs
```

**3. Create the volume group with the extent size the task named.**

```bash
vgcreate -s 16M vg_data "$A" "$B"
vgs -o vg_name,vg_extent_size,vg_size,pv_count vg_data
```

**4. Create the logical volume.**

```bash
lvcreate -L 1.5G -n lv_app vg_data
lvs vg_data
```

**5. Format and mount it.**

```bash
mkfs.ext4 /dev/vg_data/lv_app
mkdir -p /app
```

**6. Persist the mount, then mount from fstab.**

```bash
echo "/dev/vg_data/lv_app  /app  ext4  defaults  0  2" >> /etc/fstab
findmnt --verify
mount -a
findmnt -no SOURCE,TARGET,FSTYPE /app
```

## Why

LVM is three layers, and each has its own command. `pvcreate` writes an LVM label onto a device so the layer above can claim it. `vgcreate` pools labelled devices into a group. `lvcreate` carves a volume out of the pool. Skipping a layer is the usual mistake: `vgcreate` on a device that was never `pvcreate`d does work, because it labels the device for you, but a task that names the physical volumes expects to see them.

`-s 16M` sets the physical extent size. An extent is the smallest unit LVM allocates, so every volume in the group is a whole number of extents. The default is 4 MB. A task that names an extent size is testing one flag and nothing else, and the flag is on `vgcreate`, not on `lvcreate`. It cannot be changed later on a group that holds data, so read the task before you type.

`-L` is an absolute size and `-l` is a count of extents or a percentage. `-L 1.5G` gives 1.5 GB. `-l 100%FREE` gives everything left. Reading one when the task said the other is the fastest way to lose this mark. With 16 MB extents, 1.5 GB is 96 extents exactly, so the volume comes out at precisely `1.50g` rather than rounded up to the next extent.

Both devices are needed because each holds only about 1008 MB of extents. LVM allocates linearly across the group, so the volume simply spans them. That is the whole point of a volume group: the volume is no longer limited by any one disk.

The volume has two device paths, `/dev/vg_data/lv_app` and `/dev/mapper/vg_data-lv_app`, and both are symlinks to the same device-mapper node. Either works in `/etc/fstab`. Unlike `/dev/sdb1`, these names are stable across reboots because LVM builds them from the group and volume names, so a UUID is not required here.

## Verify

```bash
pvs -o pv_name,vg_name,pv_size
vgs --noheadings -o vg_name,vg_extent_size,pv_count vg_data
lvs --noheadings -o lv_name,lv_size vg_data
findmnt -no SOURCE,TARGET,FSTYPE /app
grep /app /etc/fstab
findmnt --verify
```

## Docs

- `man 8 lvm` for the whole tool set and the shared options
- `man 8 pvcreate`, `man 8 vgcreate`, `man 8 lvcreate` for the three creation commands
- `man 8 vgs`, `man 8 lvs` for the reporting fields such as `vg_extent_size` and `lv_size`
- `man 5 fstab` for the mount line
- `man 8 mkfs.ext4` for the filesystem
