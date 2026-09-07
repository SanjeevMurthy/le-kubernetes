# Q06. Default target and GRUB timeout, persistent (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. The default target.**

```bash
systemctl get-default            # graphical.target
systemctl set-default multi-user.target
systemctl get-default            # multi-user.target
```

**2. The GRUB timeout, in the file that GRUB is generated from.**

```bash
vi /etc/default/grub             # GRUB_TIMEOUT=10
grep '^GRUB_TIMEOUT=' /etc/default/grub
```

Without an editor:

```bash
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=10/' /etc/default/grub
```

**3. Regenerate the file the boot loader actually reads.**

```bash
update-grub                                # Ubuntu, writes /boot/grub/grub.cfg
grub2-mkconfig -o /boot/grub2/grub.cfg     # Rocky
```

**4. Prove it landed.**

```bash
grep 'timeout=10' /boot/grub/grub.cfg 2>/dev/null || grep 'timeout=10' /boot/grub2/grub.cfg
```

## Why

`systemctl set-default` replaces the symlink `/etc/systemd/system/default.target`, which is a file on disk, so the change is persistent as soon as the command returns. Its runtime-only sibling is `systemctl isolate multi-user.target`, which switches the running system immediately and is forgotten at the next boot. A task that says "by default" wants `set-default`; a task that says "right now, without rebooting" wants `isolate`.

GRUB has the same split, in a more dangerous form. `/etc/default/grub` is the source, `/boot/grub/grub.cfg` or `/boot/grub2/grub.cfg` is generated from it, and only the generated file is read at boot. Editing the source alone changes nothing until the generator runs. Editing the generated file alone works exactly until the next kernel update regenerates it and silently throws the edit away. Change the source, then run the generator, then check the generated file. That third step is the one people skip.

The two generator commands differ by family. `update-grub` on the Debian family is a small wrapper around `grub-mkconfig -o /boot/grub/grub.cfg`. The RHEL family has no wrapper, so name the output file: `grub2-mkconfig -o /boot/grub2/grub.cfg`.

Two extras worth carrying into the exam. At the GRUB menu, pressing `e` lets you append `systemd.unit=rescue.target` to the `linux` line for a one-time boot into a rescue shell, which is how a host with a broken `/etc/fstab` gets fixed. And after any change to `/etc/fstab`, `findmnt --verify` plus `mount -a` catch the mistake that would otherwise drop the next boot into emergency mode.

## Verify

```bash
systemctl get-default                                  # multi-user.target
readlink -f /etc/systemd/system/default.target

grep '^GRUB_TIMEOUT=' /etc/default/grub                # GRUB_TIMEOUT=10
grep 'timeout=10' /boot/grub/grub.cfg 2>/dev/null
grep 'timeout=10' /boot/grub2/grub.cfg 2>/dev/null
```

## Docs

- `man 1 systemctl` for `get-default`, `set-default` and `isolate`
- `man 5 systemd.special` for what `multi-user.target`, `graphical.target` and `rescue.target` mean
- `man 8 update-grub` and `man 8 grub2-mkconfig` for regenerating the boot configuration
- `man 8 grub-mkconfig` and the comments inside `/etc/default/grub` itself for the variable names
- `man 5 fstab` and `man 8 findmnt` for the neighbouring failure that stops a boot
