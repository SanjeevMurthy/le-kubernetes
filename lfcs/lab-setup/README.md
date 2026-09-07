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

Repeat the clone on `lfcs-rocky`. Only one question is tagged `rocky`, but most of the bank is worth a second pass there: the questions branch on the distribution, so the same task teaches you `firewall-cmd`, `nmcli` and `dnf` on Rocky where it taught you `ufw`, netplan and `apt` on Ubuntu. That is the point of keeping both.

## Which questions run where

`sudo ./lfcs --env` prints the authoritative answer for the host you are on, by matching each question's `needs` tags against the environment. Broadly:

| Host | Covers |
|---|---|
| `lfcs-ubuntu` | Everything except the SELinux question. Most storage questions use its spare disks; the rest fall back to loop devices. |
| `lfcs-rocky` | The SELinux question, and a second run of anything you want to practise the RHEL-family way. Only the LDAP question cannot run here, because Rocky 9 ships no OpenLDAP server. |
| Either, with a peer | NFS, NBD, routing and firewall questions use a network namespace peer created by the CLI, so a second VM is optional. The few questions tagged `host2` want the other VM reachable over SSH. |

<!-- lab-table -->

`sudo ./lfcs --env` prints the authoritative answer for the host you are on, by matching each question's `needs` tags against the environment. In summary, **43 of the 45 questions run on either virtual machine**, 1 is Ubuntu-only and 1 is Rocky-only.

| # | Question | Domain | Ubuntu | Rocky | Also needs |
|---|---|---|---|---|---|
| Q1 | Kernel parameters now and after reboot | D1 | yes | yes | — |
| Q2 | Find the disk-reading process, record its PID, lower its priority | D1 | yes | yes | `pidstat` |
| Q3 | Scheduled jobs for a user, root, and a one-off | D1 | yes | yes | — |
| Q4 | A timer that runs a script every 15 minutes | D1 | yes | yes | — |
| Q5 | Install, hold, verify, and report packages | D1 | yes | yes | — |
| Q6 | Default target and GRUB timeout, persistent | D1 | yes | yes | — |
| Q7 | Define a VM from a disk image and set autostart | D1 | yes | yes | libvirt, `qemu-img` |
| Q8 | Run a web container with limits and a restart policy that survives reboot | D1 | yes | yes | `podman` |
| Q9 | Serve a custom document root on a custom port under SELinux enforcing | D1 | no | yes | `semanage` |
| Q10 | Write a service unit for an application | D1 | yes | yes | — |
| Q11 | A service fails to start: find why, fix it, make the journal persistent | D1 | yes | yes | — |
| Q12 | Static IPv4 on the second NIC, persistent | D2 | yes | yes | second NIC |
| Q13 | Persistent static route | D2 | yes | yes | second NIC |
| Q14 | Hostname, hosts file, DNS servers and search domain | D2 | yes | yes | — |
| Q15 | Time source, NTP serving, timezone | D2 | yes | yes | `chronyc` |
| Q16 | Harden sshd, key-only login with one password exception | D2 | yes | yes | — |
| Q17 | Allow only ssh, http, https and icmp, persistent, without blocking the exam ports | D2 | yes | yes | netns peer |
| Q18 | Redirect a port and masquerade a subnet, persistent | D2 | yes | yes | netns peer |
| Q19 | Put the second NIC into a bridge, persistent | D2 | yes | yes | second NIC |
| Q20 | Reverse proxy in front of an application | D2 | yes | yes | — |
| Q21 | Export a directory and mount it persistently | D2 | yes | yes | `exportfs`, netns peer |
| Q22 | The web app is unreachable from the peer, find and fix two causes | D2 | yes | yes | netns peer |
| Q23 | Partition a disk, format it, and mount it by UUID | D3 | yes | yes | spare disk or loop file |
| Q24 | Volume group with a custom extent size and a mounted logical volume | D3 | yes | yes | spare disk or loop file |
| Q25 | Grow a mounted logical volume after adding a disk | D3 | yes | yes | spare disk or loop file |
| Q26 | Add a swap file with a priority, persistent | D3 | yes | yes | — |
| Q27 | User quota on a filesystem | D3 | yes | yes | spare disk or loop file |
| Q28 | Mirror two disks with mdadm and mount the array | D3 | yes | yes | spare disk or loop file, `mdadm` |
| Q29 | Encrypted volume unlocked with a key file at boot | D3 | yes | yes | spare disk or loop file, `cryptsetup` |
| Q30 | Attach a network block device and mount it | D3 | yes | yes | netns peer, `nbd-client` |
| Q31 | Filesystem nearly full: recover space and find the hidden consumer | D3 | yes | yes | spare disk or loop file |
| Q32 | Clone, branch, ignore, commit, push | D4 | yes | yes | `git` |
| Q33 | Read a certificate and issue a self-signed one | D4 | yes | yes | `openssl` |
| Q34 | Locate files by owner and size, list SUID binaries, set SGID and sticky | D4 | yes | yes | — |
| Q35 | Reports from a log with grep, sort, uniq, sed and awk | D4 | yes | yes | — |
| Q36 | Archive with exclusions, extract, symbolic and hard links | D4 | yes | yes | — |
| Q37 | A script with separate stdout and stderr files | D4 | yes | yes | — |
| Q38 | A service cannot start because another one owns its port | D4 | yes | yes | — |
| Q39 | Report CPU hog, load, cores, memory and process count | D4 | yes | yes | — |
| Q40 | A service fails its file-descriptor limit: raise it with a drop-in | D4 | yes | yes | — |
| Q41 | Create users with exact attributes, a system account, and lock one | D5 | yes | yes | — |
| Q42 | Sudo rules and password ageing | D5 | yes | yes | — |
| Q43 | Group collaboration directory with ACLs | D5 | yes | yes | — |
| Q44 | System-wide environment, skeleton, and per-user limits | D5 | yes | yes | — |
| Q45 | Resolve users from an LDAP directory | D5 | yes | no | `slapd` |

The Rocky-only rows are the RHEL-family curriculum bullets: SELinux, firewalld, `nmcli` and `dnf`. The Ubuntu-only rows are its opposites: `ufw`, AppArmor and `apt`. Everything else is portable, which is the point of learning both.

Rows needing a **spare disk or loop file** work on either VM without extra disks: the CLI prefers a genuinely unused disk and falls back to a loop-backed file. Rows needing a **netns peer** create their own second host inside the VM. Only the rows marked **peer VM over SSH** want both VMs running at once.

<!-- lab-table stop -->

## Optional: a Kubernetes cluster in the same VM

If you want a kubeadm cluster you own, rather than relying on Killercoda's one-hour sessions, the Ubuntu VM can host a single-node cluster. Raise its RAM to 6 GB first.

```bash
sudo bash lfcs/lab-setup/kubeadm-single-node.sh
```

This is a convenience for CKS practice, not an LFCS requirement.

## Safety

The practice CLI modifies users, sudoers, partitions, filesystems, firewall rules, network configuration and systemd units. It refuses to run on any host without `/etc/lfcs-lab`, and you should never remove that guard on a machine you care about. Snapshot before each session.
