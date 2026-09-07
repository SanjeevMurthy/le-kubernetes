# Q21. Export a directory and mount it persistently

This host is both the NFS server and the NFS client for this task. Setup has created `/srv/share` with a file called `marker` in it, started the NFS server without enabling it, and given the host a second address, `10.99.21.1`, with a peer at `10.99.21.2`.

**Server side.** Export `/srv/share` to the network `10.0.0.0/8`:

- read-write
- without squashing root, so a root client keeps root privileges on the share
- synchronous writes
- the NFS server unit starts at boot, because it is running now but disabled, so a reboot would leave the export unserved

**Client side.** Mount that export at `/mnt/share`:

- the mount is live now, and `/mnt/share/marker` is readable
- the mount comes back after a reboot, from `/etc/fstab`
- the fstab line carries `_netdev`, so a boot does not hang waiting for a network that is not up yet
- `findmnt --verify` reports no problem with the fstab

Mount from `10.99.21.1`, not from `localhost`. The export is offered to `10.0.0.0/8` and `127.0.0.1` is not in that network, so a loopback mount is refused by the server.

The words matter here more than anywhere else in this exam. `ro` against `rw`, and `root_squash` against `no_root_squash`, are single words that decide the grade. Re-read the task before you leave the host.
