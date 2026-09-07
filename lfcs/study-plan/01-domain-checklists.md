# LFCS Domain Checklists

Your mastery tracker, and the coverage map for the kit. Every line is a competency from the official LFCS curriculum, paired with the note recipe that teaches it and the practice question that drills it.

Mark each line:

- `[ ]` not started
- `[~]` can do it with the notes open
- `[x]` **can do it timed, under 6 minutes, from man pages alone**

That last bar is deliberate. The exam gives you no browser, so a competency you can only do with a search engine open is not yet a competency.

Re-score on **10 Jan**, **24 Jan** and **31 Jan**.

Question ids are all marked *(planned)* until the practice CLI is built in Phase 4.

---

<!-- toc -->
## Table of Contents

- [Domain 1 — Operations Deployment (25%)](#domain-1--operations-deployment-25)
- [Domain 2 — Networking (25%)](#domain-2--networking-25)
- [Domain 3 — Storage (20%)](#domain-3--storage-20)
- [Domain 4 — Essential Commands (20%)](#domain-4--essential-commands-20)
- [Domain 5 — Users and Groups (10%)](#domain-5--users-and-groups-10)
- [Cross-cutting: the two habits the exam grades](#cross-cutting-the-two-habits-the-exam-grades)
- [Re-score log](#re-score-log)

<!-- toc stop -->

## Domain 1 — Operations Deployment (25%)

> Curriculum bullets: configure kernel parameters, persistent and non-persistent · diagnose, identify, manage, and troubleshoot processes and services · manage or schedule jobs for executing commands · search for, install, validate, and maintain software packages or repositories · recover from hardware, operating system, or filesystem failures · manage Virtual Machines (libvirt) · configure container engines, create and manage containers · create and enforce MAC using SELinux

**Kernel parameters**

- [ ] Set a parameter for this boot with `sysctl -w` and read it back with `sysctl -n` — note 01, Q1
- [ ] Make it persist in `/etc/sysctl.d/` and apply with `sysctl --system` — note 01, Q1

**Processes and services**

- [ ] Find the process consuming a resource: `ps` sorted, `top`, `pidstat -d` for disk — note 01, Q2
- [ ] Change priority with `nice` and `renice`, and send the right signal — note 01, Q2
- [ ] Write a systemd service unit with `Type`, `ExecStart`, `Restart`, `User`, `WantedBy` — note 01, Q10
- [ ] `daemon-reload`, then `enable --now`, and know why both matter — note 01, Q10
- [ ] Override a shipped unit with a drop-in rather than editing it — note 01, Q40
- [ ] Diagnose a unit that will not start from `systemctl status` and `journalctl -u` — note 01, Q11
- [ ] Mask a unit, and explain how that differs from disabling it — note 01, Q38

**Scheduled jobs**

- [ ] A user crontab with `crontab -e -u`, and the five time fields from memory — note 01, Q3
- [ ] A one-off job with `at`, listed with `atq` — note 01, Q3
- [ ] A systemd timer with `OnCalendar` and `Persistent`, plus its service unit — note 01, Q4
- [ ] Read `systemctl list-timers` to prove the next run — note 01, Q4

**Packages and repositories**

- [ ] Install a specific version and hold it: `apt-mark hold` or `dnf versionlock` — note 01, Q5
- [ ] Find which package owns a file, and list what a package installed — note 01, Q5
- [ ] Verify an installed package against its manifest — note 01, Q5
- [ ] Add a repository with a signing key — note 01, Q5

**Recovery**

- [ ] Change the default boot target, and boot once into rescue from GRUB — note 01, Q6
- [ ] Repair a filesystem with `fsck` or `xfs_repair`, unmounted — note 01, Q6
- [ ] Recover a machine that will not boot because of a bad `/etc/fstab` line — note 01, Q6
- [ ] Read the previous boot's errors with `journalctl -b -1 -p err` — note 01, Q11

**Virtual machines**

- [ ] Import an existing qcow2 disk as a VM with `virt-install --import` — note 01, Q7
- [ ] Set it to start at boot with `virsh autostart`, and prove it — note 01, Q7
- [ ] Read a VM's memory, vCPUs and disks with `virsh dominfo` and `domblklist` — note 01, Q7

**Containers**

- [ ] Run a container with a name, a published port, a memory limit and a restart policy — note 01, Q8
- [ ] Mount a host directory read-only into it — note 01, Q8
- [ ] Make a container start at boot with a generated systemd unit — note 01, Q8
- [ ] Inspect a running container with `podman inspect --format` — note 01, Q8

**SELinux**

- [ ] Read the current mode, and set it persistently in `/etc/selinux/config` — note 01, Q9
- [ ] Set a file context with `semanage fcontext` and apply it with `restorecon` — note 01, Q9
- [ ] Allow a service on a non-standard port with `semanage port` — note 01, Q9
- [ ] Flip a boolean persistently with `setsebool -P` — note 01, Q9
- [ ] Diagnose a denial with `ausearch -m avc -ts recent` — note 01, Q9

---

## Domain 2 — Networking (25%)

> Curriculum bullets: configure IPv4 and IPv6 networking and hostname resolution · set and synchronize system time using time servers · monitor and troubleshoot networking · configure the OpenSSH server and client · configure packet filtering, port redirection, and NAT · configure static routing · configure bridge and bonding devices · implement reverse proxies and load balancers

**Addressing and resolution**

- [ ] Give an interface a static address persistently, on both netplan and nmcli — note 02, Q12
- [ ] Set the hostname persistently with `hostnamectl` — note 02, Q14
- [ ] Configure DNS servers and a search domain, and prove it with `resolvectl` — note 02, Q14
- [ ] Add a host entry and prove resolution with `getent hosts` — note 02, Q14
- [ ] Configure an IPv6 address alongside IPv4 — note 02, Q12

**Time**

- [ ] Point chrony at a specific server and prove synchronisation with `chronyc sources` — note 02, Q15
- [ ] Set the timezone with `timedatectl` — note 02, Q15
- [ ] Serve time to a local network with `allow` — note 02, Q15

**Troubleshooting**

- [ ] Find what is listening with `ss -tulpn` and map it to a process — note 02, Q22
- [ ] Work out whether a failure is address, route, firewall, DNS or the service itself — note 02, Q22
- [ ] Watch traffic with `tcpdump` filtered to one port — note 02, Q22

**OpenSSH**

- [ ] Harden `sshd_config`: no root login, no password auth, a lower `MaxAuthTries` — note 02, Q16
- [ ] Add a `Match` block that makes an exception for one user — note 02, Q16
- [ ] Validate with `sshd -t` **before** restarting, and read effective settings with `sshd -T` — note 02, Q16
- [ ] Deploy a key and set the right permissions on `.ssh` and `authorized_keys` — note 02, Q16

**Packet filtering, redirection and NAT**

- [ ] Write an nftables ruleset that allows only what is asked — note 02, Q17
- [ ] Persist it, knowing where each distribution keeps it, and enable the service — note 02, Q17
- [ ] Do the same with `ufw` and with `firewalld --permanent` plus `--reload` — note 02, Q17
- [ ] **Never block 8080, 4505 or 4506** — note 02, Q17
- [ ] Redirect one port to another, and masquerade a subnet — note 02, Q18
- [ ] Enable IP forwarding persistently to make NAT work after a reboot — note 02, Q18

**Routing, bridges and bonds**

- [ ] Add a static route that survives a reboot — note 02, Q13
- [ ] Put an interface into a bridge and give the bridge the address — note 02, Q19
- [ ] Create a bond and read its state from `/proc/net/bonding/` — note 02, Q19

**Reverse proxies**

- [ ] Put nginx in front of an application on another port — note 02, Q20
- [ ] Balance across two backends with an `upstream` block — note 02, Q20
- [ ] Validate with `nginx -t`, and on RHEL set `httpd_can_network_connect` — note 02, Q20

---

## Domain 3 — Storage (20%)

> Curriculum bullets: configure and manage LVM storage · manage and configure the virtual file system · create, manage, and troubleshoot filesystems · use remote filesystems and network block devices · configure and manage swap space · configure filesystem automounters · monitor storage performance

- [ ] Partition a disk and make a filesystem on it — note 03 recipe 1, Q23
- [ ] Mount it persistently **by UUID**, with the options asked for — note 03 recipe 2, Q23
- [ ] Run `findmnt --verify` and `mount -a` before trusting an fstab edit — note 03 recipe 2, Q23
- [ ] Build a volume group with a stated extent size, and a logical volume — note 03 recipe 3, Q24
- [ ] Add a disk to a full volume group with `vgextend` — note 03 recipe 4, Q25
- [ ] **Extend a mounted logical volume and its filesystem with `lvextend -r`** — note 03 recipe 4, Q25
- [ ] Know that `resize2fs` takes a device and `xfs_growfs` takes a mount point — note 03 recipe 4, Q25
- [ ] Add a swap file at a stated priority, persistently — note 03 recipe 5, Q26
- [ ] Export a directory over NFS and mount it with `_netdev` — note 03 recipe 6, Q21
- [ ] Configure an automounter — note 03 recipe 6
- [ ] Attach a network block device, and clear a stale one — note 03 recipe 7, Q30
- [ ] Create a RAID 1 array that reassembles under the same name after a reboot — note 03 recipe 8, Q28
- [ ] Turn on user quotas and set a soft and hard limit — note 03 recipe 8, Q27
- [ ] Encrypt a volume with LUKS and unlock it at boot from a key file — note 03 recipe 9, Q29
- [ ] Diagnose a full filesystem, including inode exhaustion and deleted-but-open files — note 03 recipe 9, Q31
- [ ] Read storage performance with `iostat` and `vmstat` — note 03 recipe 9

---

## Domain 4 — Essential Commands (20%)

> Curriculum bullets: basic Git operations · create, configure, and troubleshoot services · monitor and troubleshoot system performance and services · determine application and service specific constraints · troubleshoot diskspace issues · work with SSL certificates

- [ ] Clone, branch, stage, commit and push — note 04, Q32
- [ ] Set `user.email` before the first commit, because it fails without one — note 04, Q32
- [ ] Write a `.gitignore` that actually excludes what is asked — note 04, Q32
- [ ] Create and troubleshoot a service, including a port conflict — note 04, Q38
- [ ] Read load, memory, CPU and process counts quickly — note 04, Q39
- [ ] Raise a service's file-descriptor limit with a drop-in — note 04, Q40
- [ ] Set a user's limits in `/etc/security/limits.d/` — note 04, Q44
- [ ] Diagnose a full filesystem — note 04, Q31
- [ ] Read a certificate's subject, issuer and expiry with `openssl x509` — note 04, Q33
- [ ] Generate a self-signed certificate and a CSR — note 04, Q33
- [ ] Match a private key to a certificate by modulus — note 04, Q33
- [ ] Inspect a live TLS endpoint with `openssl s_client` — note 04, Q33
- [ ] Find files by owner, size, permission and age, and act on them with `-exec` — note 04, Q34
- [ ] Set SUID, SGID and the sticky bit, and read them back from `ls -l` — note 04, Q34
- [ ] Build a report with `grep`, `sort`, `uniq -c`, `cut`, `awk` and `sed` — note 04, Q35
- [ ] Create and extract tar archives with compression and exclusions — note 04, Q36
- [ ] Create hard and symbolic links, and tell them apart — note 04, Q36
- [ ] Redirect stdout and stderr to different files in a script — note 04, Q37

---

## Domain 5 — Users and Groups (10%)

> Curriculum bullets: create and manage local user and group accounts · manage personal and system-wide environment profiles · configure user resource limits · configure and manage ACLs · configure the system to use LDAP user and group accounts

- [ ] Create a user with an exact UID, primary group, supplementary groups, shell, home and expiry — note 05, Q41
- [ ] Create a system account with no login shell — note 05, Q41
- [ ] Lock an account, and prove it from `passwd -S` — note 05, Q41
- [ ] Create a group with a specific GID and manage its membership — note 05, Q41
- [ ] Set password ageing with `chage`, and defaults in `/etc/login.defs` — note 05, Q42
- [ ] Grant sudo through a file in `/etc/sudoers.d/`, validated with `visudo -c` — note 05, Q42
- [ ] Grant a single NOPASSWD command to a group — note 05, Q42
- [ ] Prove a user's sudo rights with `sudo -l -U` — note 05, Q42
- [ ] Set an ACL for a user, and a default ACL on a directory — note 05, Q43
- [ ] Read ACLs with `getfacl -p` and understand the mask — note 05, Q43
- [ ] Set a system-wide environment variable in `/etc/profile.d/` — note 05, Q44
- [ ] Add to `/etc/skel` so future users inherit it — note 05, Q44
- [ ] Set per-user process and file limits — note 05, Q44
- [ ] Configure sssd so LDAP users resolve through `getent passwd` — note 05, Q45

---

## Cross-cutting: the two habits the exam grades

These are not curriculum bullets. They are what candidates actually fail on.

- [ ] **Persistence.** For every change above, I can state which file makes it survive a reboot, and I check it before leaving the task.
- [ ] **Host discipline.** I `ssh` to the host the task names, run `hostname` to confirm, and `exit` back to base before the next task.
- [ ] **No browser.** I can find any of the above in a man page in under thirty seconds using `man -k` and section 5.
- [ ] **Validation before restart.** `findmnt --verify`, `sshd -t`, `visudo -c`, `nginx -t`, `nft -c` are reflexes, not afterthoughts.

---

## Re-score log

| Date | `[x]` count | Weakest domain | Action |
|---|---|---|---|
| 10 Jan 2027 | | | |
| 24 Jan 2027 | | | |
| 31 Jan 2027 | | | |
