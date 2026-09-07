# Q25. Grow a mounted logical volume after adding a disk

The log volume `vg_ext/lv_logs` is mounted at `/var/lib/lfcs-logs` and is running out of room. It is 500 MB, and the volume group has almost no free space left. A second spare device has been attached to the host; the setup printed both device names.

Give the log volume another **400 MB**, so it ends up at 900 MB or more, and make the **filesystem** that size too.

Rules:

- `/var/lib/lfcs-logs` must stay mounted for the whole task. An application holds files open there, so unmounting it is not allowed, and the grader can tell.
- The existing file `/var/lib/lfcs-logs/app.log` must survive untouched.
- The filesystem must still mount at boot when you are done.

The grader reads `lvs` for the volume size and `df` for the filesystem size, and they are not the same thing. It also compares the mount against the one the setup created, and reads `/etc/fstab`.
