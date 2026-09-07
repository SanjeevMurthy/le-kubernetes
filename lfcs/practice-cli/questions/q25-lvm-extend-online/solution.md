# Q25. Grow a mounted logical volume after adding a disk (solution)

## Steps

**1. Look before you type.** Two facts decide everything: how much free space the group has, and what the filesystem is.

```bash
vgs vg_ext
lvs vg_ext
df -hT /var/lib/lfcs-logs
```

`VFree` on `vg_ext` is under 100 MB, so there is nowhere for another 400 MB to come from yet.

**2. Add the spare device to the group.**

```bash
B=/dev/loop1                 # use the device the setup printed
pvcreate "$B"
vgextend vg_ext "$B"
vgs vg_ext                   # VFree is now around 1 GB
```

**3. Grow the volume and the filesystem in one command.**

```bash
lvextend -r -L +400M /dev/vg_ext/lv_logs
```

**4. Confirm both halves moved.**

```bash
lvs --noheadings -o lv_name,lv_size vg_ext
df -hT /var/lib/lfcs-logs
findmnt -no TARGET /var/lib/lfcs-logs
```

If `lvextend` was already run without `-r`, the volume is bigger and the filesystem is not. Fix it without unmounting:

```bash
resize2fs /dev/vg_ext/lv_logs        # ext2, ext3, ext4: takes the DEVICE
# xfs_growfs /var/lib/lfcs-logs      # XFS: takes the MOUNT POINT
```

## Why

`-r` is the whole question. Without it, `lvextend` hands more extents to the volume and stops. The block device is larger, the filesystem inside it still believes it ends where it did, and `df` proves it. This is the failure that looks like success: `lvs` says `900.00m`, the task says grow the volume, and the mark is still lost. Read `df`, never `lvs`, when a task says a filesystem must have more room.

With `-r`, `lvextend` calls `fsadm`, which picks the right tool for the filesystem it finds: `resize2fs` for ext4, `xfs_growfs` for XFS. Knowing what it calls matters because the two tools disagree about their argument. `resize2fs` takes the device, `xfs_growfs` takes the mount point. Handing `xfs_growfs` a device path is a classic exam minute lost to an error message.

Growing online is safe and normal. ext4 and XFS both grow while mounted and in use, which is why nothing here needs an unmount. Neither shrinks online, and XFS never shrinks at all, so the direction of the task decides whether it is routine or impossible.

`+400M` adds 400 MB to the current size. `400M` sets the total to 400 MB, which on a 500 MB volume is a shrink, and a shrink of a mounted ext4 filesystem fails outright. The plus sign carries the whole meaning.

The `/etc/fstab` line does not change, and that is worth understanding rather than ignoring: the volume kept its identity through the resize, so the UUID the line names is still the UUID of the filesystem. If instead you had destroyed and recreated the volume to make it bigger, the new filesystem would have a new UUID, the old line would point at nothing, and the next boot would stop with a failed mount.

## Verify

```bash
pvs -o pv_name,vg_name
vgs --noheadings -o vg_name,pv_count,vg_free vg_ext
lvs --noheadings -o lv_name,lv_size vg_ext
df -BM --output=size,used,avail /var/lib/lfcs-logs
findmnt -no SOURCE,TARGET,FSTYPE /var/lib/lfcs-logs
cat /var/lib/lfcs-logs/app.log | head -1
grep lfcs-logs /etc/fstab
findmnt --verify
```

## Docs

- `man 8 lvextend` for `-r`, `-L` and the difference between `+400M` and `400M`
- `man 8 vgextend` and `man 8 pvcreate` for adding a device to an existing group
- `man 8 resize2fs` for growing ext4, and note that it takes the device
- `man 8 xfs_growfs` for growing XFS, and note that it takes the mount point
- `man 8 fsadm` for what `lvextend -r` actually calls
- `man 8 lvs`, `man 8 vgs` for the reporting fields
