# Q29. Encrypted volume unlocked with a key file at boot (solution)

## Steps

**1. Name the device once, and be sure it is the spare one.**

```bash
DISK=/dev/loop0          # use the device the setup printed
lsblk -f "$DISK"
```

**2. Put a LUKS header on it.** This destroys whatever was there and asks for `YES` in capitals, then a passphrase twice.

```bash
cryptsetup luksFormat "$DISK"
```

**3. Make the key file before adding it, and lock it down first.**

```bash
dd if=/dev/urandom of=/root/secret.key bs=1024 count=4
chmod 600 /root/secret.key
chown root:root /root/secret.key
```

**4. Add the key file as a second way in.** This asks for the passphrase you just chose, because you have to prove you can already open the volume.

```bash
cryptsetup luksAddKey "$DISK" /root/secret.key
cryptsetup luksDump "$DISK" | grep -i keyslot
```

**5. Open it, format it and mount it.**

```bash
cryptsetup luksOpen "$DISK" secret --key-file /root/secret.key
ls -l /dev/mapper/secret
mkfs.ext4 /dev/mapper/secret
mkdir -p /mnt/secret
mount /dev/mapper/secret /mnt/secret
```

**6. Write both persistence files.**

```bash
UUID=$(blkid -s UUID -o value "$DISK")
echo "secret  UUID=$UUID  /root/secret.key  luks" >> /etc/crypttab
echo "/dev/mapper/secret  /mnt/secret  ext4  defaults  0  2" >> /etc/fstab

findmnt --verify
```

**7. Prove the pair works without rebooting.**

```bash
umount /mnt/secret
cryptsetup close secret
cryptsetup luksOpen --test-passphrase --key-file /root/secret.key "$DISK" && echo "key file opens it"
systemctl daemon-reload
cryptdisks_start secret 2>/dev/null || cryptsetup luksOpen "$DISK" secret --key-file /root/secret.key
mount -a
findmnt -no SOURCE,TARGET /mnt/secret
```

## Why

There are two layers here and each has its own persistence file, which is the whole reason this task is worth marks.

The lower layer is the LUKS container. `/etc/crypttab` describes it in four fields: the name to open it as, the device holding the header, the key to open it with, and options. The name field is not decoration; it becomes `/dev/mapper/<name>`. Writing `secret` there is what makes `/dev/mapper/secret` exist at boot.

The upper layer is the filesystem inside the opened container, and it belongs in `/etc/fstab` like any other. The line has to name `/dev/mapper/secret`. Naming the raw device instead is the classic mistake: at the moment fstab is processed the raw device is a wall of ciphertext with no filesystem on it, so the mount fails and the boot stalls. Ordering is handled for you, because systemd generates a dependency from the crypttab entry to the mapper device, and the fstab mount waits for it.

The key file exists so the machine can unlock itself. A passphrase means someone types it at every boot; a key file readable only by root means the volume opens unattended. That is also why the mode matters: `600` and root-owned, since anything wider hands the volume to any local user. LUKS keeps up to eight key slots, so the passphrase and the key file both stay valid, and `cryptsetup luksDump` shows which slots are in use.

`--test-passphrase` opens nothing and creates no mapping. It only answers the question "would this key work", which makes it the right way to check a key file without disturbing a running mapping.

## Verify

```bash
blkid -s TYPE -o value "$DISK"        # crypto_LUKS
cryptsetup status secret
cryptsetup luksDump "$DISK" | head -20
stat -c '%a %U' /root/secret.key       # 600 root
findmnt -no SOURCE,TARGET,FSTYPE /mnt/secret
cat /etc/crypttab
grep secret /etc/fstab
findmnt --verify
```

## Docs

- `man 8 cryptsetup` for `luksFormat`, `luksAddKey`, `luksOpen`, `luksDump`, `--key-file` and `--test-passphrase`
- `man 5 crypttab` for the four fields and the option list
- `man 5 fstab` for the mount line that goes with it
- `man 8 blkid` for reading the container UUID
- `man 4 urandom` for the source of the key material
