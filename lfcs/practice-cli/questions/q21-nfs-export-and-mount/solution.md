# Q21. Export a directory and mount it persistently (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Write the export.**

```bash
vim /etc/exports
```

```
/srv/share 10.0.0.0/8(rw,sync,no_subtree_check,no_root_squash)
```

There is no space between `10.0.0.0/8` and the opening parenthesis. With a space, the line exports the directory to that network with default options **and** to the whole world with the options in the parentheses, which is a much larger mistake than it looks.

**2. Re-export and read the table back.**

```bash
exportfs -ra
exportfs -v
exportfs -s
systemctl enable --now nfs-kernel-server      # nfs-server on Rocky
```

Setup left the unit running but disabled, so `systemctl enable` is a step that is graded on its own. `--now` covers both halves at once, and `systemctl is-enabled` is what proves the boot half.

**3. Mount it, from the network address.**

```bash
showmount -e 10.99.21.1
mkdir -p /mnt/share
mount -t nfs 10.99.21.1:/srv/share /mnt/share
findmnt -no FSTYPE,SOURCE /mnt/share
cat /mnt/share/marker
```

**4. Make the mount persistent.**

```bash
vim /etc/fstab
```

```
10.99.21.1:/srv/share  /mnt/share  nfs  defaults,_netdev  0 0
```

```bash
findmnt --verify
umount /mnt/share && mount -a && findmnt /mnt/share
```

Unmounting and running `mount -a` is the only test that proves the fstab line itself works rather than the `mount` command typed earlier.

**5. On Rocky, open the firewall if one is running.**

```bash
firewall-cmd --permanent --add-service=nfs --add-service=rpc-bind --add-service=mountd
firewall-cmd --reload
```

## Why

An `/etc/exports` line is a permission grant, written in a syntax where whitespace changes the meaning. The field order is directory, then one or more client specifications, each immediately followed by its options in parentheses. A space before the parenthesis splits one client specification into two: the named network with default options, and a wildcard client with the options that were meant for the network.

`no_root_squash` is the option worth understanding rather than memorising. By default the server maps requests from the client's root user onto the anonymous user, so root on a client cannot walk through the permissions on the server. `no_root_squash` turns that mapping off, which is genuinely what some tasks ask for and is genuinely dangerous: root on any machine in the exported network is then root on the exported files.

`exportfs -ra` re-reads `/etc/exports` and applies it. Editing the file alone changes nothing for clients already talking to the server, and `exportfs -v` or `exportfs -s` afterwards is what proves the kernel agrees with the file.

On the client side, `_netdev` tells systemd that this mount needs the network, so it is ordered after `network-online.target` and, more importantly, is not attempted during the early boot when the network is not up. Without it, a boot can sit waiting for an unreachable server. `x-systemd.automount` goes further and defers the mount until something touches the directory, which is safer still on a machine that must boot whether or not the server is there.

`findmnt --verify` parses `/etc/fstab` and reports unusable lines before a reboot does. A bad fstab line is one of the few ways to make a Linux host fail to boot from a single-line edit, which is why the check is worth running every time.

## Verify

```bash
exportfs -s                                   # the export line as the kernel holds it
exportfs -v | grep /srv/share                 # check rw or ro and the squash setting
showmount -e 10.99.21.1

findmnt -no FSTYPE,SOURCE /mnt/share          # nfs4 and 10.99.21.1:/srv/share
cat /mnt/share/marker

grep /mnt/share /etc/fstab                    # persistence, with _netdev
findmnt --verify
systemctl is-enabled nfs-kernel-server 2>/dev/null || systemctl is-enabled nfs-server
```

## Docs

- `man 5 exports` for the syntax, the client specification and every option including `no_root_squash`
- `man 8 exportfs` for `-ra`, `-v` and `-s`
- `man 5 nfs` for the client mount options and the version negotiation
- `man 8 mount.nfs` and `man 5 fstab` for the fstab line
- `man 8 showmount` for reading a server's export list
- `man 5 systemd.mount` for `_netdev` and `x-systemd.automount`
