# Q29. Encrypted volume unlocked with a key file at boot

A spare block device has been handed to this host. The setup printed its name.

Turn it into an encrypted volume that needs no one at the console:

- Encrypt the device with LUKS. Any passphrase will do; you choose it.
- Create a key file `/root/secret.key`, mode `600`, owned by root, and add it as a second way to unlock the volume.
- Unlock the volume under the name `secret`, so it appears as `/dev/mapper/secret`.
- Format it ext4 and mount it at `/mnt/secret`.
- Make both halves permanent: `/etc/crypttab` unlocks it from the key file at boot, naming the container by **UUID**, and `/etc/fstab` mounts `/dev/mapper/secret` at `/mnt/secret`.

The `/etc/fstab` line must name `/dev/mapper/secret`, not the raw device. The raw device is still encrypted at that point in the boot; only the mapper name has a filesystem on it.

The grader reads `cryptsetup status`, `blkid`, `stat`, `findmnt`, `/etc/crypttab` and `/etc/fstab`, and it runs `findmnt --verify`. It also tests the key file against the volume, so a key file that exists but unlocks nothing scores nothing.
