# Q30. Attach a network block device and mount it

A storage host on the lab network is exporting a block device over NBD:

- server `10.99.30.2`, port `10809`
- export name `export`

Attach it to this machine and mount it:

- Load the kernel module that NBD needs.
- Connect the export to `/dev/nbd0`.
- Mount `/dev/nbd0` at `/mnt/nbd`. It already holds an ext4 filesystem with a file called `marker.txt` on it; do not reformat it.
- Copy the contents of `marker.txt` into `/opt/course/30/token.txt`.

Then make the attachment survive a reboot as far as it sensibly can:

- The `nbd` module must load at boot, from a file under `/etc/modules-load.d/` or from `/etc/modules`.
- `/etc/fstab` must carry a line for `/mnt/nbd` with both `_netdev` and `noauto` in its options.

`noauto` is deliberate. `/etc/fstab` cannot run `nbd-client`, so the device does not exist yet when the boot processes fstab; an automatic entry would stall the boot instead of helping it. The line documents the mount and makes `mount /mnt/nbd` work once the device is attached.

The grader reads `nbd-client -c`, `findmnt`, `/etc/modules-load.d/`, `/etc/modules` and `/etc/fstab`, and it runs `findmnt --verify`.
