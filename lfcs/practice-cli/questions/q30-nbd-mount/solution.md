# Q30. Attach a network block device and mount it (solution)

## Steps

**1. Load the module. Nothing works before this.**

```bash
modprobe nbd
ls /dev/nbd0
```

**2. Clear any stale attachment, then connect.**

```bash
nbd-client -d /dev/nbd0
nbd-client 10.99.30.2 10809 /dev/nbd0 -name export
```

**3. Confirm the device is really there before mounting it.**

```bash
nbd-client -c /dev/nbd0          # prints the pid when connected
lsblk /dev/nbd0
blkid /dev/nbd0
```

**4. Mount it and read the marker.**

```bash
mkdir -p /mnt/nbd
mount /dev/nbd0 /mnt/nbd
cat /mnt/nbd/marker.txt

mkdir -p /opt/course/30
cp /mnt/nbd/marker.txt /opt/course/30/token.txt
```

**5. Make the module load at boot.**

```bash
echo nbd > /etc/modules-load.d/nbd.conf
```

**6. Record the mount in fstab, with the two options that make it safe.**

```bash
echo "/dev/nbd0  /mnt/nbd  ext4  defaults,_netdev,noauto  0  0" >> /etc/fstab
findmnt --verify
```

To detach when you are finished:

```bash
umount /mnt/nbd
nbd-client -d /dev/nbd0
```

## Why

NBD puts a block device at the other end of a TCP connection. The server exports a file or a device, the client attaches it as `/dev/nbdN`, and from that point everything above it behaves like a local disk: `blkid` reads it, `mount` mounts it, `lsblk` lists it. Unlike NFS, which shares a filesystem, NBD shares the blocks and leaves the filesystem to the client, which is why the export already has ext4 on it and reformatting would destroy what the server holds.

The module is not loaded by default on either distribution, and without it `/dev/nbd0` does not exist at all. That is the first failure to recognise: `nbd-client` complaining about the device usually means `modprobe nbd` was skipped. `/etc/modules-load.d/*.conf` is what systemd reads at boot to load modules by name, one per line; `/etc/modules` is the older Debian file and still works.

`nbd-client -d` before connecting is the habit worth keeping. A device left attached by an earlier attempt refuses a new connection, and the error does not say so clearly. Disconnecting first costs nothing when there was nothing attached.

The persistence half is a compromise, and understanding why is the point of the question. `/etc/fstab` describes mounts; it cannot run `nbd-client`, so at the moment the boot reads fstab there is no `/dev/nbd0` to mount. An ordinary entry would therefore fail, and on a system waiting for local filesystems it can stall the boot. `_netdev` marks the mount as needing the network, which delays it until networking is up. `noauto` stops the boot from trying at all, leaving `mount /mnt/nbd` to work the moment you attach the device by hand. A genuinely automatic NBD mount needs a systemd unit that runs `nbd-client` and is ordered before the mount unit, which is more than any exam task has asked for.

## Verify

```bash
lsmod | grep '^nbd '
nbd-client -c /dev/nbd0
lsblk -no NAME,SIZE /dev/nbd0
findmnt -no SOURCE,TARGET,FSTYPE /mnt/nbd
cat /opt/course/30/token.txt
cat /etc/modules-load.d/nbd.conf
grep /mnt/nbd /etc/fstab
findmnt --verify
```

## Docs

- `man 8 nbd-client` for connecting, `-name`, `-c` and `-d`
- `man 1 nbd-server` and `man 5 nbd-server` for what the far end is doing
- `man 8 modprobe` and `man 5 modules-load.d` for loading the module now and at boot
- `man 5 fstab` for `_netdev` and `noauto`
- `man 8 findmnt`, `man 8 lsblk` for checking the result
