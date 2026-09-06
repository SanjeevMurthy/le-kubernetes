# LFCS Kit Implementation Plan (Phases 3 to 5)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete LFCS preparation kit under `lfcs/` (lab guide and provisioning scripts, exam-environment note, five domain recipe notes plus a basics refresher, cheatsheets, Anki deck, real-exam compilation, dated plan, a 45-question practice CLI that runs as root inside the VMs, three scored mocks) and finish the repo with the combined roadmap, root README, and CLAUDE.md, all before study starts on 13 Dec 2026.

**Architecture:** `lfcs/` mirrors `cks/`. The practice CLI reuses the CKS harness (entrypoint, menu, progress, checks, generators) with an LFCS `lib/env.sh` that provides root and lab-marker guards, distro detection, loop-device disks, a network-namespace peer host, and file backup and restore. Questions are self-contained folders with `meta`, `question.md`, `solution.md`, `setup.sh`, `verify.sh`, `cleanup.sh`, verified by effect and by persistence. Two VirtualBox VMs (Ubuntu 24.04 primary, Rocky 9 secondary) are built from a guide and two provisioning scripts.

**Tech Stack:** bash 3.2-compatible menu code, bash 5 question scripts on Ubuntu 24.04 and Rocky 9 (arm64 guests under VirtualBox 7.2 on Apple Silicon, UTM as fallback), losetup, iproute2 network namespaces, systemd, LVM, mdadm, cryptsetup, nfs, nbd, podman, libvirt, chrony, nftables, ufw, firewalld, SELinux tooling, python3 for the doc checks.

**Spec:** `docs/superpowers/specs/2026-09-06-cks-lfcs-prep-design.md` (sections 2, 4, 5, 6, 7, 8, 9, 11, 12). Depends on the CKS plans being merged: this plan copies `cks/practice-cli/lib/{colors,checks,progress,menu}.sh`, `cks/practice-cli/cks`, and `cks/practice-cli/tools/{build-registry,build-guide,build-mock}.sh`.

## Global Constraints

- Branch `lfcs` created from `main` after the CKS part 2 PR is merged; commit after every task; PR at the end of Phase 4 and again after Phase 5.
- Every markdown file under `lfcs/` with H2 headings carries a `<!-- toc -->` block and passes `scripts/check-docs.sh`; at most one mermaid diagram per note, only for a flow.
- Notes are exam-task recipes in the format defined in `2026-09-06-cks-docs-plan.md` (Goal, Frequency, Commands, Verify, Gotchas, Docs), with `Docs` naming man pages (the exam allows no browser). Where Ubuntu and Rocky differ, Commands shows both in a two-column table.
- Exam facts must match spec §2: 17 to 20 tasks, 2 hours, 67%, `base` host plus `ssh <nodename>`, `sudo -i`, man pages and `/usr/share/doc` only, ports 8080, 4505, 4506 never blocked, distribution unspecified (Ubuntu primary, Rocky secondary).
- The CLI runs as root (auto `sudo -E`) and refuses hosts without `/etc/lfcs-lab` unless `LFCS_ALLOW_HOST=1`.
- Every question has at least one live-effect check and one persistence check where the task has a persistent component; verifiers use `getent`, `getfacl -p`, `lsblk -no`, `blkid -o value`, `lvs --noheadings`, `findmnt -no`, `findmnt --verify`, `swapon --show --noheadings`, `systemctl is-enabled`, `systemctl is-active`, `systemctl show -p`, `ss -H -ltn`, `nft -j list ruleset`, `sshd -T`, `ip -j`, `chage -l`, `sudo -l -U`, never a grep of human-formatted output when a machine-readable flag exists.
- Setups back up every file they modify with `backup_file`; cleanups restore, detach loop devices, delete namespaces.
- State lives in `/var/lib/lfcs`; deliverables under `/opt/course/<n>/`.
- Subagents: at most three in parallel, one file or one batch of five questions each, content returned inline; commit trailer `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01VDFGGfnXyAR8hsizcKsJzb`.

---

## File structure

```
lfcs/
├── README.md
├── lab-setup/
│   ├── README.md                 # VirtualBox on Apple Silicon: images, VM specs, disks, NICs, snapshots, ssh aliases, disk cleanup, UTM fallback
│   ├── vbox-create-vms.sh        # VBoxManage commands: host-only network, two VMs, spare disks, second NIC
│   ├── provision-ubuntu.sh       # run as root inside lfcs-ubuntu: packages, modules, marker, lfcs user, /opt/course
│   ├── provision-rocky.sh        # run as root inside lfcs-rocky
│   ├── ssh-config.example        # Host node1 / node2 entries for ~/.ssh/config on the Mac
│   └── kubeadm-single-node.sh    # optional: single-node kubeadm cluster in lfcs-ubuntu for CKS node-level practice
├── study-plan/                   # README.md, 00-calendar.md, 01-domain-checklists.md, 02-resources.md, 03-exam-day-playbook.md
├── study-notes/                  # README.md, 00-exam-environment.md, 01-operations-deployment.md, 02-networking.md,
│                                 # 03-storage.md, 04-essential-commands.md, 05-users-and-groups.md, 06-linux-basics-refresher.md
├── cheatsheets/                  # lfcs-exam-cheatsheet.md, man-page-navigation.md, lfcs-anki-deck.txt
├── practice-tests/exam-questions/lfcs-real-exam-questions.md
├── mock-exams/                   # README.md, mock-{1,2,3}.set, mock-{1,2,3}.md (generated)
└── practice-cli/
    ├── lfcs                      # copied from cks/practice-cli/cks with the edits in Phase 4 Task 2
    ├── README.md
    ├── lfcs-exam-qa-guide.md     # generated
    ├── lib/                      # colors.sh, checks.sh, progress.sh, menu.sh (copied and edited), env.sh (new), questions.sh (generated)
    ├── tools/                    # build-registry.sh, build-guide.sh, build-mock.sh (copied, paths edited)
    └── questions/qNN-<slug>/     # meta, question.md, solution.md, setup.sh, verify.sh, cleanup.sh
roadmap.md, README.md, CLAUDE.md  # Phase 5
```

### `meta` format

Same keys as the CKS CLI. `domain_short` values: `D1` Operations Deployment, `D2` Networking, `D3` Storage, `D4` Essential Commands, `D5` Users and Groups. `host` is `ubuntu`, `rocky`, or `any`. Needs tags: `disk` (a spare block device or loop support), `netns` (`ip netns` works), `host2` (`ssh node2 true` works), `nic2` (a second non-loopback, non-virtual NIC exists), `rocky`, `ubuntu`, `virt` (`virsh` present and `libvirtd` active), `tool:<name>`.

---

## Phase 3: lab, documents, plan (done by 15 Nov 2026)

### Task 1: Lab-setup guide and VM creation script

**Files:**
- Create: `lfcs/lab-setup/README.md`, `lfcs/lab-setup/vbox-create-vms.sh`, `lfcs/lab-setup/ssh-config.example`

- [ ] **Step 1: Write `README.md`** with sections:
  1. `## Disk space first`: target 50 GB free; `docker system prune -a`, `minikube delete -p cka-multinode`, `du -sh ~/Library/Containers/com.docker.docker`, `brew cleanup`.
  2. `## Install VirtualBox 7.2 on Apple Silicon`: `brew install --cask virtualbox`; note that only arm64 guests run; allow the kernel extension in System Settings; UTM fallback (`brew install --cask utm`) with the same images if a VM fails to boot.
  3. `## Images`: Ubuntu 24.04 LTS server arm64 ISO from `https://cdimage.ubuntu.com/releases/24.04/release/` and Rocky 9 aarch64 minimal ISO from `https://download.rockylinux.org/pub/rocky/9/isos/aarch64/`; verify the SHA256 with `shasum -a 256`.
  4. `## VM specs` table (from spec §6): `lfcs-ubuntu` 2 vCPU, 4096 MB, 25 GB root, three 2 GB spare disks, NAT plus host-only; `lfcs-rocky` 2 vCPU, 2048 MB, 12 GB root, two 2 GB spare disks, same NICs.
  5. `## Create the VMs`: run `bash vbox-create-vms.sh` (Step 2) then install each OS from the ISO with the GUI (user `lfcs`, OpenSSH server enabled on Ubuntu, minimal install on Rocky), static IPs on the host-only NIC `192.168.56.10` (ubuntu) and `192.168.56.20` (rocky) during install or via `provision-*.sh` later.
  6. `## Provision`: copy `provision-ubuntu.sh` in (`scp`), run `sudo bash provision-ubuntu.sh`; same for Rocky; the scripts print `LFCS lab marker written` at the end.
  7. `## Snapshots`: `VBoxManage snapshot lfcs-ubuntu take clean` after provisioning, `VBoxManage snapshot lfcs-ubuntu restore clean` before a mock.
  8. `## SSH aliases`: append `ssh-config.example` to `~/.ssh/config`, `ssh-copy-id node1`, `ssh node1` and `ssh node2` work; inside the VMs `ssh node2` also works (provision scripts add `/etc/hosts` entries and a key pair).
  9. `## Clone the kit inside the VM`: `git clone -b lfcs https://github.com/SanjeevMurthy/le-kubernetes ~/le-kubernetes && cd ~/le-kubernetes/lfcs/practice-cli && sudo ./lfcs`.
  10. `## Which questions run where` table filled from `./lfcs --list` after Phase 4 Task 12 (a note until then).
  11. `## Optional single-node kubeadm` pointer to `kubeadm-single-node.sh` (Task 2).

- [ ] **Step 2: Write `vbox-create-vms.sh`** (runs on the Mac; idempotent where VBoxManage allows)

```bash
#!/usr/bin/env bash
# Create the two LFCS VirtualBox VMs on Apple Silicon (arm64 guests). Attach ISOs afterwards in the GUI or with the lines at the end.
set -euo pipefail
VMDIR="${VMDIR:-$HOME/VirtualBox VMs}"
UBUNTU_ISO="${UBUNTU_ISO:-$HOME/Downloads/ubuntu-24.04.3-live-server-arm64.iso}"
ROCKY_ISO="${ROCKY_ISO:-$HOME/Downloads/Rocky-9-latest-aarch64-minimal.iso}"

VBoxManage list hostonlynets | grep -q '^Name: *lfcsnet$' || \
  VBoxManage hostonlynet add --name lfcsnet --netmask 255.255.255.0 --lower-ip 192.168.56.100 --upper-ip 192.168.56.200 --enable

create_vm() {  # name ostype memory_mb disk_gb spare_count
  local name="$1" ostype="$2" mem="$3" disk="$4" spares="$5" i
  if VBoxManage showvminfo "$name" >/dev/null 2>&1; then echo "$name exists, skipping create"; return; fi
  VBoxManage createvm --name "$name" --ostype "$ostype" --register --platform-architecture arm
  VBoxManage modifyvm "$name" --cpus 2 --memory "$mem" --nic1 nat --nic2 hostonlynet --host-only-net2 lfcsnet --boot1 dvd --boot2 disk
  VBoxManage storagectl "$name" --name "SCSI" --add virtio-scsi --controller VirtIO --bootable on
  VBoxManage createmedium disk --filename "$VMDIR/$name/$name.vdi" --size $((disk * 1024)) >/dev/null
  VBoxManage storageattach "$name" --storagectl SCSI --port 0 --device 0 --type hdd --medium "$VMDIR/$name/$name.vdi"
  for i in $(seq 1 "$spares"); do
    VBoxManage createmedium disk --filename "$VMDIR/$name/$name-spare$i.vdi" --size 2048 >/dev/null
    VBoxManage storageattach "$name" --storagectl SCSI --port "$i" --device 0 --type hdd --medium "$VMDIR/$name/$name-spare$i.vdi"
  done
  echo "created $name"
}
create_vm lfcs-ubuntu Ubuntu_arm64 4096 25 3
create_vm lfcs-rocky  RedHat_arm64 2048 12 2

# Attach install media (rerun after downloading the ISOs):
VBoxManage storageattach lfcs-ubuntu --storagectl SCSI --port 9 --device 0 --type dvddrive --medium "$UBUNTU_ISO" 2>/dev/null || echo "attach Ubuntu ISO manually: $UBUNTU_ISO"
VBoxManage storageattach lfcs-rocky  --storagectl SCSI --port 9 --device 0 --type dvddrive --medium "$ROCKY_ISO"  2>/dev/null || echo "attach Rocky ISO manually: $ROCKY_ISO"
echo "Next: start each VM, install the OS, then run the provision script inside it."
```
  Note in the README that `--platform-architecture arm` and `Ubuntu_arm64` / `RedHat_arm64` are the VirtualBox 7.1+ names; if `VBoxManage list ostypes | grep arm64` shows different ids, use those.

- [ ] **Step 3: Write `ssh-config.example`**

```
Host node1
  HostName 192.168.56.10
  User lfcs
  StrictHostKeyChecking no
Host node2
  HostName 192.168.56.20
  User lfcs
  StrictHostKeyChecking no
```

- [ ] **Step 4: Verify** `bash -n lfcs/lab-setup/vbox-create-vms.sh && python3 scripts/generate_toc.py --inject lfcs/lab-setup/README.md && bash scripts/check-docs.sh lfcs/lab-setup` → `ALL OK`.
- [ ] **Step 5: Commit** `docs(lfcs): lab-setup guide, VM creation script, ssh aliases`.

### Task 2: Provisioning scripts

**Files:**
- Create: `lfcs/lab-setup/provision-ubuntu.sh`, `lfcs/lab-setup/provision-rocky.sh`, `lfcs/lab-setup/kubeadm-single-node.sh`

- [ ] **Step 1: Write `provision-ubuntu.sh`**

```bash
#!/usr/bin/env bash
# Provision lfcs-ubuntu (Ubuntu 24.04) for the LFCS practice CLI. Run as root.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root"; exit 1; }
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q \
  lvm2 mdadm cryptsetup xfsprogs parted gdisk quota acl attr tree \
  nfs-kernel-server nfs-common autofs nbd-client nbd-server \
  podman qemu-system-arm qemu-utils libvirt-daemon-system libvirt-clients virtinst \
  chrony git openssl sysstat nftables iptables ufw \
  sssd-ldap ldap-utils bridge-utils tcpdump traceroute nmap-ncat curl wget vim jq \
  python3 at cron bash-completion
systemctl enable --now chrony atd cron libvirtd nftables 2>/dev/null || true
systemctl enable --now sysstat 2>/dev/null || true
modprobe loop nbd 2>/dev/null || true
printf 'loop\nnbd\n' > /etc/modules-load.d/lfcs.conf
usermod -aG libvirt,kvm lfcs 2>/dev/null || true
mkdir -p /opt/course /var/lib/lfcs
grep -q 'node2' /etc/hosts || printf '192.168.56.10 node1 node1.lab.local\n192.168.56.20 node2 node2.lab.local\n' >> /etc/hosts
[[ -f /root/.ssh/id_ed25519 ]] || ssh-keygen -q -t ed25519 -N '' -f /root/.ssh/id_ed25519
echo "ubuntu $(date -Is)" > /etc/lfcs-lab
echo "LFCS lab marker written: /etc/lfcs-lab. Copy /root/.ssh/id_ed25519.pub into node2's /root/.ssh/authorized_keys for two-host tasks."
```

- [ ] **Step 2: Write `provision-rocky.sh`**

```bash
#!/usr/bin/env bash
# Provision lfcs-rocky (Rocky 9) for the LFCS practice CLI. Run as root.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root"; exit 1; }
dnf install -y -q epel-release
dnf install -y -q \
  lvm2 mdadm cryptsetup xfsprogs parted gdisk quota acl attr tree \
  nfs-utils autofs nbd \
  podman qemu-kvm libvirt virt-install \
  chrony git openssl sysstat nftables iptables-nft firewalld \
  policycoreutils-python-utils setools-console setroubleshoot-server \
  sssd-ldap openldap-clients tcpdump traceroute nmap-ncat curl wget vim jq \
  python3 at cronie bash-completion
systemctl enable --now chronyd atd crond libvirtd firewalld 2>/dev/null || true
modprobe loop nbd 2>/dev/null || true
printf 'loop\nnbd\n' > /etc/modules-load.d/lfcs.conf
usermod -aG libvirt lfcs 2>/dev/null || true
mkdir -p /opt/course /var/lib/lfcs
grep -q 'node1' /etc/hosts || printf '192.168.56.10 node1 node1.lab.local\n192.168.56.20 node2 node2.lab.local\n' >> /etc/hosts
[[ -f /root/.ssh/id_ed25519 ]] || ssh-keygen -q -t ed25519 -N '' -f /root/.ssh/id_ed25519
getenforce
echo "rocky $(date -Is)" > /etc/lfcs-lab
echo "LFCS lab marker written: /etc/lfcs-lab (SELinux must be Enforcing for the SELinux questions)."
```

- [ ] **Step 3: Write `kubeadm-single-node.sh`** (optional CKS tier for the Ubuntu VM): install containerd with `SystemdCgroup = true`, the Kubernetes apt repo for v1.35 (`pkgs.k8s.io/core:/stable:/v1.35/deb/`), `kubeadm init --pod-network-cidr=192.168.0.0/16`, Calico manifest, `kubectl taint nodes --all node-role.kubernetes.io/control-plane-`, copy the kubeconfig to `/root/.kube/config` and `/home/lfcs/.kube/config`; print `kubectl get nodes`. Needs 4 GB RAM; the README says to raise the VM to 6 GB for it.

- [ ] **Step 4: Verify** `bash -n lfcs/lab-setup/*.sh && echo ok` and `bash scripts/check-docs.sh lfcs/lab-setup` → `ALL OK`.
- [ ] **Step 5: Commit** `feat(lfcs): provisioning scripts for Ubuntu and Rocky VMs, optional kubeadm`.

### Task 3: Note 00-exam-environment.md

**Files:**
- Create: `lfcs/study-notes/00-exam-environment.md`

- [ ] **Step 1: Write the note** from spec §2 and `docs/research/2026-09-06-lfcs-exam-research.md` §1: facts table (17 to 20 tasks, 2 h, 67%, one retake within 12 months, valid 2 years, price, two killer.sh sessions with the same 20 questions); the remote desktop (PSI Bridge, single monitor, VSCodium, terminal, notepad, timer alerts, INSERT disabled, `Ctrl+Alt+W`, `Ctrl+Shift+C/V`); hosts (`base` never rebooted, `ssh <nodename>`, no nested ssh, `sudo -i`, tools present on hosts: vim nano emacs git sudo); allowed resources (man pages, `/usr/share/doc`, installable distro packages) and explicitly nothing else; the three ports never to block; the distribution question (unspecified; Ubuntu likely; SELinux bullet means RHEL-family skills too) with a two-column "if the host is Debian-family / RHEL-family" quick map (apt/dnf, netplan/nmcli, ufw/firewalld, AppArmor/SELinux, `nfs-kernel-server`/`nfs-utils`); `## First two minutes on a task host` block (`sudo -i`, `hostname`, `cat /etc/os-release`, `man -k`, `set -o vi` optional, `alias ll='ls -al'`); `## Verification habit` (re-read the task, check with the machine-readable command, check persistence, `exit` to base); `## Memorise`.
- [ ] **Step 2: Verify and commit** `docs(lfcs): add 00-exam-environment note`.

### Task 4: Note 01-operations-deployment.md (11 recipes)

**Files:**
- Create: `lfcs/study-notes/01-operations-deployment.md`

- [ ] **Step 1: Write the recipes** (curriculum bullets from spec §2 in brackets; research §3 for frequency):
  1. Kernel parameters, non-persistent and persistent [bullet 1]: `sysctl -w`, `/etc/sysctl.d/90-lab.conf`, `sysctl --system`, `sysctl -n`. Drill Q1.
  2. Processes: `ps -eo pid,ni,pcpu,comm --sort=-pcpu`, `top`, `pidstat -d 1`, `nice`, `renice -n 15 -p`, signals (`kill -TERM`, `-KILL`, `-HUP`), `pgrep`, `/proc/PID/status`. Drill Q2, Q39.
  3. Scheduled jobs [bullet 3]: `crontab -e -u user`, five-field syntax, `/etc/cron.d`, `cron.allow`, `at now + 2 hours`, `atq`, `atrm`, systemd timers (`OnCalendar=*:0/15`, `Persistent=true`, `systemctl list-timers`). Drill Q3, Q4.
  4. Packages and repositories [bullet 4]: apt (`apt-cache policy`, `apt-get install pkg=version`, `apt-mark hold`, `dpkg -L`, `dpkg -S`, `dpkg -V`, adding a repo with a signed-by key) and dnf (`dnf repolist`, `dnf install`, `dnf provides`, `rpm -ql`, `rpm -V`, `dnf config-manager --add-repo`, `dnf history`). Drill Q5.
  5. Recover from failures [bullet 5]: GRUB edit (`e`, `systemd.unit=rescue.target`, `rd.break` on RHEL, `init=/bin/bash`), `systemctl set-default`, `fsck -y` on an unmounted filesystem, `xfs_repair`, fixing a bad `/etc/fstab` line (`nofail`, comment it, `mount -a`), `journalctl -b -1 -p err`, `systemd-analyze blame`. Drill Q6, Q11.
  6. Virtual machines with libvirt [bullet 6]: `virsh list --all`, `virsh define`, `virt-install --import --name --memory --vcpus --disk --os-variant generic --virt-type qemu --noautoconsole`, `virsh autostart`, `virsh start`, `virsh dominfo`, `virsh dumpxml`, `qemu-img create/convert`. Drill Q7.
  7. Containers [bullet 7]: `podman run -d --name web -p 8080:80 -m 256m --restart=always -v /srv/web:/usr/share/nginx/html:ro,Z nginx:1.27`, `podman ps`, `logs`, `exec`, `inspect --format`, `podman generate systemd --new --name web`, quadlets, rootless notes, `docker` equivalence. Drill Q8.
  8. SELinux [bullet 8]: `getenforce`, `setenforce`, `/etc/selinux/config`, `ls -Z`, `ps -Z`, `semanage fcontext -a -t httpd_sys_content_t "/srv/site(/.*)?"`, `restorecon -Rv`, `semanage port -a -t http_port_t -p tcp 8081`, `setsebool -P`, `ausearch -m avc -ts recent`, `sealert`. Drill Q9.
  9. systemd units [bullets 2 and Essential 2]: unit sections, `Type`, `ExecStart`, `Restart`, `User`, `WantedBy`, `systemctl daemon-reload`, `enable --now`, `mask`, drop-ins (`systemctl edit`), `systemctl show -p`, `journalctl -u -b`. Drill Q10, Q11, Q38, Q40.
  10. Logging: `journalctl` filters (`-u`, `-p`, `--since`, `-b`, `-f`, `-o json`), persistent journal (`Storage=persistent`, `/var/log/journal`), `journalctl --vacuum-size`, rsyslog files, `logrotate` config and `-d`. Drill Q11.
  11. Kernel modules: `lsmod`, `modinfo`, `modprobe`, `modprobe -r`, `/etc/modules-load.d`, `/etc/modprobe.d/blacklist`. Drill Q42 of the CKS kit and the Memorise list.
- [ ] **Step 2: `## What the exam asks`** table (containers 4, libvirt 3, cron and timers 2, systemd units 2, packages 0 reports but a bullet, SELinux 1, sysctl 0 but a bullet).
- [ ] **Step 3: One mermaid diagram** (`flowchart TD`) of the boot chain: firmware, GRUB, kernel and initramfs, systemd default target, units. Quick reference and Memorise.
- [ ] **Step 4: Verify (11 recipes) and commit** `docs(lfcs): add 01-operations-deployment recipes`.

### Task 5: Note 02-networking.md (11 recipes)

- [ ] **Step 1: Write the recipes**: 1. IPv4 and IPv6 addressing with netplan (`/etc/netplan/*.yaml`, `netplan try`, `netplan apply`) and nmcli (`nmcli con mod eth1 ipv4.addresses … ipv4.method manual`, `con up`) side by side, `ip -br a`, `ip -j` [bullet 1]. Drill Q12. 2. Hostname and resolution: `hostnamectl set-hostname`, `/etc/hosts`, `resolvectl`, `/etc/systemd/resolved.conf`, netplan `nameservers`, nmcli `ipv4.dns`, `getent hosts`, `dig`, `nslookup`. Drill Q14. 3. Time sync [bullet 2]: `timedatectl set-timezone`, `chrony.conf` `server … iburst`, `allow`, `chronyc sources -v`, `chronyc tracking`, `makestep`. Drill Q15. 4. Troubleshooting [bullet 3]: `ip link`, `ss -tulpn`, `ping`, `tracepath`, `nc -zv`, `tcpdump -i any port 80`, `ethtool`, `/etc/nsswitch.conf`, reading `journalctl -u NetworkManager`. Drill Q22. 5. OpenSSH [bullet 4]: `sshd_config` keys (`PermitRootLogin`, `PasswordAuthentication`, `MaxAuthTries`, `AllowUsers`, `Match User`), `sshd -t`, `sshd -T -C user=`, `ssh-keygen`, `ssh-copy-id`, `authorized_keys` perms, `ssh_config` `Host` blocks, `-L`/`-R` forwarding, agent. Drill Q16. 6. Packet filtering [bullet 5]: nftables table and chain syntax, `nft add rule inet filter input tcp dport {22,80,443} accept`, default drop, `nft list ruleset`, persistence (`/etc/nftables.conf` and `systemctl enable nftables` on Ubuntu, `/etc/sysconfig/nftables.conf` on Rocky), ufw (`allow`, `deny`, `status numbered`, `enable`), firewalld (`--add-service`, `--add-port`, `--permanent`, `--reload`, zones), iptables equivalents and `iptables-save`. Drill Q17. 7. Port redirection and NAT [bullet 5]: `nft add rule ip nat prerouting tcp dport 8081 redirect to :8080`, `masquerade`, `dnat to`, `iptables -t nat -A PREROUTING … -j REDIRECT --to-port`, `net.ipv4.ip_forward`, firewalld `--add-forward-port`, `--add-masquerade`. Drill Q18. 8. Static routing [bullet 6]: `ip route add 10.200.0.0/16 via 192.168.56.1 dev eth1`, netplan `routes:`, nmcli `ipv4.routes`, `ip -j route`. Drill Q13. 9. Bridge and bonding [bullet 7]: netplan `bridges:` and `bonds:` (mode active-backup), nmcli `con add type bridge`, `bridge-slave`, `bond`, `bridge link`, `cat /proc/net/bonding/bond0`. Drill Q19. 10. Reverse proxies and load balancers [bullet 8]: nginx `server { listen 80; location / { proxy_pass http://127.0.0.1:9000; proxy_set_header Host $host; } }`, `upstream` with two servers, haproxy `frontend`/`backend` minimal config, `nginx -t`, SELinux `httpd_can_network_connect`. Drill Q20. 11. NFS and remote filesystems (client side of Storage bullet 4 lives here for networking context): `showmount -e`, `mount -t nfs`, `_netdev`, firewall ports 2049 and 111. Drill Q21.
- [ ] **Step 2: `## What the exam asks`** (iptables and nftables 7, sshd 2, static IP 1, bridge 1, reverse proxy 2, time sync 0 but a bullet, NFS 3). One mermaid diagram (`flowchart LR`) of the netfilter hooks prerouting, input, forward, output, postrouting with nat and filter chains. Quick reference, Ubuntu versus Rocky table, Memorise.
- [ ] **Step 3: Verify (11 recipes) and commit** `docs(lfcs): add 02-networking recipes`.

### Task 6: Note 03-storage.md (9 recipes)

- [ ] **Step 1: Write the recipes**: 1. Partitions: `lsblk -f`, `parted /dev/sdb mklabel gpt mkpart primary ext4 1MiB 1GiB`, `fdisk`, `gdisk`, `partprobe`, `wipefs -a`. Drill Q23. 2. Filesystems and quotas [bullet 3]: `mkfs.ext4 -L data`, `mkfs.xfs`, `tune2fs -l`, `xfs_admin -L`, `fsck`, `xfs_repair`, `resize2fs`, `xfs_growfs`, `usrquota` mount option, `quotacheck -cug`, `quotaon`, `edquota`, `setquota`, `repquota`. Drill Q23, Q27. 3. Mounting and the virtual filesystem [bullet 2]: `mount -o noatime`, `/etc/fstab` by `UUID=` (`blkid`), `findmnt --verify`, `mount -a`, `systemd-mount` units, `/proc`, `/sys`, `tmpfs`, bind mounts. Drill Q23. 4. LVM [bullet 1]: `pvcreate`, `vgcreate -s 16M`, `lvcreate -L 1.5G -n`, `lvextend -r -L +400M`, `vgextend`, `lvreduce` warnings, `lvs -o+devices`, snapshots. Drill Q24, Q25. 5. Swap [bullet 5]: `fallocate -l 512M /swapfile2`, `chmod 600`, `mkswap`, `swapon -p 10`, fstab `pri=10`, `swapon --show`. Drill Q26. 6. Remote filesystems and network block devices [bullet 4]: NFS server (`/etc/exports`, `exportfs -ra`, `no_root_squash`), client mount, `autofs` (`auto.master`, indirect map, `--timeout`), NBD (`nbd-server` config, `nbd-client host 10809 /dev/nbd0`, `nbd-client -d`). Drill Q21, Q30. 7. RAID with mdadm: `mdadm --create /dev/md0 --level=1 --raid-devices=2`, `mdadm --detail`, `mdadm --detail --scan >> mdadm.conf`, `update-initramfs -u` or `dracut -f`. Drill Q28. 8. LUKS: `cryptsetup luksFormat`, `luksOpen`, `luksAddKey`, `/etc/crypttab` with a key file, `cryptsetup status`. Drill Q29. 9. Storage performance and disk-space troubleshooting [bullet 7, Essential 5]: `iostat -xz 1`, `iotop`, `vmstat 1`, `df -hT`, `df -i`, `du -xh --max-depth=1 / | sort -h`, `find / -xdev -size +100M`, `lsof +L1`, `journalctl --vacuum-size`. Drill Q31.
- [ ] **Step 2: `## What the exam asks`** (LVM 4, partition and fstab 2, NFS 3, swap 1, RAID 1, NBD 0 reports but KodeKloud mock, LUKS 0). One mermaid diagram (`flowchart TD`) of the LVM stack disk, partition, PV, VG, LV, filesystem, mount. Quick reference and Memorise.
- [ ] **Step 3: Verify (9 recipes) and commit** `docs(lfcs): add 03-storage recipes`.

### Task 7: Note 04-essential-commands.md (9 recipes)

- [ ] **Step 1: Write the recipes**: 1. Git basics [bullet 1]: `git clone`, `checkout -b`, `add`, `commit -m`, `config user.name`, `.gitignore`, `push -u origin`, `log --oneline`, `status`, `diff`, `stash`. Drill Q32. 2. Services [bullet 2]: create, enable, troubleshoot (port conflicts with `ss -tlpn`, `journalctl -u`, `systemctl status`, `SYSTEMD_LOG_LEVEL`), cross-reference 01 recipe 9. Drill Q38. 3. Performance monitoring [bullet 3]: `uptime`, `top -o %CPU`, `ps --sort`, `vmstat`, `free -m`, `nproc`, `sar`, `/proc/loadavg`. Drill Q39. 4. Application and service constraints [bullet 4]: `systemctl show -p LimitNOFILE`, drop-in `LimitNOFILE=`, `TasksMax=`, `MemoryMax=`, `CPUQuota=`, `ulimit -n`, `cat /proc/PID/limits`. Drill Q40. 5. Disk-space troubleshooting [bullet 5]: cross-reference 03 recipe 9 with the exam phrasing. Drill Q31. 6. SSL certificates [bullet 6]: `openssl x509 -in cert -noout -subject -enddate -issuer`, `openssl req -x509 -newkey rsa:2048 -nodes -keyout -out -days 365 -subj`, CSR generation, `openssl verify -CAfile`, `openssl s_client -connect host:443 -servername`, modulus match, key permissions. Drill Q33. 7. Text processing: `grep -E -c -o -v`, `sed -i 's,http://,https://,g'`, `awk -F, '{print $3}'`, `sort | uniq -c | sort -rn | head -5`, `cut`, `tr`, `wc`, `xargs`, `tee`. Drill Q35. 8. find and permissions: `find -user -size +1M -mtime -7 -perm -4000 -exec cp -p {} dir \;`, `chmod 3775`, `chown -R user:group`, `umask`, SUID, SGID, sticky, `stat -c '%A %U:%G'`. Drill Q34. 9. Archives, links, redirection: `tar czf --exclude='*.tmp'`, `tar xJf`, `tar -tzf`, `gzip`, `xz`, `zip`, `ln -s`, `ln`, `stat -c %i`, `>`, `>>`, `2>`, `2>&1`, `&>`, `|`, here-docs, `set -e`, `#!/bin/bash`. Drill Q36, Q37.
- [ ] **Step 2: `## What the exam asks`** (OpenSSL 4, git 1, find 1, links 1, archives 1, redirection 1, systemd troubleshooting 2). No diagram. Quick reference and Memorise.
- [ ] **Step 3: Verify (9 recipes) and commit** `docs(lfcs): add 04-essential-commands recipes`.

### Task 8: Note 05-users-and-groups.md (5 recipes) and 06-linux-basics-refresher.md

- [ ] **Step 1: Write 05** recipes: 1. Local users and groups [bullet 1]: `useradd -u 2001 -g devs -G wheel -s /bin/bash -m -c 'Ana' -e 2027-06-30 ana`, `usermod -aG`, `-L`, `-U`, `-s`, `userdel -r`, `groupadd -g 3001`, `gpasswd -a/-d`, `chage -l/-E/-M/-m/-W`, `passwd -S`, `/etc/passwd`, `/etc/shadow`, `/etc/group`, `/etc/login.defs`, system users (`-r`), `pwquality.conf`. Drill Q41, Q42. 2. Environment profiles [bullet 2]: `/etc/profile`, `/etc/profile.d/*.sh`, `/etc/bash.bashrc` or `/etc/bashrc`, `~/.bashrc`, `~/.profile`, `/etc/environment`, `/etc/skel`, `export`, `PATH`. Drill Q44. 3. Resource limits [bullet 3]: `/etc/security/limits.conf`, `limits.d`, soft versus hard, `nproc`, `nofile`, `ulimit -Hu`, `pam_limits`, systemd `DefaultLimitNOFILE`. Drill Q44. 4. ACLs [bullet 4]: `setfacl -m u:ana:rwx`, `-m d:g:qa:r-x`, `-x`, `-b`, `getfacl -p`, mask, SGID directories, `chmod g+s`. Drill Q43. 5. LDAP accounts [bullet 5]: `sssd.conf` (`id_provider = ldap`, `ldap_uri`, `ldap_search_base`, `ldap_tls_reqcert`), `nsswitch.conf` `sss`, `pam_mkhomedir` (`authselect` on Rocky, `pam-auth-update` on Ubuntu), `getent passwd user`, `ldapsearch -x -H ldap://host -b`. Drill Q45. Plus sudo as recipe 1b: `visudo`, `/etc/sudoers.d/`, `%ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx`, `sudo -l -U`, `visudo -c`. Drill Q42.
- [ ] **Step 2: Write 06** (no recipes): navigation and globbing, `man` sections and `man -k`, `--help | less`, vim survival keys, permissions table, process basics, redirection table, the ten commands every task uses, links to le-linux for depth (`https://github.com/SanjeevMurthy/le-linux/blob/main/linux-notes/...`).
- [ ] **Step 3: Verify (05 has 6 recipes counting sudo) and commit** `docs(lfcs): add 05-users-and-groups recipes and 06 basics refresher`.

### Task 9: Study-notes README, cheatsheets, Anki, real-exam compilation

**Files:**
- Create: `lfcs/study-notes/README.md`, `lfcs/cheatsheets/lfcs-exam-cheatsheet.md`, `lfcs/cheatsheets/man-page-navigation.md`, `lfcs/cheatsheets/lfcs-anki-deck.txt`, `lfcs/practice-tests/exam-questions/lfcs-real-exam-questions.md`

- [ ] **Step 1: README**: table of the seven notes with weight, recipe count, drill Q ids; reading order (04 and 06 first for muscle memory, then 05, 01, 03, 02).
- [ ] **Step 2: `lfcs-exam-cheatsheet.md`**: first two minutes; per-domain command lists (every command that appears in a Memorise section); the persistence table (what file makes each change survive a reboot on Ubuntu and on Rocky: sysctl, hostname, IP, routes, DNS, firewall, mounts, swap, crypttab, mdadm, units, timers, crontab, limits, profiles); the verification one-liner per task family; the exam rules (ports, base, nested ssh).
- [ ] **Step 3: `man-page-navigation.md`**: `man -k keyword`, `apropos`, `man 5 fstab` sections, `/pattern`, `n`, `SEE ALSO`, `--help | grep`, `/usr/share/doc/<pkg>/examples`, `info`, `bash` builtins with `help`, a table of "task to man page" (fstab, crontab(5), sshd_config(5), nft(8), sudoers(5), systemd.unit(5), systemd.timer(5), lvm(8), mdadm(8), cryptsetup(8), exports(5), netplan(5), nmcli(1), semanage-fcontext(8), setfacl(1), chage(1), login.defs(5), limits.conf(5), sssd.conf(5), openssl-x509(1), tar(1), find(1)).
- [ ] **Step 4: Anki deck** in the tab format with deck `LFCS`, about 120 cards from the Memorise sections, tags `lfcs::files`, `lfcs::commands`, `lfcs::flags`, `lfcs::traps`; row check as in the CKS plan.
- [ ] **Step 5: Real-exam compilation** from `docs/research/2026-09-06-lfcs-exam-research.md` §2 and §3: per domain a table (task type, frequency with source count, phrasing, starting state, gotchas, drill Q ids) for all 35 rows of the research table; frequency tiers; the 21 candidate sources with dates and URLs; "environment facts that surprised candidates" (17 machines, no online docs, wrong host, persistence).
- [ ] **Step 6: Verify** `bash scripts/check-docs.sh lfcs`, the Anki row check, and `grep -c '^| [0-9]' lfcs/practice-tests/exam-questions/lfcs-real-exam-questions.md` at least 35.
- [ ] **Step 7: Commit** `docs(lfcs): notes README, cheatsheets, Anki deck, real-exam compilation`.

### Task 10: Study plan (dated) and LFCS README

**Files:**
- Create: `lfcs/study-plan/README.md`, `00-calendar.md`, `01-domain-checklists.md`, `02-resources.md`, `03-exam-day-playbook.md`, `lfcs/README.md`

- [ ] **Step 1: `00-calendar.md`** with checkboxes:

| Dates | Focus | Content |
|---|---|---|
| Before 13 Dec | Setup | free 50 GB, install VirtualBox, download both ISOs, book the exam for Sat 6 Feb 2027, KodeKloud LFCS enrolment, Anki import |
| Sun 13 Dec | Lab build | both VMs, provision scripts, snapshots, ssh aliases, `./lfcs --env` on both; note 00 |
| 14 to 20 Dec | Essential Commands and Users | notes 04, 06, 05; Q32 to Q37, Q41 to Q44; KodeKloud Essential Commands and Users sections |
| 21 to 27 Dec | Operations Deployment | note 01; Q1 to Q8, Q10, Q11; Q9 on Rocky; KodeKloud Operations section |
| 28 Dec to 3 Jan | Storage | note 03; Q23 to Q31; KodeKloud Storage section |
| 4 to 10 Jan | Networking | note 02; Q12 to Q22; KodeKloud Networking section; repo mock 1 on Sun 10 Jan as baseline |
| 11 to 17 Jan | Drills 1 | every question timed and interleaved; KodeKloud mocks 1 and 2; repo mock 2 on Sat 16 Jan |
| 18 to 24 Jan | Drills 2 | weak areas, Rocky flavour, two-host tasks (Q21, Q30, Q45); killer.sh session 1 on Sat 23 Jan |
| 25 to 31 Jan | Drills 3 | gap review from session 1; KodeKloud mocks 3 and 4; repo mock 3 on Sun 31 Jan |
| 1 to 6 Feb | Exam week | weak-area drills; killer.sh session 2 on Wed 3 Feb; light review; exam Sat 6 Feb |

  Per entry: KodeKloud lessons, note recipes to type out, questions with the VM to use, Anki cards, Sunday close-out line.
- [ ] **Step 2: `README.md`** (parameters: start 13 Dec, exam 6 Feb, hours, KodeKloud, killer.sh, the two VMs; phases; principles; how to use), **`01-domain-checklists.md`** (all 34 curriculum bullets plus the implicit basics, `[ ]/[~]/[x]`, drill Q ids, re-score dates 10 Jan, 24 Jan, 31 Jan), **`02-resources.md`** (KodeKloud LFCS course sections mapped to notes; Ghada Atef lab scripts and giulianopz notes as free extras; killercoda Ubuntu playground; man pages per domain; le-linux links for depth; what the killer.sh LFCS simulator covers), **`03-exam-day-playbook.md`** (PSI rules, base and hosts, first two minutes, task ordering: quick tasks first, firewall and networking last, 6 minutes per task, flag at 8, verification list per family, persistence checklist, recovery: `sshd -t`, `netplan try`, `mount -a`, `visudo -c`, never blocking the three ports, top 15 lessons from research §2).
- [ ] **Step 3: `lfcs/README.md`**: verified facts, folder map, quick start (lab guide, CLI, calendar), warning that the CLI modifies the VM and must never run on a real host.
- [ ] **Step 4: Verify** `python3 scripts/generate_toc.py --inject lfcs && bash scripts/check-docs.sh lfcs` → `ALL OK`; coverage: every one of the 34 bullets appears in `01-domain-checklists.md` with a recipe and a Q id.
- [ ] **Step 5: Commit** `docs(lfcs): dated study plan 13 Dec to 6 Feb, resources, playbook, README`, then `git push -u origin lfcs`.

---

## Phase 4: practice CLI, questions, mocks (done by 12 Dec 2026)

### Task 11: Harness copy and LFCS environment library

**Files:**
- Copy: `cks/practice-cli/lib/colors.sh`, `checks.sh`, `progress.sh`, `menu.sh` to `lfcs/practice-cli/lib/`; `cks/practice-cli/tools/build-registry.sh`, `build-guide.sh`, `build-mock.sh` to `lfcs/practice-cli/tools/`; `cks/practice-cli/cks` to `lfcs/practice-cli/lfcs`
- Create: `lfcs/practice-cli/lib/env.sh`

- [ ] **Step 1: Copy and apply the exact edits**

```bash
mkdir -p lfcs/practice-cli/{lib,tools,questions} lfcs/mock-exams
cp cks/practice-cli/lib/{colors,checks,progress,menu}.sh lfcs/practice-cli/lib/
cp cks/practice-cli/tools/{build-registry,build-guide,build-mock}.sh lfcs/practice-cli/tools/
cp cks/practice-cli/cks lfcs/practice-cli/lfcs
cd lfcs/practice-cli
sed -i '' 's/CKS Exam Practice CLI/LFCS Exam Practice CLI/; s/All CKS Questions/All LFCS Questions/' lib/menu.sh
sed -i '' 's/CKS_STATE_DIR/LFCS_STATE_DIR/g' lib/progress.sh
sed -i '' 's/"D1|Cluster Setup" "D2|Cluster Hardening" "D3|System Hardening" "D4|Minimize Microservice Vulnerabilities" "D5|Supply Chain Security" "D6|Monitoring, Logging and Runtime Security"/"D1|Operations Deployment" "D2|Networking" "D3|Storage" "D4|Essential Commands" "D5|Users and Groups"/' lib/progress.sh
sed -i '' 's/cks-exam-qa-guide.md/lfcs-exam-qa-guide.md/; s/CKS Exam Question and Answer Guide/LFCS Exam Question and Answer Guide/; s/Kubernetes v1.35 environment, 15 to 20 tasks, 2 hours, 67% to pass, CKA prerequisite./17 to 20 tasks, 2 hours, 67% to pass, man pages only, one designated host per task./' tools/build-guide.sh
sed -i '' 's/CKS Mock Exam/LFCS Mock Exam/; s/\.\/cks --mock/.\/lfcs --mock/' tools/build-mock.sh
sed -i '' 's/CKS_STATE_DIR/LFCS_STATE_DIR/g; s/CKS Exam Practice CLI/LFCS Exam Practice CLI/; s/Good luck on your CKS. Secure those clusters./Good luck on your LFCS. Own the box./; s/require_context_allowed || exit 1/require_lab_host || exit 1/g; s/usage: cks/usage: lfcs/' lfcs
```
  Then in `lfcs` replace the `show_env` function body and the `for d in D1 … D6` line in `mock_domain_report` with the LFCS versions in Step 3, and remove the `kubectl`-specific lines (`context`, `CNI`, `node root`, the tool list) from `show_env`.

- [ ] **Step 2: Write `lib/env.sh`**

```bash
#!/usr/bin/env bash
# LFCS environment: root guard, lab marker, distro, needs tags, loop disks, netns peer host, backups.
LFCS_STATE_DIR="${LFCS_STATE_DIR:-/var/lib/lfcs}"
COURSE_DIR="${COURSE_DIR:-/opt/course}"
export LFCS_STATE_DIR COURSE_DIR

require_root() { if [[ $EUID -ne 0 ]]; then exec sudo -E "$0" "$@"; fi; mkdir -p "$LFCS_STATE_DIR/backup" "$LFCS_STATE_DIR/disks" "$COURSE_DIR"; }
require_lab_host() {
  [[ "${LFCS_ALLOW_HOST:-0}" == "1" ]] && return 0
  [[ -f /etc/lfcs-lab ]] && return 0
  echo "Refusing to run: /etc/lfcs-lab is missing. This CLI modifies users, disks, firewalls and services; run it only inside the lab VMs (provision scripts write the marker) or set LFCS_ALLOW_HOST=1."
  return 1
}
distro() { . /etc/os-release 2>/dev/null; case "${ID:-}" in ubuntu|debian) echo ubuntu ;; rocky|rhel|centos|almalinux|fedora) echo rocky ;; *) echo "${ID:-unknown}" ;; esac; }
require_distro() { [[ "$(distro)" == "$1" ]] || { echo "This question runs on $1 only (this host is $(distro))."; return 1; }; }
course_dir() { mkdir -p "$COURSE_DIR/$1" && echo "$COURSE_DIR/$1"; }

spare_disk() {   # prints the first whole disk with no partitions, no filesystem, no mount (empty when none)
  lsblk -dpno NAME,TYPE | awk '$2=="disk" {print $1}' | while read -r d; do
    [[ -z "$(lsblk -no FSTYPE "$d" | tr -d ' \n')" && -z "$(lsblk -no MOUNTPOINT "$d" | tr -d ' \n')" && "$(lsblk -no NAME "$d" | wc -l)" -eq 1 ]] && { echo "$d"; return; }
  done
}
make_loop_disk() {   # make_loop_disk name sizeM -> prints /dev/loopN (idempotent per name)
  local name="$1" size="$2" img="$LFCS_STATE_DIR/disks/$1.img" dev
  dev=$(losetup -j "$img" 2>/dev/null | cut -d: -f1 | head -1)
  if [[ -z "$dev" ]]; then
    [[ -f "$img" ]] || truncate -s "${size}M" "$img"
    dev=$(losetup -fP --show "$img") || return 1
  fi
  echo "$dev"
}
free_loop_disk() {   # free_loop_disk name
  local img="$LFCS_STATE_DIR/disks/$1.img" dev
  for dev in $(losetup -j "$img" 2>/dev/null | cut -d: -f1); do wipefs -aq "$dev" 2>/dev/null; losetup -d "$dev"; done
  rm -f "$img"
}
make_netns_peer() {  # make_netns_peer name subnet-octet [http|sshd] -> host side 10.99.N.1/24, peer 10.99.N.2/24
  local ns="$1" n="$2" svc="${3:-}" h="veth-$1" p="veth-$1-p"
  ip netns list | grep -qw "$ns" || ip netns add "$ns"
  ip link show "$h" >/dev/null 2>&1 || { ip link add "$h" type veth peer name "$p"; ip link set "$p" netns "$ns"; }
  ip addr replace "10.99.$n.1/24" dev "$h"; ip link set "$h" up
  ip netns exec "$ns" ip addr replace "10.99.$n.2/24" dev "$p"; ip netns exec "$ns" ip link set "$p" up; ip netns exec "$ns" ip link set lo up
  ip netns exec "$ns" ip route replace default via "10.99.$n.1" 2>/dev/null
  case "$svc" in
    http) ip netns exec "$ns" sh -c "cd /var/lib/lfcs && nohup python3 -m http.server 80 --bind 10.99.$n.2 >/dev/null 2>&1 &" ;;
    sshd) mkdir -p "$LFCS_STATE_DIR/$ns"; [[ -f "$LFCS_STATE_DIR/$ns/hostkey" ]] || ssh-keygen -q -t ed25519 -N '' -f "$LFCS_STATE_DIR/$ns/hostkey"
          ip netns exec "$ns" /usr/sbin/sshd -h "$LFCS_STATE_DIR/$ns/hostkey" -o "ListenAddress=10.99.$n.2" -o "PidFile=$LFCS_STATE_DIR/$ns/sshd.pid" ;;
  esac
  echo "10.99.$n.2"
}
del_netns_peer() { local ns="$1"; ip netns pids "$ns" 2>/dev/null | xargs -r kill 2>/dev/null; ip link del "veth-$1" 2>/dev/null; ip netns del "$ns" 2>/dev/null; rm -rf "$LFCS_STATE_DIR/$ns"; return 0; }
in_peer() { ip netns exec "$1" "${@:2}"; }   # in_peer name cmd...

has_needs() {
  local n
  for n in $1; do
    case "$n" in
      linux)  [[ "$(uname -s)" == Linux ]] || return 1 ;;
      disk)   [[ -n "$(spare_disk)" ]] || losetup -f >/dev/null 2>&1 || return 1 ;;
      netns)  ip netns add lfcs-probe 2>/dev/null && ip netns del lfcs-probe || return 1 ;;
      host2)  ssh -o BatchMode=yes -o ConnectTimeout=3 node2 true >/dev/null 2>&1 || return 1 ;;
      nic2)   [[ "$(ip -o link | awk -F': ' '{print $2}' | grep -Evc '^(lo|docker|veth|virbr|br-|podman|cni)')" -ge 2 ]] || return 1 ;;
      rocky)  [[ "$(distro)" == rocky ]] || return 1 ;;
      ubuntu) [[ "$(distro)" == ubuntu ]] || return 1 ;;
      virt)   command -v virsh >/dev/null 2>&1 && systemctl is-active libvirtd >/dev/null 2>&1 || return 1 ;;
      tool:*) command -v "${n#tool:}" >/dev/null 2>&1 || return 1 ;;
      *)      echo "unknown need tag: $n" >&2; return 1 ;;
    esac
  done
  return 0
}
backup_file() { local f="$1" q="$2" b; mkdir -p "$LFCS_STATE_DIR/backup/$q"; b="$LFCS_STATE_DIR/backup/$q/$(echo "$f" | tr / _)"; [[ -f "$f" && ! -f "$b" ]] && cp -p "$f" "$b"; return 0; }
restore_file() { local f="$1" q="$2" b; b="$LFCS_STATE_DIR/backup/$q/$(echo "$f" | tr / _)"; if [[ -f "$b" ]]; then cp -p "$b" "$f" && rm -f "$b"; fi; return 0; }
pkg_install() { if [[ "$(distro)" == ubuntu ]]; then DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$@" >/dev/null; else dnf install -y -q "$@" >/dev/null; fi; }
```

- [ ] **Step 3: LFCS `show_env` and domain list** in `lfcs`

```bash
show_env() {
  print_header "${ICON_GEAR} Environment"
  echo -e "  host:         $(hostname) ($(distro))"
  if require_lab_host >/dev/null 2>&1; then echo -e "  lab marker:   yes"; else echo -e "  lab marker:   ${RED}missing${RESET}"; fi
  echo -e "  state dir:    $LFCS_STATE_DIR"
  echo -e "  deliverables: $COURSE_DIR"
  echo -e "  spare disk:   $(spare_disk)$( [[ -z "$(spare_disk)" ]] && echo '(none; loop devices will be used)')"
  local t; for t in lvm mdadm cryptsetup exportfs nbd-client podman virsh chronyc nft ufw firewall-cmd semanage git openssl pidstat setfacl sssd; do
    if command -v "$t" >/dev/null 2>&1; then echo -e "  tool $t: ${GREEN}present${RESET}"; else echo -e "  tool $t: ${GRAY}missing${RESET}"; fi
  done
  echo ""; echo -e "  ${BOLD}Runnable questions here:${RESET}"
  local q id needs runnable=0
  for q in "${QUESTIONS[@]}"; do
    id=$(get_question_id "$q"); needs=$(get_question_needs "$q")
    if has_needs "$needs"; then echo -e "  ${GREEN}Q$id${RESET} $(get_question_title "$q")"; runnable=$((runnable + 1)); else echo -e "  ${GRAY}Q$id needs: $needs${RESET}"; fi
  done
  echo ""; echo -e "  $runnable of ${#QUESTIONS[@]} questions runnable on this host."
}
```
  and `for d in D1 D2 D3 D4 D5; do` in `mock_domain_report`. Insert `require_root "$@"` as the first statement after the `source` lines, and change the mock duration text to "18 tasks, 120 minutes".

- [ ] **Step 4: Test on the Mac** (menu only): `bash -n lfcs/practice-cli/lfcs lfcs/practice-cli/lib/*.sh lfcs/practice-cli/tools/*.sh && echo syntax-ok`. (`--list` needs a registry; tested in Task 12.)
- [ ] **Step 5: Commit** `feat(lfcs-cli): copy harness and add LFCS environment library (loop disks, netns peer, guards)`.

### Task 12: Questions batch 1, Operations Deployment Q1 to Q11

Every `verify.sh` sources `../../lib/checks.sh` and `../../lib/env.sh`; every setup prints the facts (device names, peer IPs, usernames). Solutions carry Ubuntu and Rocky variants where they differ.

| Q, folder | Title, meta | setup.sh creates | verify.sh checks | Solution key steps |
|---|---|---|---|---|
| 01 `q01-sysctl-persistent` | Kernel parameters now and after reboot. `needs="" weight=4 minutes=5 sources=0 host=any` | sets `net.ipv4.ip_forward=0`, removes `/etc/sysctl.d/90-lab.conf` | `sysctl -n net.ipv4.ip_forward` is 1; `sysctl -n vm.swappiness` is 10; a file under `/etc/sysctl.d` or `/etc/sysctl.conf` contains both keys | `sysctl -w`, write the drop-in, `sysctl --system` |
| 02 `q02-process-io-hog` | Find the disk-reading process, record its PID, lower its priority. `needs="tool:pidstat" weight=5 minutes=6 sources=4 host=any` | 200 MB file; background loop `bash -c 'exec -a lfcs-reader bash -c "while true; do cat FILE >/dev/null; done"'`; PID in state | `$COURSE_DIR/2/pid.txt` equals the reader PID; `ps -o ni= -p PID` is 15 | `pidstat -d 1 5`, `renice -n 15 -p` |
| 03 `q03-cron-and-at` | Scheduled jobs for a user, root, and a one-off. `needs="" weight=5 minutes=6 sources=2 host=any` | user `backupop`; `/usr/local/bin/backup.sh` and `cleanup.sh` | `crontab -l -u backupop` has `30 2 * * * /usr/local/bin/backup.sh`; root crontab has `0 4 * * 0 /usr/local/bin/cleanup.sh`; `atq` has at least one job | `crontab -e -u`, `echo cmd | at 23:00` |
| 04 `q04-systemd-timer` | A timer that runs a script every 15 minutes. `needs="" weight=6 minutes=8 sources=2 host=any` | `/usr/local/bin/logsync.sh` | `logsync.service` and `logsync.timer` exist; `systemctl is-enabled logsync.timer` enabled; `is-active` active; `systemctl show logsync.timer -p TimersCalendar` contains `*:0/15` | write both units, `daemon-reload`, `enable --now logsync.timer` |
| 05 `q05-packages` | Install, hold, verify, and report packages. `needs="" weight=4 minutes=5 sources=3 host=any` | removes `tree` and `nginx` if present | `command -v tree`; nginx package installed, `systemctl is-enabled nginx` disabled and inactive; `$COURSE_DIR/5/version.txt` equals `dpkg-query -W -f='${Version}' openssl` or `rpm -q --qf '%{VERSION}-%{RELEASE}' openssl`; `$COURSE_DIR/5/verify.txt` is the output of `dpkg -V bash` or `rpm -V bash` (empty allowed) | apt or dnf install, `systemctl disable --now nginx`, query versions |
| 06 `q06-boot-target-grub` | Default target and GRUB timeout, persistent. `needs="" weight=5 minutes=6 sources=2 host=any` | `backup_file /etc/default/grub`; `systemctl set-default graphical.target` | `systemctl get-default` is `multi-user.target`; `/etc/default/grub` has `GRUB_TIMEOUT=10`; `/boot/grub/grub.cfg` (ubuntu) or `/boot/grub2/grub.cfg` (rocky) contains `timeout=10` | `set-default`, edit, `update-grub` or `grub2-mkconfig -o` |
| 07 `q07-libvirt-define-vm` | Define a VM from a disk image and set autostart. `needs="virt tool:qemu-img" weight=6 minutes=8 sources=3 host=any` | `qemu-img create -f qcow2 /var/lib/libvirt/images/lab.qcow2 1G` | `virsh dominfo labvm` exists; `Autostart: enable`; `Max memory: 524288 KiB`; `CPU(s): 1`; disk path in `virsh domblklist labvm` | `virt-install --name labvm --memory 512 --vcpus 1 --disk … --import --os-variant generic --virt-type qemu --noautoconsole --print-xml > labvm.xml; virsh define labvm.xml; virsh autostart labvm` |
| 08 `q08-podman-container` | Run a web container with limits and a restart policy that survives reboot. `needs="tool:podman" weight=7 minutes=8 sources=4 host=any` | `/srv/web` empty; pulls `docker.io/library/nginx:1.27` | `podman inspect web --format '{{.HostConfig.Memory}}'` is 268435456; `'{{.HostConfig.PortBindings}}'` maps 80 to 8080; `curl -s localhost:8080` returns `hello`; `systemctl is-enabled container-web` enabled or `podman inspect --format '{{.HostConfig.RestartPolicy.Name}}'` is `always` | `podman run -d --name web -p 8080:80 -m 256m --restart=always -v /srv/web:/usr/share/nginx/html:ro,Z nginx:1.27`, `podman generate systemd --new --name web`, enable |
| 09 `q09-selinux-httpd-docroot` | Serve a custom document root on a custom port under SELinux enforcing. `needs="rocky tool:semanage" weight=7 minutes=8 sources=3 host=rocky` | installs httpd; `/srv/site/index.html` with wrong context; `Listen 8081` and `DocumentRoot /srv/site`; `setenforce 1` | `getenforce` Enforcing; `curl -s localhost:8081` returns the page; `ls -Zd /srv/site` has `httpd_sys_content_t`; `semanage port -l | grep http_port_t` includes 8081; `getsebool httpd_can_network_connect` on; `firewall-cmd --list-ports` includes `8081/tcp` | `semanage fcontext -a -t`, `restorecon -Rv`, `semanage port -a -t http_port_t -p tcp 8081`, `setsebool -P`, `firewall-cmd --add-port --permanent`, restart httpd |
| 10 `q10-systemd-service-unit` | Write a service unit for an application. `needs="" weight=6 minutes=8 sources=2 host=any` | `/opt/inventory/server.sh` (python http server on 9090); user `inventory` | unit has `User=inventory`, `Restart=on-failure`, `WantedBy=multi-user.target`; enabled and active; `ss -H -ltn` shows `:9090`; the process runs as `inventory` | write the unit, `daemon-reload`, `enable --now` |
| 11 `q11-journald-troubleshoot-service` | A service fails to start: find why, fix it, make the journal persistent. `needs="" weight=6 minutes=8 sources=2 host=any` | `billing.service` whose script lacks the executable bit; `backup_file /etc/systemd/journald.conf`; sets `Storage=volatile` | `systemctl is-active billing` active; `$COURSE_DIR/11/error.txt` contains `Permission denied` or `203/EXEC`; `/etc/systemd/journald.conf` has `Storage=persistent`; `/var/log/journal` exists | `journalctl -u billing -b`, `chmod +x`, `systemctl restart`, edit journald.conf, `systemctl restart systemd-journald` |

- [ ] **Step 1: Write the eleven folders.**
- [ ] **Step 2: Verify**

```bash
bash -n lfcs/practice-cli/questions/*/*.sh && echo syntax-ok
bash lfcs/practice-cli/tools/build-registry.sh && bash lfcs/practice-cli/tools/build-guide.sh
./lfcs/practice-cli/lfcs --list 2>/dev/null | grep -c '\[Q' || bash -c 'cd lfcs/practice-cli; LFCS_ALLOW_HOST=1 bash -c "source lib/colors.sh; source lib/env.sh; source lib/questions.sh; echo \${#QUESTIONS[@]}"'
```
Expected: `syntax-ok`, registry written, `11`. (On the Mac `require_root` execs `sudo`; use the second form.)
- [ ] **Step 3: Commit** `feat(lfcs-cli): add Operations Deployment questions Q1 to Q11`.

### Task 13: Questions batch 2, Networking Q12 to Q22

| Q, folder | Title, meta | setup.sh creates | verify.sh checks | Solution key steps |
|---|---|---|---|---|
| 12 `q12-static-ip-second-nic` | Static IPv4 on the second NIC, persistent. `needs="nic2" weight=6 minutes=8 sources=1 host=any` | records the second NIC name in state; backs up `/etc/netplan/*.yaml` or the nmcli connection; removes its address | `ip -j addr show NIC` contains `192.168.56.10/24` (or `.20` on rocky); persistence: a netplan file contains the address, or `nmcli -g ipv4.addresses con show <con>` prints it | netplan yaml with `addresses:` and `netplan apply`, or `nmcli con mod … ipv4.method manual ipv4.addresses …; nmcli con up` |
| 13 `q13-static-route` | Persistent static route. `needs="nic2" weight=5 minutes=6 sources=1 host=any` | configures the NIC as in Q12 | `ip -j route` has `10.200.0.0/16 via 192.168.56.1`; netplan `routes:` or `nmcli -g ipv4.routes` contains it | netplan `routes: [{to: 10.200.0.0/16, via: 192.168.56.1}]` or `nmcli con mod … +ipv4.routes "10.200.0.0/16 192.168.56.1"` |
| 14 `q14-hostname-and-resolver` | Hostname, hosts file, DNS servers and search domain. `needs="" weight=5 minutes=6 sources=3 host=any` | `backup_file /etc/hosts`; records the current hostname | `hostnamectl --static` is `node1.lab.local` (or `node2…`); `getent hosts node9` is `192.168.56.90`; `resolvectl dns` or `/etc/resolv.conf` lists `1.1.1.1` and `9.9.9.9`; search domain `lab.local` | `hostnamectl set-hostname`, edit hosts, netplan `nameservers` or `nmcli ipv4.dns`, `resolvectl status` |
| 15 `q15-chrony-time-sync` | Time source, NTP serving, timezone. `needs="tool:chronyc" weight=5 minutes=6 sources=0 host=any` | `backup_file` chrony.conf; timezone UTC | chrony.conf has `server time.google.com iburst` and `allow 192.168.56.0/24`; `chronyc sources` lists `time.google.com`; `timedatectl show -p Timezone --value` is `Asia/Kolkata`; service active | edit, `systemctl restart chrony` or `chronyd`, `timedatectl set-timezone` |
| 16 `q16-ssh-hardening-keys` | Harden sshd, key-only login with one password exception. `needs="" weight=6 minutes=8 sources=2 host=any` | user `deploy`; key pair in `$COURSE_DIR/16/`; `backup_file /etc/ssh/sshd_config` | `sshd -T` has `permitrootlogin no`, `passwordauthentication no`, `maxauthtries 3`; `sshd -T -C user=deploy,host=x,addr=127.0.0.1` has `passwordauthentication yes`; `/home/deploy/.ssh/authorized_keys` contains the public key, mode 600, owner deploy; `ssh -i key -o BatchMode=yes deploy@localhost true` succeeds | edit sshd_config with a `Match User deploy` block at the end, `sshd -t`, restart |
| 17 `q17-firewall-filter-persistent` | Allow only ssh, http, https, icmp; persistent; never block the exam ports. `needs="netns" weight=8 minutes=10 sources=7 host=any` | peer `fw-peer` at `10.99.17.2`; listeners on host `10.99.17.1:80` and `:9999`; `backup_file` the persistence files; flushes rules | from the peer `curl --max-time 3 10.99.17.1:80` succeeds, `:9999` fails, `ping -c1 10.99.17.1` succeeds; persistence: `/etc/nftables.conf` or `/etc/sysconfig/nftables.conf` contains the rules, or `ufw status` is active with 22, 80, 443, or `firewall-cmd --permanent --list-services` includes ssh http https; nothing blocks `8080`, `4505`, `4506` (`nft -j list ruleset` has no drop for them and the input policy allows or they are accepted) | nft table, chain with policy drop, accept rules, save to the persistence file, enable the service |
| 18 `q18-port-redirect-nat` | Redirect a port and masquerade a subnet, persistent. `needs="netns" weight=7 minutes=8 sources=7 host=any` | peer `nat-peer` at `10.99.18.2` with default route via the host; listener on `10.99.18.1:8080`; `ip_forward` on | from the peer `curl 10.99.18.1:8081` returns the 8080 page; `nft -j list ruleset` or `iptables -t nat -S` contains a redirect from 8081 to 8080 and a masquerade for `10.99.18.0/24`; persistence file contains them | `nft add table ip nat`, prerouting redirect, postrouting masquerade, save |
| 19 `q19-bridge-second-nic` | Put the second NIC into a bridge, persistent. `needs="nic2" weight=6 minutes=8 sources=1 host=any` | backs up the NIC config | `ip -j link show br0` type bridge; `bridge link` shows the NIC with master br0; br0 has `192.168.56.10/24` (or `.20`); netplan `bridges:` or nmcli bridge connection exists | netplan `bridges: br0: interfaces: [eth1]`, or `nmcli con add type bridge`, `bridge-slave` |
| 20 `q20-reverse-proxy-nginx` | Reverse proxy in front of an application. `needs="" weight=6 minutes=8 sources=2 host=any` | backend unit on `127.0.0.1:9000` serving `backend-ok`; installs nginx; removes the default site | `curl -s localhost/` returns `backend-ok`; nginx config contains `proxy_pass http://127.0.0.1:9000`; `systemctl is-enabled nginx` enabled; on rocky `getsebool httpd_can_network_connect` on | write the server block, `nginx -t`, reload, SELinux boolean on rocky |
| 21 `q21-nfs-export-and-mount` | Export a directory and mount it persistently. `needs="tool:exportfs" weight=7 minutes=8 sources=3 host=any` | `/srv/share` with a marker file; nfs server active | `exportfs -v` shows `/srv/share` with `rw` and `no_root_squash` for `10.0.0.0/8`; `findmnt -no FSTYPE /mnt/share` is nfs or nfs4; the marker file is readable at `/mnt/share`; fstab line for `/mnt/share` with `nfs` and `_netdev`; `findmnt --verify` clean | `/etc/exports`, `exportfs -ra`, `mount -t nfs localhost:/srv/share /mnt/share`, fstab; with `host2` present the solution shows the two-VM variant |
| 22 `q22-network-troubleshoot-unreachable` | The web app is unreachable from the peer: find and fix two causes. `needs="netns" weight=6 minutes=8 sources=5 host=any` | unit binding `127.0.0.1:8082`; nft drop rule for 8082; peer `dbg-peer` at `10.99.22.2` | from the peer `curl --max-time 3 10.99.22.1:8082` succeeds; `$COURSE_DIR/22/causes.txt` mentions `127.0.0.1` or `bind` and `nft`, `firewall`, or `drop` | `ss -tlpn`, fix the bind address, `nft list ruleset`, delete the rule |

- [ ] **Step 1: Write the eleven folders.** **Step 2: Verify** (registry count 22). **Step 3: Commit** `feat(lfcs-cli): add Networking questions Q12 to Q22`.

### Task 14: Questions batch 3, Storage Q23 to Q31

| Q, folder | Title, meta | setup.sh creates | verify.sh checks | Solution key steps |
|---|---|---|---|---|
| 23 `q23-partition-format-fstab-uuid` | Partition, format, label, mount by UUID with options. `needs="disk" weight=6 minutes=8 sources=2 host=any` | `make_loop_disk d23 2048` or `spare_disk`; prints the device | one partition on the device; `blkid -o value -s TYPE` ext4 and `LABEL` `data`; `findmnt -no OPTIONS /data` contains `noatime`; fstab line for `/data` uses `UUID=` equal to `blkid -s UUID -o value`; `findmnt --verify` clean | `parted`, `mkfs.ext4 -L data`, `blkid`, fstab, `mount -a` |
| 24 `q24-lvm-create` | Volume group with a custom extent size and a mounted logical volume. `needs="disk" weight=7 minutes=8 sources=4 host=any` | two loop disks 1024 MB | `vgs --noheadings -o vg_name` contains `vg_data`; `vgs --noheadings -o vg_extent_size vg_data` is `16.00m`; `lvs --noheadings -o lv_size vg_data/lv_app` is `1.50g`; mounted at `/app` ext4; fstab entry | `pvcreate`, `vgcreate -s 16M`, `lvcreate -L 1.5G -n lv_app`, mkfs, mount, fstab |
| 25 `q25-lvm-extend-online` | Grow a mounted logical volume after adding a disk. `needs="disk" weight=6 minutes=6 sources=4 host=any` | `vg_ext` with `lv_logs` 500 MB ext4 mounted at `/var/lib/lfcs-logs` on loop disk A (600 MB); loop disk B (1024 MB) unused; writes a marker file | `pvs --noheadings -o vg_name` shows two PVs in `vg_ext`; `lvs --noheadings -o lv_size vg_ext/lv_logs` at least `900.00m`; `df -BM --output=size /var/lib/lfcs-logs` at least 850M; still mounted; marker file present | `pvcreate B`, `vgextend`, `lvextend -r -L +400M` |
| 26 `q26-swap-file` | Add a swap file with a priority, persistent. `needs="" weight=4 minutes=5 sources=1 host=any` | none | `swapon --show --noheadings` includes `/swapfile2` 512M prio 10; `stat -c %a /swapfile2` is 600; fstab line with `pri=10` | `fallocate`, `chmod 600`, `mkswap`, `swapon -p 10`, fstab |
| 27 `q27-user-quota` | User quota on a filesystem. `needs="disk" weight=6 minutes=8 sources=0 host=any` | loop disk ext4 mounted at `/quota` with fstab; user `qa` | `findmnt -no OPTIONS /quota` contains `usrquota`; `quotaon -p /quota` reports on; `repquota -u /quota` shows `qa` soft 51200 hard 102400 | fstab `usrquota`, remount, `quotacheck -cu`, `quotaon`, `setquota -u qa 51200 102400 0 0 /quota` |
| 28 `q28-raid1-mdadm` | Mirror two disks and mount the array. `needs="disk tool:mdadm" weight=6 minutes=8 sources=1 host=any` | two loop disks | `mdadm --detail /dev/md0` level raid1 with 2 active devices; `/etc/mdadm/mdadm.conf` or `/etc/mdadm.conf` has an `ARRAY` line; mounted at `/mnt/raid`; fstab | `mdadm --create`, `mkfs.ext4`, `mdadm --detail --scan >> conf`, fstab |
| 29 `q29-luks-encrypted-volume` | Encrypted volume unlocked with a key file at boot. `needs="disk tool:cryptsetup" weight=7 minutes=8 sources=0 host=any` | loop disk | `cryptsetup status secret` active; `/etc/crypttab` has `secret UUID=… /root/secret.key`; `stat -c %a /root/secret.key` 600; mounted at `/mnt/secret`; fstab | `luksFormat`, `luksAddKey`, `luksOpen`, mkfs, crypttab, fstab |
| 30 `q30-nbd-mount` | Attach a network block device and mount it. `needs="netns tool:nbd-client" weight=6 minutes=8 sources=0 host=any` | peer `nbd-peer` at `10.99.30.2` running `nbd-server` (config in state) exporting a 200 MB ext4 image | `nbd-client -c /dev/nbd0` connected; `findmnt -no SOURCE /mnt/nbd` is `/dev/nbd0`; a marker file readable | `modprobe nbd`, `nbd-client 10.99.30.2 10809 /dev/nbd0 -name export`, mount |
| 31 `q31-disk-full-triage` | Filesystem nearly full: recover space and find the hidden consumer. `needs="disk" weight=5 minutes=6 sources=2 host=any` | loop disk 300 MB mounted at `/data`; junk files under `/data/tmp`; a process holding a deleted 100 MB file; records the largest file path | `/data` usage under 60%; `$COURSE_DIR/31/biggest.txt` equals the recorded path; `lsof +L1 | grep /data` empty | `du -xh --max-depth=1`, `find -size +50M`, `rm`, `lsof +L1`, kill or restart the holder |

- [ ] **Step 1: Write the nine folders.** **Step 2: Verify** (registry 31). **Step 3: Commit** `feat(lfcs-cli): add Storage questions Q23 to Q31`.

### Task 15: Questions batch 4, Essential Commands Q32 to Q40

| Q, folder | Title, meta | setup.sh creates | verify.sh checks | Solution key steps |
|---|---|---|---|---|
| 32 `q32-git-basics` | Clone, branch, ignore, commit, push. `needs="tool:git" weight=5 minutes=6 sources=1 host=any` | bare repo `$COURSE_DIR/32/repo.git` with one commit | `git -C work rev-parse --abbrev-ref HEAD` is `feature/lfcs`; `.gitignore` contains `*.log`; last commit author email `lfcs@example.com`; `git --git-dir=repo.git branch --list feature/lfcs` non-empty | `git clone`, `checkout -b`, `git config user.email`, commit, `push -u origin feature/lfcs` |
| 33 `q33-openssl-inspect-and-selfsigned` | Read a certificate and issue a self-signed one. `needs="tool:openssl" weight=5 minutes=6 sources=4 host=any` | `$COURSE_DIR/33/server.crt` with CN `shop.example` and a fixed expiry | `answer.txt` contains the CN and the `notAfter` date as printed by `openssl x509 -noout -subject -enddate`; `/etc/ssl/lab/lab.crt` has `CN = lab.local`, validity 365 days (within 1), `/etc/ssl/lab/lab.key` mode 600, key and cert moduli match | `openssl x509 -noout -subject -enddate`, `openssl req -x509 -newkey rsa:2048 -nodes -days 365 -subj /CN=lab.local` |
| 34 `q34-find-and-special-permissions` | Locate files by owner and size, list SUID binaries, set SGID and sticky. `needs="" weight=5 minutes=6 sources=3 host=any` | `$COURSE_DIR/34/data` tree with files of various owners and sizes; user `auditor`; group `devs`; empty `shared` dir | `found/` contains exactly the files owned by auditor over 1 MB with original permissions; `suid.txt` contains `/usr/bin/passwd`; `stat -c %A shared` ends with `t` and has `s` in the group triplet; group `devs` | `find -user auditor -size +1M -exec cp -p {} found/ \;`, `find /usr/bin -perm -4000`, `chgrp devs; chmod 3775` |
| 35 `q35-text-processing-pipeline` | Reports from a log with grep, sort, uniq, sed, awk. `needs="" weight=5 minutes=6 sources=3 host=any` | `access.log` with known IP counts and 5xx lines; `urls.txt`; `data.csv`; expected outputs in state | `top-ips.txt` equals the expected five `count ip` lines; `errors.txt` line count equals the 5xx count; `urls.txt` contains no `http://`; `col3.txt` equals the expected third column | `awk '{print $1}' | sort | uniq -c | sort -rn | head -5`, `grep -E ' 5[0-9]{2} '`, `sed -i`, `awk -F,` |
| 36 `q36-archives-and-links` | Archive with exclusions, extract, symbolic and hard links. `needs="" weight=4 minutes=5 sources=2 host=any` | `project/` tree with `*.tmp` files; `bundle.tar.xz` containing `v2/`; `notes.txt` | `tar -tzf project.tar.gz` lists the sources and no `.tmp`; `extracted/v2` exists; `readlink current` is `extracted/v2`; `stat -c %i notes.txt` equals `stat -c %i notes.hard` | `tar czf --exclude='*.tmp'`, `tar xJf -C`, `ln -s`, `ln` |
| 37 `q37-redirection-script` | A script with separate stdout and stderr files. `needs="" weight=4 minutes=5 sources=2 host=any` | `$COURSE_DIR/37/` | `report.sh` executable, `bash -n` clean; running it creates `report.txt` containing `Filesystem` and a trailing date line, and `errors.txt`; prints `DONE` | `#!/bin/bash`, `df -h > report.txt 2> errors.txt`, `free -m >> report.txt`, `date >> report.txt`, `echo DONE` |
| 38 `q38-service-port-conflict` | A service cannot start because another one owns its port. `needs="" weight=6 minutes=8 sources=2 host=any` | `legacy.service` on 8090 (enabled, active); `webapp.service` on 8090 (failed) | `webapp` active; `systemctl is-enabled legacy` is `masked`; `$COURSE_DIR/38/answer.txt` equals `legacy.service` | `journalctl -u webapp`, `ss -tlpn`, `systemctl disable --now legacy; systemctl mask legacy`, start webapp |
| 39 `q39-resource-monitoring` | Report CPU hog, load, cores, memory, process count. `needs="" weight=4 minutes=5 sources=3 host=any` | CPU hog `exec -a lfcs-burner sha256sum /dev/zero` | `cpu.txt` equals the burner PID; `cores.txt` equals `nproc`; `load.txt` has three numbers; `mem.txt` within 15% of `free -m` available; `procs.txt` within 20 of `ps -e --no-headers | wc -l` | `top -bn1 -o %CPU`, `uptime`, `nproc`, `free -m`, `ps -e` |
| 40 `q40-service-limits-dropin` | A service fails its file-descriptor limit: raise it with a drop-in. `needs="" weight=5 minutes=6 sources=1 host=any` | `fdhog.service` with `LimitNOFILE=16` running a script that opens 100 files and exits non-zero when it cannot | `/etc/systemd/system/fdhog.service.d/*.conf` sets `LimitNOFILE=65536` and `TasksMax=4096`; `systemctl show fdhog -p LimitNOFILE` is 65536; active | `systemctl edit fdhog`, `daemon-reload`, restart |

- [ ] **Step 1: Write the nine folders.** **Step 2: Verify** (registry 40). **Step 3: Commit** `feat(lfcs-cli): add Essential Commands questions Q32 to Q40`.

### Task 16: Questions batch 5, Users and Groups Q41 to Q45

| Q, folder | Title, meta | setup.sh creates | verify.sh checks | Solution key steps |
|---|---|---|---|---|
| 41 `q41-users-groups-lifecycle` | Create users with exact attributes, a system account, and lock one. `needs="" weight=5 minutes=6 sources=1 host=any` | user `bob`; removes `ana`, `svc-batch`, group `devs` if present | `getent passwd ana` has UID 2001, shell `/bin/bash`, home `/home/ana`; `id -gn ana` is `devs` with GID 3001; `chage -l ana` shows `Account expires` `Jun 30, 2027`; `getent passwd svc-batch` UID under 1000 and shell `nologin`; `passwd -S bob` shows `L` | `groupadd -g 3001 devs`, `useradd -u 2001 -g devs -s /bin/bash -m -e 2027-06-30 ana`, `useradd -r -s /usr/sbin/nologin svc-batch`, `usermod -L bob` |
| 42 `q42-sudo-and-password-policy` | Sudo rules and password ageing. `needs="" weight=6 minutes=8 sources=2 host=any` | users `ana`, `opsman`; group `ops` with `opsman`; `backup_file /etc/login.defs`, `/etc/security/pwquality.conf` | `visudo -c` ok; `sudo -l -U ana` shows `(ALL) ALL`; `sudo -l -U opsman` shows `NOPASSWD: /usr/bin/systemctl restart nginx`; `login.defs` has `PASS_MAX_DAYS 90`; `chage -l ana` max 60, min 7, warn 14; `pwquality.conf` has `minlen = 12` | `/etc/sudoers.d/` files, `chage -M 60 -m 7 -W 14 ana`, edits |
| 43 `q43-acls-and-special-perms` | Group collaboration directory with ACLs. `needs="" weight=5 minutes=6 sources=1 host=any` | `/srv/projects/alpha`; users `ana`, `qauser`; groups `devs`, `qa` | `stat -c %A /srv/projects` has `s` in the group triplet and `---` for others; `getfacl -p /srv/projects` has `default:group:qa:r-x`; `getfacl -p /srv/projects/alpha` has `user:ana:rwx`; effective mask allows it | `chgrp devs; chmod 2770`, `setfacl -m d:g:qa:r-x`, `setfacl -m u:ana:rwx` |
| 44 `q44-profiles-skel-and-limits` | System-wide environment, skeleton, and per-user limits. `needs="" weight=5 minutes=6 sources=2 host=any` | user `ana`; removes `/etc/profile.d/lab.sh`, `/etc/skel/bin` | `su - ana -c 'echo $EDITOR:$HISTSIZE'` prints `vim:5000`; `su - ana -c 'echo $PATH'` contains `/home/ana/bin`; `/etc/skel/bin` exists and a user `newbie` created by the candidate has `/home/newbie/bin`; `su - ana -c 'ulimit -Hu'` is 200 and `ulimit -Sn` is 4096 | `/etc/profile.d/lab.sh`, `.bashrc`, `mkdir /etc/skel/bin`, `useradd -m newbie`, `/etc/security/limits.d/ana.conf` |
| 45 `q45-ldap-client-sssd` | Resolve users from an LDAP directory. `needs="ubuntu tool:slapd" weight=7 minutes=10 sources=0 host=ubuntu` | installs `slapd` with debconf preseed (domain `lab.local`, admin password `lfcs`), loads an LDIF with `ou=People` and user `ldapuser` (uid 5001); `backup_file /etc/nsswitch.conf`; removes `/etc/sssd/sssd.conf` | `getent passwd ldapuser` resolves with uid 5001; `systemctl is-active sssd`; `nsswitch.conf` passwd line contains `sss`; `id ldapuser` works | `/etc/sssd/sssd.conf` with `id_provider = ldap`, `ldap_uri = ldap://localhost`, `ldap_search_base = dc=lab,dc=local`, mode 600, `pam-auth-update --enable mkhomedir`, restart sssd |

- [ ] **Step 1: Write the five folders.** **Step 2: Verify** (registry 45). **Step 3: Commit** `feat(lfcs-cli): add Users and Groups questions Q41 to Q45`.

### Task 17: Mock sets, papers, README, CLI README

**Files:**
- Create: `lfcs/mock-exams/mock-1.set`, `mock-2.set`, `mock-3.set`, `lfcs/mock-exams/README.md`, `lfcs/practice-cli/README.md`
- Generate: `lfcs/mock-exams/mock-{1,2,3}.md`, `lfcs/practice-cli/lfcs-exam-qa-guide.md`

- [ ] **Step 1: Sets** (18 tasks each, `id|weight` with the meta weights):

```
# mock-1.set
01|4
03|5
04|6
08|7
10|6
12|6
14|5
16|6
17|8
21|7
23|6
24|7
26|4
32|5
33|5
35|5
41|5
43|5
```
```
# mock-2.set (Q9 is skipped automatically on the Ubuntu VM)
02|5
05|4
06|5
09|7
11|6
13|5
15|5
18|7
20|6
22|6
25|6
27|6
28|6
34|5
36|4
38|6
42|6
44|5
```
```
# mock-3.set: the rest plus the most-reported families again
07|6
19|6
29|7
30|6
31|5
37|4
39|4
40|5
45|7
17|8
24|7
33|5
08|7
21|7
16|6
23|6
04|6
41|5
```

- [ ] **Step 2: Generate and document**

```bash
for n in 1 2 3; do bash lfcs/practice-cli/tools/build-mock.sh $n; done
bash lfcs/practice-cli/tools/build-guide.sh
```
  `mock-exams/README.md`: restore the `clean` snapshot before a mock, `sudo ./lfcs --mock N`, the timing rules, the results log `/var/lib/lfcs/mock-results.log`, the schedule (10 Jan baseline, 16 Jan, 31 Jan). `practice-cli/README.md`: requirements (root inside a lab VM with the marker), quick start, menu, per-question layout, needs tags, the netns peer and loop-disk model, two-host questions, the generators, the question table from `--list`, the "never on a real host" warning.
- [ ] **Step 3: Verify** `bash scripts/check-docs.sh lfcs` → `ALL OK`; `grep -c '^### Task' lfcs/mock-exams/mock-1.md` → 18.
- [ ] **Step 4: Commit** `feat(lfcs): mock exam sets and papers, CLI README`.

### Task 18: Phase 4 gate, smoke test in the VMs, PR

- [ ] **Step 1: Full check** `bash scripts/check-docs.sh; echo "exit=$?"` → `ALL OK`, `exit=0`; registry count 45.
- [ ] **Step 2: Owner smoke test** (record results in the commit message):
  1. In `lfcs-ubuntu`: `sudo ./lfcs --env` shows the marker, a spare disk or loop support, and at least 40 runnable questions.
  2. Run `[S]`, solve, `[V]`, `[C]` for Q4, Q17, Q23, Q25, Q30, Q41, Q45 (one per helper family: timer, netns firewall, loop disk, LVM online, NBD peer, users, LDAP). Every verifier fails before solving and passes after; every cleanup leaves `lsblk`, `ip netns list`, and `getent passwd` as before.
  3. In `lfcs-rocky`: `sudo ./lfcs --env`; run Q9 and Q17 (firewalld variant) end to end.
  4. Restore the `clean` snapshot and run `sudo ./lfcs --mock 1` end to end; score and per-domain table print; `[C]` cleans up.
  Fix every defect before the PR.
- [ ] **Step 3: Fill the lab-setup "which questions run where" table and the checklist drill column** from `--list`; commit `docs(lfcs): map the question bank into lab table and checklists`.
- [ ] **Step 4: Push and open the PR** (`gh pr create --base main --head lfcs --title "LFCS kit: lab, notes, plan, 45-question practice CLI, mocks"` with a body listing the deliverables and the smoke-test results, ending with the generated-with footer used in the CKS plans).

---

## Phase 5: roadmap, root docs, final verification (done by 13 Dec 2026)

### Task 19: Roadmap

**Files:**
- Create: `roadmap.md`

- [ ] **Step 1: Write** a single page: the two exam dates, the voucher expiry (owner to fill the exact dates), a month-by-month table from Sept 2026 to March 2027 merging both calendars, the booking checklist (CKS exam, LFCS exam, killer.sh activations with dates, KodeKloud), the mock and simulator dates, the retake windows, and links to `cks/study-plan/00-calendar.md` and `lfcs/study-plan/00-calendar.md`.
- [ ] **Step 2: Verify** `python3 scripts/generate_toc.py --inject roadmap.md && bash scripts/check-docs.sh roadmap.md` → `ALL OK`. **Commit** `docs: add combined CKS and LFCS roadmap`.

### Task 20: Root README and CLAUDE.md

**Files:**
- Modify: `README.md`, `CLAUDE.md`

- [ ] **Step 1: README**: certification table with CKA Passed, CKAD Passed, CKS In progress (exam 12 Dec 2026), LFCS In progress (exam 6 Feb 2027), KCNA and KCSA Planned; the structure tree including `cks/` and `lfcs/` subfolders, `docs/`, `scripts/`, `roadmap.md`; quick starts for all four CLIs; the verification section (`bash scripts/check-docs.sh`); the cheatsheet table extended with the CKS and LFCS cheatsheets.
- [ ] **Step 2: CLAUDE.md**: repository structure with `cks/`, `lfcs/`, `docs/`, `scripts/`; the practice CLI contract (per-question folder, `meta` keys, needs tags, generators, state directories, guards); the docs conventions (TOC markers, recipe format, one diagram per note); the workflow (branch per cert, `check-docs.sh` before every commit, PR per phase); key paths updated.
- [ ] **Step 3: Verify** `python3 scripts/generate_toc.py --check README.md && bash scripts/check-docs.sh` → `ALL OK`. **Commit** `docs: update root README and CLAUDE.md for the CKS and LFCS kits`.

### Task 21: Final gate and PR

- [ ] **Step 1** `bash scripts/check-docs.sh; echo "exit=$?"` → `ALL OK`, `exit=0`.
- [ ] **Step 2** `./cks/practice-cli/cks --list | grep -c '\[Q'` → 44; LFCS registry count → 45; `git status --short` empty.
- [ ] **Step 3** Push and open the Phase 5 PR (`roadmap, root README, CLAUDE.md`), merge after review, then `git checkout main && git pull`.

---

## Self-review against the spec

- §2 LFCS facts: Task 3 (note 00), Task 10 (plan and README).
- §4 layout: Tasks 1 to 2 (lab-setup), 3 to 10 (docs), 11 to 17 (CLI and mocks), 19 to 20 (root files); every folder in the spec tree has a creating task.
- §5 calendar: Task 10 matches the spec rows (13 Dec lab, foundation to 10 Jan with mock 1, drills with mock 2 on 16 Jan, killer.sh session 1 on 23 Jan, mock 3 on 31 Jan, session 2 on 3 Feb, exam 6 Feb).
- §6 LFCS VMs, safety marker, fallback: Tasks 1, 2, 11.
- §7 contracts, needs tags, env helpers (`make_loop_disk`, `free_loop_disk`, `make_netns_peer`, `backup_file`, `restore_file`, `require_root`, `require_distro`), mock mode, compatibility: Task 11 plus the copied harness.
- §8 bank: 11 + 11 + 9 + 9 + 5 = 45; every high-frequency family from the research has a question (iptables and nftables Q17, Q18, Q22; LVM Q24, Q25; OpenSSL Q33; containers Q8; NFS Q21; libvirt Q7; cron and timers Q3, Q4; systemd units Q10, Q11, Q38, Q40; sshd Q16; fstab by UUID Q23; netplan and nmcli Q12, Q13, Q19; SELinux Q9; users, sudo, ACLs Q41 to Q44; git Q32; swap Q26; disk-full Q31; NBD Q30; LDAP Q45).
- §9 notes, cheatsheets, compilation, plan files: Tasks 3 to 10; every one of the 34 curriculum bullets is assigned to a recipe in Tasks 4 to 8 (bullet numbers noted inline).
- §11 root README and CLAUDE.md: Task 20.
- §12 acceptance: Tasks 10 (owner builds the VMs from the guide), 18 (smoke test and mock), 21 (final check).
- Placeholder scan: none; the "which questions run where" table is filled in Task 18 Step 3 rather than left open.
- Name consistency: `require_root`, `require_lab_host`, `distro`, `require_distro`, `course_dir`, `spare_disk`, `make_loop_disk`, `free_loop_disk`, `make_netns_peer`, `del_netns_peer`, `in_peer`, `has_needs`, `backup_file`, `restore_file`, `pkg_install`, `LFCS_STATE_DIR`, `COURSE_DIR` are used with the same names in Tasks 11 to 18; the copied harness keeps `check_*`, `summary`, `kjp` (unused here), `get_question_*`, and `mark_complete`.
