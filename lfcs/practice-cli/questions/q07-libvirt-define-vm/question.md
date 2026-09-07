# Q07. Define a VM from a disk image and set autostart

A qcow2 disk image is waiting at `/var/lib/libvirt/images/lab.qcow2`. Turn it into a virtual machine that this host owns permanently.

1. Define a domain named `labvm` that imports that existing disk. Do not create a new disk and do not run an installer.
2. Give it 512 MiB of memory and 1 vCPU.
3. Make it start automatically when the host boots.

This lab VM has no nested virtualisation, so the domain must use the `qemu` virtualisation type rather than KVM. The domain does not have to be running when you finish.

The grader reads `virsh dominfo labvm`, `virsh domblklist labvm`, and the domain definition under `/etc/libvirt/qemu/`.
