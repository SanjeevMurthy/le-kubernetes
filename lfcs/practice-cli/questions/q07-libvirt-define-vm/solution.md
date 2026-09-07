# Q07. Define a VM from a disk image and set autostart (solution)

## Steps

**1. Look at what you have been given.**

```bash
systemctl is-active libvirtd
virsh list --all
qemu-img info /var/lib/libvirt/images/lab.qcow2
```

**2. Define the domain from the existing disk.**

```bash
virt-install --name labvm \
  --memory 512 --vcpus 1 \
  --disk path=/var/lib/libvirt/images/lab.qcow2,format=qcow2,bus=virtio \
  --import --os-variant generic \
  --virt-type qemu \
  --graphics none --noautoconsole
```

The two-step form does the same thing without starting the domain, which is useful when the image has no operating system on it:

```bash
virt-install --name labvm --memory 512 --vcpus 1 \
  --disk path=/var/lib/libvirt/images/lab.qcow2,format=qcow2 \
  --import --os-variant generic --virt-type qemu --print-xml > /root/labvm.xml

virsh define /root/labvm.xml
```

**3. Turn on autostart.**

```bash
virsh autostart labvm
```

**4. Read back what libvirt recorded.**

```bash
virsh dominfo labvm
virsh domblklist labvm
```

`dominfo` should show `Autostart: enable`, `Max memory: 524288 KiB` and `CPU(s): 1`.

## Why

`virsh create file.xml` and `virsh define file.xml` look similar and behave completely differently. `create` starts a transient domain that exists only in the running libvirt daemon and disappears at the next reboot. `define` writes `/etc/libvirt/qemu/labvm.xml` and is the persistent form. `virt-install` without `--transient` defines, which is why it is the safe default here.

Autostart is a separate decision from running. It is a symlink under `/etc/libvirt/qemu/autostart/` pointing back at the domain XML. Starting a domain does not create it, and creating it does not start the domain, so a task asking for both needs both commands.

`--import` says the disk already contains a system, so skip the installer and boot straight off it. Without it, `virt-install` waits for installation media that this task never provides.

`--virt-type qemu` selects plain emulation instead of KVM acceleration. On a lab VM without nested virtualisation there is no `/dev/kvm`, and a domain defined for KVM refuses to start with a hardware acceleration error. The trade is speed, which does not matter to a grader reading `dominfo`.

`--os-variant` only sets sensible device defaults. `generic` always exists, while a guess such as `rocky9.4` fails when the local osinfo database does not know it. `osinfo-query os` lists what is available.

Memory is where arithmetic bites. `virt-install --memory` takes MiB, and `virsh dominfo` reports KiB, so 512 comes back as 524288. The domain XML uses `<memory unit='KiB'>524288</memory>` for the same reason.

One last trap on the RHEL family: the image file must be readable by the libvirt user and carry the right SELinux label. If a domain refuses to start with a permission error on the disk, run `restorecon -Rv /var/lib/libvirt/images` before looking anywhere else.

## Verify

```bash
virsh dominfo labvm
virsh domblklist labvm
virsh dumpxml labvm | grep -E 'memory unit|vcpu|source file|domain type'
ls -l /etc/libvirt/qemu/labvm.xml
ls -l /etc/libvirt/qemu/autostart/
```

## Docs

- `man 1 virt-install` for `--import`, `--virt-type`, `--os-variant` and `--print-xml`
- `man 1 virsh` for `define`, `create`, `undefine`, `autostart`, `dominfo`, `domblklist` and `dumpxml`
- `man 1 qemu-img` for `create`, `info` and `convert`
- the domain XML reference shipped under `/usr/share/doc/libvirt-daemon` for `<memory>`, `<vcpu>` and `<domain type>`
- `man 8 restorecon` when the disk image will not open on the RHEL family
