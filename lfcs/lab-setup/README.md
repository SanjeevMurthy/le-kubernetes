# LFCS Lab Setup

Two virtual machines on this Mac: an Ubuntu 24.04 host for most of the work, and a small Rocky 9 host for the RHEL-family half of the curriculum (SELinux, firewalld, nmcli, dnf). The practice CLI runs inside them as root.

Build this on **Sunday 13 December 2026**, the first day of LFCS study. Allow an afternoon.

<!-- toc -->
## Table of Contents

- [Why two distributions](#why-two-distributions)
- [Disk space first](#disk-space-first)
- [Install VirtualBox](#install-virtualbox)
- [Download the images](#download-the-images)
- [VM specifications](#vm-specifications)
- [Create the VMs](#create-the-vms)
- [Provision](#provision)
- [Snapshots](#snapshots)
- [SSH aliases](#ssh-aliases)
- [Run the practice CLI](#run-the-practice-cli)
- [Which questions run where](#which-questions-run-where)
- [Optional: a Kubernetes cluster in the same VM](#optional-a-kubernetes-cluster-in-the-same-vm)
- [Safety](#safety)

<!-- toc stop -->

## Why two distributions

The exam is officially distribution-agnostic, and the Linux Foundation declines to say which one you get. Candidate reports point at Ubuntu, sometimes with CentOS-family nodes alongside. The curriculum settles the argument on its own: "Create and enforce MAC using SELinux" is an explicit bullet, and SELinux is not an Ubuntu technology. So: Ubuntu primary, Rocky secondary, and the notes give both commands side by side.

## Disk space first

The two VMs need about 45 GB. This Mac had roughly 26 GB free when the kit was written, so reclaim space before you start.

```bash
df -h /System/Volumes/Data                 # check free space

open -a Docker                             # only if you still need it
docker system prune -a --volumes           # usually the biggest win
minikube delete -p cks                     # after the CKS exam is behind you
minikube delete -p cka-multinode
brew cleanup
```

Target 50 GB free before creating the VMs.

## Install VirtualBox

```bash
brew install --cask virtualbox
```

VirtualBox 7.1 and later run on Apple Silicon, and only **arm64 guests**. Approve the kernel extension in System Settings, Privacy and Security, when macOS prompts, then reboot if asked.

If a VM refuses to boot, fall back to UTM. The same images and the same provisioning scripts work unchanged:

```bash
brew install --cask utm
```

## Download the images

Both are arm64 or aarch64 builds. Verify the checksum before installing; it takes a minute and saves an afternoon.

| VM | Image |
|---|---|
| `lfcs-ubuntu` | Ubuntu Server 24.04 LTS for ARM, from `https://cdimage.ubuntu.com/releases/24.04/release/` |
| `lfcs-rocky` | Rocky Linux 9 minimal for aarch64, from `https://download.rockylinux.org/pub/rocky/9/isos/aarch64/` |

```bash
shasum -a 256 ~/Downloads/ubuntu-24.04*-live-server-arm64.iso
shasum -a 256 ~/Downloads/Rocky-9*-aarch64-minimal.iso
```

## VM specifications

The spare disks are what make LVM, RAID, LUKS, quota and filesystem practice possible. The second NIC is what makes static addressing, bridging and routing practice possible. Both are why this lab beats a container.

| | `lfcs-ubuntu` | `lfcs-rocky` |
|---|---|---|
| vCPU | 2 | 2 |
| RAM | 4096 MB | 2048 MB |
| Root disk | 25 GB | 12 GB |
| Spare disks | three, 2 GB each | two, 2 GB each |
| NICs | NAT plus host-only | NAT plus host-only |
| Host-only address | 192.168.56.10 | 192.168.56.20 |

The practice CLI can also create disks from loop-backed files when no spare block device is present, so a single-disk VM still runs most storage questions. Real spare disks are better, because `lsblk` then behaves exactly as it does in the exam.

## Create the VMs

```bash
cd lfcs/lab-setup
bash vbox-create-vms.sh
```

The script creates the host-only network, both VMs, their disks and NICs, and attaches the installer images if it finds them in `~/Downloads`. Then install each operating system from the VirtualBox GUI:

- Username `lfcs` on both.
- On Ubuntu, tick **Install OpenSSH server**.
- On Rocky, choose **Minimal Install** and set SELinux to Enforcing, which is the default.
- Give the host-only interface the static address from the table, either during installation or afterwards with the provisioning script.

## Provision

Copy each script into its VM and run it as root. It installs the tool set the curriculum needs and writes the lab marker the CLI checks for.

```bash
scp lfcs/lab-setup/provision-ubuntu.sh lfcs@192.168.56.10:
ssh lfcs@192.168.56.10 'sudo bash provision-ubuntu.sh'

scp lfcs/lab-setup/provision-rocky.sh lfcs@192.168.56.20:
ssh lfcs@192.168.56.20 'sudo bash provision-rocky.sh'
```

Each finishes by printing `LFCS lab marker written`. Without `/etc/lfcs-lab` the practice CLI refuses to run, because its questions create users, repartition disks, rewrite firewall rules and restart services.

## Snapshots

Take a snapshot immediately after provisioning, before any practice. Restore it before every mock exam so each one starts from the same place.

```bash
VBoxManage snapshot lfcs-ubuntu take clean --description "provisioned, before practice"
VBoxManage snapshot lfcs-rocky  take clean --description "provisioned, before practice"

VBoxManage snapshot lfcs-ubuntu restore clean     # before a mock, or after breaking something
```

Restoring a snapshot is also the fastest recovery from a question that leaves the VM unbootable, which the boot-target and fstab questions can genuinely do. That is deliberate: recovering from a broken `/etc/fstab` is itself on the syllabus.

## SSH aliases

Append `ssh-config.example` to `~/.ssh/config`, then set up keys.

```bash
cat lfcs/lab-setup/ssh-config.example >> ~/.ssh/config
ssh-copy-id node1
ssh-copy-id node2
ssh node1 hostname
```

Using `ssh node1` and `ssh node2` from the start builds the exam habit: every task names a host, you connect to it, and you `exit` back before the next one. The provisioning scripts add matching `/etc/hosts` entries and a root key pair inside the VMs, so `ssh node2` works from within `node1` too, which the NFS and NBD questions need.

## Run the practice CLI

Inside `lfcs-ubuntu`:

```bash
git clone -b lfcs https://github.com/SanjeevMurthy/le-kubernetes ~/le-kubernetes
cd ~/le-kubernetes/lfcs/practice-cli
sudo ./lfcs --env      # what this host can run
sudo ./lfcs
```

Repeat the clone on `lfcs-rocky` for the questions tagged `rocky`.

## Which questions run where

`sudo ./lfcs --env` prints the authoritative answer for the host you are on, by matching each question's `needs` tags against the environment. Broadly:

| Host | Covers |
|---|---|
| `lfcs-ubuntu` | Everything except the SELinux and firewalld questions. Most storage questions use its spare disks; the rest fall back to loop devices. |
| `lfcs-rocky` | The `rocky`-tagged questions: SELinux contexts, ports and booleans, firewalld, nmcli, dnf. |
| Either, with a peer | NFS, NBD, routing and firewall questions use a network namespace peer created by the CLI, so a second VM is optional. The few questions tagged `host2` want the other VM reachable over SSH. |

## Optional: a Kubernetes cluster in the same VM

If you want a kubeadm cluster you own, rather than relying on Killercoda's one-hour sessions, the Ubuntu VM can host a single-node cluster. Raise its RAM to 6 GB first.

```bash
sudo bash lfcs/lab-setup/kubeadm-single-node.sh
```

This is a convenience for CKS practice, not an LFCS requirement.

## Safety

The practice CLI modifies users, sudoers, partitions, filesystems, firewall rules, network configuration and systemd units. It refuses to run on any host without `/etc/lfcs-lab`, and you should never remove that guard on a machine you care about. Snapshot before each session.
