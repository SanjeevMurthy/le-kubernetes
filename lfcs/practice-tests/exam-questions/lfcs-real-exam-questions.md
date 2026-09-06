# LFCS Real Exam Task Types

What candidates actually report seeing, with a count of independent sources for each. This is the evidence layer of the kit: every "n sources" figure in the study notes traces back to a row here.

**Method.** Compiled on 6 September 2026 from 21 first-hand write-ups published between 2020 and 2026, plus the KodeKloud mock-exam community threads, the killer.sh simulator description, and several public practice repositories. Full detail and every URL: [`../../../docs/research/2026-09-06-lfcs-exam-research.md`](../../../docs/research/2026-09-06-lfcs-exam-research.md).

**What this is not.** These are task *types* reconstructed from what candidates remembered afterwards, not verbatim exam questions. The Linux Foundation certification agreement forbids sharing actual exam content, and nobody here has. Treat the phrasings as representative shapes, not quotations.

**Sources that could not be read.** Reddit blocked automated access entirely, so no Reddit threads inform this file. Udemy and O'Reilly course pages also blocked access, so their ratings come from search summaries only.

<!-- toc -->
## Table of Contents

- [Frequency tiers](#frequency-tiers)
- [Domain 1 — Operations Deployment (25%)](#domain-1--operations-deployment-25)
- [Domain 2 — Networking (25%)](#domain-2--networking-25)
- [Domain 3 — Storage (20%)](#domain-3--storage-20)
- [Domain 4 — Essential Commands (20%)](#domain-4--essential-commands-20)
- [Domain 5 — Users and Groups (10%)](#domain-5--users-and-groups-10)
- [What candidates were surprised by](#what-candidates-were-surprised-by)
- [How to use this file](#how-to-use-this-file)

<!-- toc stop -->

## Frequency tiers

| Tier | Threshold | Families |
|---|---|---|
| **1** | 4 or more independent sources | Packet filtering with persistence (7), LVM create and online extend (4), OpenSSL certificate work (4), containers with limits and restart policy (4) |
| **2** | 2 to 3 sources | NFS export and mount (3), libvirt from qcow2 (3), cron and timers (2), systemd units (2), sshd hardening (2), partition and fstab by UUID (2), web server and reverse proxy (2) |
| **3** | 1 source, or a curriculum bullet with mock-only evidence | users and groups, ACLs, special permissions, resource limits, swap, RAID, bridging, SELinux, static IP and routes, process and IO monitoring, scripting and redirection, find, links, archives, NBD, LDAP, disk-space triage, time synchronisation, quotas, LUKS |

**What this means in practice.** At 18 tasks, the exam draws heavily from tiers 1 and 2, but tier 3 is where the curriculum bullets live and any of them can appear. The one asymmetry worth acting on: **firewall work with persistence is reported roughly twice as often as anything else**, so it deserves twice the drilling.

---

## Domain 1 — Operations Deployment (25%)

| # | Task type | Sources | Phrasing as candidates remember it | Starting state | Gotchas | Drill |
|---|---|---|---|---|---|---|
| 1 | Containers with name, ports, volumes, memory limit and restart policy | **4** | "Run image X as container Y, publish a port, limit memory, restart on failure" | Engine installed; the image may need pulling | podman and docker CLI parity; rootless quirks; `--restart` needs the engine service enabled; `-m 256m` reads back as 268435456 | Q8 |
| 2 | Define a libvirt VM from an existing qcow2 | **3** | "Import the qcow2 at /path as VM X with N MB RAM; make it autostart" | Image provided; libvirtd may be stopped | `--import` with `--osinfo` or `--os-variant`; `virsh autostart`; no nested virtualisation in a lab VM, so `--virt-type qemu` | Q7 |
| 3 | Cron, at, and systemd timers, including for another user | **2** | "Schedule /usr/bin/x every day at 03:00 for user bob" | User exists, crontab empty | `crontab -u`; field order; `cron.allow`; a timer needs its matching `.service` and `enable --now` on the **timer** | Q3, Q4 |
| 4 | Write a unit, enable it, or diagnose one that fails | **2** | "Create a service that runs /opt/app at boot"; "Service X fails to start, fix it" | A broken unit, a missing file, or a masked unit | `daemon-reload`; `[Install] WantedBy=`; exit code 203 means not executable; masked units | Q10, Q11 |
| 5 | Kernel parameters, persistent and non-persistent | bullet | "Set net.ipv4.ip_forward now and after reboot" | Default value | `sysctl -w` is runtime only; the file goes in `/etc/sysctl.d/` then `sysctl --system` | Q1 |
| 6 | Packages and repositories: install, hold, verify | bullet, plus one candidate report of ambiguity about whether tools must be installed | "Install X at version N and prevent upgrades" | Repos configured | `apt-mark hold` versus `dnf versionlock`; `dpkg -V` and `rpm -V` print nothing when intact | Q5 |
| 7 | Recover from a boot, filesystem or hardware failure | bullet | "Set the default target"; "The machine will not boot, fix it" | A wrong target, or a bad fstab line | Edit `/etc/default/grub`, never `grub.cfg`; `fsck` only unmounted; `nofail` prevents the failure class entirely | Q6 |
| 8 | Process and IO monitoring, priorities and signals | **1** | "Find the process reading the most from disk and lower its priority" | A runaway process | `pidstat -d` needs sysstat installed and enabled; `renice` is runtime, `Nice=` in a unit persists | Q2 |
| 9 | SELinux contexts, ports and booleans | **1** | "Serve /srv/site on port 8081 with SELinux enforcing" | Enforcing, wrong labels | `semanage fcontext` then `restorecon`; `chcon` does not survive a relabel; `setsebool -P` | Q9 (Rocky) |

## Domain 2 — Networking (25%)

| # | Task type | Sources | Phrasing as candidates remember it | Starting state | Gotchas | Drill |
|---|---|---|---|---|---|---|
| 10 | **Packet filtering, port redirection and NAT, made persistent** | **7** | "Redirect incoming port 80 to 8080 and make it persistent"; "Allow or deny traffic from X and ensure the rules survive a reboot" | Often an empty ruleset; `iptables` may be the nft backend | **The single most reported family.** Persist per distribution; **never block 8080, 4505 or 4506**; do not lock out your own SSH; `-I` versus `-A`, `-t nat`, MASQUERADE, DNAT, REDIRECT | Q17, Q18 |
| 11 | sshd hardening, keys and Match blocks | **2** | "Allow password auth only for user X, disable root login, deploy a key for Y" | Default `sshd_config` | `sshd -t` **before** restarting; drop-ins in `sshd_config.d/`; a `Match` block must come last | Q16 |
| 12 | Web server, reverse proxy or load balancer | **2** | "Serve /var/www/x on port N"; "Proxy port 80 to a backend on 8080" | Package may need installing | SELinux booleans and `semanage port` on RHEL; the firewall; document root permissions | Q20 |
| 13 | Static addressing, routes, hostname and DNS | **1** | "Give eth1 10.0.0.5/24 and add a route to 172.16/16, persistently" | A DHCP interface | netplan versus nmcli; `netplan try` auto-reverts in 120 seconds; `systemd-resolved` means `/etc/resolv.conf` is a symlink | Q12, Q13, Q14 |
| 14 | Bridge and bonding devices | **1** | "Put eth1 into a bridge named br0" | A spare NIC | The address moves to the bridge; netplan `bridges:` versus `nmcli con add type bridge` | Q19 |
| 15 | Time synchronisation | mock reports; one candidate lists it as a KodeKloud gap | "Sync from time server X and set the timezone" | Default pool | `chrony` versus `chronyd` service name; `allow` is needed to serve time; `chronyc sources -v` proves it | Q15 |
| 16 | Network troubleshooting | mock reports | "The web app is unreachable, find and fix the cause" | A service bound to localhost, or a drop rule | `ss -tulpn` first; distinguish bind address, route, firewall, DNS and the service itself | Q22 |

## Domain 3 — Storage (20%)

| # | Task type | Sources | Phrasing as candidates remember it | Starting state | Gotchas | Drill |
|---|---|---|---|---|---|---|
| 17 | **LVM: create, and extend a mounted volume online** | **4** | "Extend /dev/vg/lv by 500 MB and grow the filesystem without unmounting"; "Create a VG from sdb and sdc, an LV of N GB, mount it persistently" | Spare disks; sometimes an LV already mounted | `lvextend -r`, or the volume grows and the filesystem does not; XFS cannot shrink; `-L` versus `-l`; forgetting `vgextend` when the group is full | Q24, Q25 |
| 18 | NFS export and persistent client mount | **3** | "Export /share read-only to network N; mount it on the client at /mnt persistently" | Server package may need installing; two hosts | `exportfs -ra`; `no_root_squash` is a real privilege grant; `_netdev` in the client fstab; the server firewall | Q21 |
| 19 | Partition, format, mount persistently by UUID | **2** | "Create a 1 GB partition on sdb, ext4, mounted at /data persistently" | A blank disk | `blkid` for the UUID; `mount -a` to test; a bad line makes the machine unbootable, so `findmnt --verify` first | Q23 |
| 20 | Swap space | **1** | "Add 512 MB of swap at priority 10, persistently" | Existing swap or none | `chmod 600` before `mkswap`; the priority goes in fstab as `pri=` | Q26 |
| 21 | RAID with mdadm | **1** | "Mirror sdb and sdc and mount the array" | Two spare disks | Without an `ARRAY` line and an initramfs rebuild it reassembles as `/dev/md127` and the fstab line fails | Q28 |
| 22 | Network block devices | mock reports | "Attach the NBD export from host X and mount it" | A peer serving the export | `modprobe nbd` first; a stale `/dev/nbd0` blocks reattachment until `nbd-client -d` | Q30 |
| 23 | Quotas | bullet | "Limit user X to a soft 50 MB and hard 100 MB on /quota" | Filesystem mounted without quota options | The `usrquota` mount option must come first, then `quotacheck`, `quotaon`, `setquota` | Q27 |
| 24 | Encrypted volumes | bullet | "Encrypt sdb1 and unlock it at boot without a passphrase" | A spare device | `/etc/crypttab` name becomes `/dev/mapper/<name>`, which is what fstab must use; the key file must be mode 600 | Q29 |
| 25 | Filesystem is full | **2** | "/data is at 98 percent, reclaim space and report the largest consumer" | Junk files, and a deleted file held open | `du -xh` to stay on one filesystem; `df -i` when space looks free; `lsof +L1` for deleted but open files | Q31 |

## Domain 4 — Essential Commands (20%)

| # | Task type | Sources | Phrasing as candidates remember it | Starting state | Gotchas | Drill |
|---|---|---|---|---|---|---|
| 26 | **SSL certificate work with openssl** | **4** | "Report the CN and expiry of /path/cert.pem"; "Create a self-signed certificate and serve HTTPS" | Certificate files provided | `openssl x509 -noout -subject -dates`; CSR versus certificate versus key; key file permissions | Q33 |
| 27 | Create, configure and troubleshoot a service | **2** | "Service X will not start because something else owns its port" | A port conflict, or a masked unit | `ss -tlpn` finds the owner; `disable --now` then `mask` | Q38 |
| 28 | Git basics | **1** | "Clone the repo, create a branch, add a .gitignore, commit and push" | A bare repo path | `git config user.email` before the first commit, or it fails outright | Q32 |
| 29 | find with filters and `-exec` | **1** | "Copy every file owned by X over 1 MB into /found, preserving permissions" | A directory tree | `-perm -4000` versus `/0002`; `-exec {} +` batches, `\;` does not; `cp -p` preserves | Q34 |
| 30 | Text processing pipelines | **1** | "Report the top five source addresses in the log" | A log file | The leading `sort` is required before `uniq -c`; `sed -i.bak` and read the output once first | Q35 |
| 31 | Archives and links | **1** each | "Archive the project excluding *.tmp"; "Create a symlink and a hard link" | A tree, an archive | Match the flag to the extension; identical inode numbers prove a hard link | Q36 |
| 32 | Redirection in a script | **1** | "Write a script sending stdout to one file and stderr to another" | An empty directory | `> out 2>&1` works and the reverse does not; the script needs a shebang and `+x` | Q37 |
| 33 | Performance monitoring | **1** | "Report load, cores, free memory and the busiest process" | A CPU hog running | `sysstat` must be enabled for `sar`; `top -bn1` for a scriptable snapshot | Q39 |
| 34 | Application and service constraints | bullet | "Raise the file-descriptor limit for service X" | A unit hitting its limit | `limits.conf` does not reach services; use a systemd drop-in and `daemon-reload` | Q40 |

## Domain 5 — Users and Groups (10%)

| # | Task type | Sources | Phrasing as candidates remember it | Starting state | Gotchas | Drill |
|---|---|---|---|---|---|---|
| 35 | User and group lifecycle with exact attributes | **1**, plus the official 2018 sample style | "Create user X with UID 2001, group Y, shell /bin/sh, home /home/x, expiring on DATE" | Group may not exist | `-m` or there is no home directory; `usermod -aG` appends and `-G` replaces; an account with no password cannot log in | Q41 |
| 36 | Password ageing and sudo | **1** | "Set password ageing for X; let group Y restart nginx without a password" | Defaults | `/etc/sudoers.d/` with mode 0440, `visudo -c`; a dot in the filename means the file is ignored; `sudo` group on Ubuntu, `wheel` on Rocky | Q42 |
| 37 | ACLs and special permissions | **1** | "Give X full access to /shared without changing its group; new files inherit read for Y" | A group directory | Default ACLs need `d:`; the mask caps named entries; a later `chmod` rewrites the mask; the only sign is a `+` in `ls -l` | Q43 |
| 38 | Environment profiles and skeleton | **1** | "Set EDITOR system-wide; make new users get a bin directory" | Defaults | `/etc/profile.d/` for shell syntax, `/etc/environment` for plain assignments; `/etc/skel` applies only to accounts created afterwards | Q44 |
| 39 | Resource limits | **1** | "Limit user X to N processes and N open files" | Defaults | `/etc/security/limits.d/`, applied by `pam_limits` at next login; `ulimit` alone never persists | Q44 |
| 40 | LDAP accounts | mock reports; one candidate lists it as a KodeKloud gap | "Make users from the LDAP directory resolve on this host" | A reachable directory | `sssd.conf` at mode 0600 or sssd refuses to start; `sss` in `nsswitch.conf`; `pam_mkhomedir` for home directories | Q45 |

---

## What candidates were surprised by

Drawn from the write-ups rather than the curriculum, because these are the things preparation usually misses.

- **One machine per task.** Several reports describe 17 questions across 17 machines. One candidate failed a first attempt partly by completing tasks on the wrong host.
- **No online manuals at all.** Coming from a Kubernetes exam this is the sharpest adjustment.
- **Single words in the prompt decide credit.** `ro` and `rw`, or a specific network mask, are graded literally.
- **Persistence is the quiet failure.** More candidates attribute a failure to a change that did not survive a reboot than to any knowledge gap.
- **The environment is slower than a local terminal.** One candidate booked a 2 AM slot and found the remote desktop sluggish.

## How to use this file

It sets the priority order of the practice question bank: the tier 1 families get the most questions and the most drilling. It is also where the "n sources" figures in the study notes come from, so if a number there looks wrong, this file and the research report behind it are the places to check. Re-verify it if the Linux Foundation revises the curriculum, which last happened in May 2023.
