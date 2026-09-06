# LFCS Exam Cheatsheet

One page for the morning of the exam. Everything here is in the notes; this is the compressed form.

<!-- toc -->
## Table of Contents

- [The rule that decides the outcome](#the-rule-that-decides-the-outcome)
- [Never block these](#never-block-these)
- [First thirty seconds on a host](#first-thirty-seconds-on-a-host)
- [Users and groups](#users-and-groups)
- [Storage](#storage)
- [Services, timers and jobs](#services-timers-and-jobs)
- [Networking](#networking)
- [Containers, VMs, SELinux](#containers-vms-selinux)
- [Files, text and certificates](#files-text-and-certificates)
- [Validate before you restart](#validate-before-you-restart)
- [Ubuntu vs Rocky](#ubuntu-vs-rocky)
- [Time plan](#time-plan)
- [The eight that fail people](#the-eight-that-fail-people)

<!-- toc stop -->

## The rule that decides the outcome

**A change that does not survive a reboot scores zero.** Before leaving any task, name the file that persists it.

| You ran | The mark lives in |
|---|---|
| `ip addr add`, `ip route add` | a netplan YAML, or `nmcli con mod ... ipv4.method manual` |
| `sysctl -w` | `/etc/sysctl.d/90-x.conf`, then `sysctl --system` |
| `mount` | `/etc/fstab`, checked with `findmnt --verify` and `mount -a` |
| `swapon` | `/etc/fstab`, with `pri=` if a priority was asked for |
| `nft add rule` | `/etc/nftables.conf` (Ubuntu) or `/etc/sysconfig/nftables.conf` (Rocky), plus `systemctl enable nftables` |
| `firewall-cmd --add-*` | the same command with `--permanent`, then `--reload` |
| `ufw allow` | `ufw enable`, which persists on its own |
| `systemctl start` | `systemctl enable`, or `enable --now` for both |
| `cryptsetup luksOpen` | `/etc/crypttab` |
| `mdadm --create` | an `ARRAY` line in mdadm.conf, then rebuild the initramfs |
| edited `/etc/exports` | `exportfs -ra` |
| `setsebool` | `setsebool -P` |
| `modprobe x` | `/etc/modules-load.d/x.conf` |

## Never block these

**8080/tcp, 4505/tcp, 4506/tcp.** Blocking any of them ends the exam session. Write the allow rules before the drop policy.

## First thirty seconds on a host

```bash
ssh <nodename> ; sudo -i ; hostname ; cat /etc/os-release
```

## Users and groups

```bash
groupadd -g 3001 devs
useradd -u 2001 -g devs -G wheel -s /bin/bash -m -c 'Ana' -e 2027-06-30 ana
usermod -aG ops ana              # -a or you REPLACE the group list
usermod -L ana                   # lock;  -U unlocks
useradd -r -s /usr/sbin/nologin svc-batch
userdel -r olduser               # -r removes the home directory
chage -M 60 -m 7 -W 14 ana       # max, min, warn
chage -E 2027-06-30 ana          # expiry
passwd -S ana                    # L locked, P usable, NP no password

echo 'ana ALL=(ALL) ALL'                              > /etc/sudoers.d/ana
echo '%ops ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx' > /etc/sudoers.d/ops
visudo -c                        # ALWAYS, before you log out

setfacl -m u:ana:rwx /srv/projects
setfacl -m d:g:qa:r-x /srv/projects      # d: = default, inherited by new files
setfacl -x u:ana /srv/projects
getfacl -p /srv/projects
chmod 2770 /srv/shared           # 2 = SGID, files inherit the group
chmod 1777 /tmp-like             # 1 = sticky, only the owner deletes
```

Verify: `getent passwd ana`, `id ana`, `chage -l ana`, `sudo -l -U ana`, `stat -c '%a %U:%G' f`.

## Storage

```bash
lsblk -f                                   # the map
parted -s /dev/sdb mklabel gpt
parted -s /dev/sdb mkpart primary ext4 1MiB 100%
mkfs.ext4 -L data /dev/sdb1
blkid -s UUID -o value /dev/sdb1

pvcreate /dev/sdb ; vgcreate -s 16M vg_data /dev/sdb ; lvcreate -L 1.5G -n lv_app vg_data
vgextend vg_data /dev/sdc
lvextend -r -L +400M /dev/vg_data/lv_app   # -r grows the filesystem too
resize2fs /dev/vg/lv                       # ext: takes the DEVICE
xfs_growfs /mnt                            # xfs: takes the MOUNT POINT, never shrinks

fallocate -l 512M /swapfile2 ; chmod 600 /swapfile2 ; mkswap /swapfile2 ; swapon -p 10 /swapfile2
mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sdb /dev/sdc
cryptsetup luksFormat /dev/sdb1 ; cryptsetup luksOpen /dev/sdb1 secret
```

fstab fields: `device  mountpoint  type  options  dump  fsckpass`. Use `UUID=`. Add `_netdev` for network mounts, `nofail` for anything non-essential.

Verify: `findmnt --verify`, `mount -a`, `findmnt -no OPTIONS /m`, `swapon --show`, `lvs`, `df -hT`, `df -i`, `lsof +L1`.

## Services, timers and jobs

```ini
# /etc/systemd/system/app.service
[Unit]
Description=App
After=network-online.target

[Service]
Type=simple
User=app
ExecStart=/opt/app/run.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```ini
# /etc/systemd/system/app.timer
[Timer]
OnCalendar=*:0/15
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
systemctl daemon-reload ; systemctl enable --now app.timer
systemctl edit app          # a drop-in, rather than editing the unit
systemctl mask legacy       # stronger than disable
systemctl list-timers --no-pager
crontab -e -u backupop      # min hour dom mon dow  command
echo /usr/local/bin/x | at 23:00 ; atq
journalctl -u app -b --no-pager ; journalctl -b -1 -p err
```

Verify: `systemctl is-active`, `is-enabled`, `systemctl show -p LimitNOFILE app`, `crontab -l -u user`.

## Networking

```bash
ip -br a ; ip r ; ss -H -ltnp ; resolvectl status
hostnamectl set-hostname node1.lab.local
timedatectl set-timezone Asia/Kolkata ; chronyc sources -v

# Ubuntu: /etc/netplan/01-x.yaml, then: netplan try   (auto-reverts in 120s)
# Rocky:
nmcli con mod eth1 ipv4.addresses 192.168.56.20/24 ipv4.method manual
nmcli con mod eth1 +ipv4.routes "10.200.0.0/16 192.168.56.1"
nmcli con up eth1

nft add table inet filter
nft add chain inet filter input '{ type filter hook input priority 0; policy drop; }'
nft add rule inet filter input ct state established,related accept
nft add rule inet filter input tcp dport { 22, 80, 443, 8080, 4505, 4506 } accept
nft list ruleset > /etc/nftables.conf ; systemctl enable --now nftables

nft add table ip nat
nft add chain ip nat prerouting '{ type nat hook prerouting priority -100; }'
nft add rule ip nat prerouting tcp dport 8081 redirect to :8080

firewall-cmd --permanent --add-service=http ; firewall-cmd --reload ; firewall-cmd --list-all
ufw allow 22/tcp ; ufw enable ; ufw status numbered
```

sshd: edit, then **`sshd -t` before restarting**. `sshd -T | grep -i permitrootlogin` shows what is effective. `Match` blocks go last.

## Containers, VMs, SELinux

```bash
podman run -d --name web -p 8080:80 -m 256m --restart=always \
  -v /srv/web:/usr/share/nginx/html:ro,Z nginx:1.27
podman inspect web --format '{{.HostConfig.Memory}}'
podman generate systemd --new --name web > /etc/systemd/system/container-web.service

virt-install --name labvm --memory 512 --vcpus 1 --disk /var/lib/libvirt/images/lab.qcow2 \
  --import --os-variant generic --virt-type qemu --noautoconsole
virsh autostart labvm ; virsh dominfo labvm ; virsh domblklist labvm

getenforce
semanage fcontext -a -t httpd_sys_content_t "/srv/site(/.*)?" ; restorecon -Rv /srv/site
semanage port -a -t http_port_t -p tcp 8081
setsebool -P httpd_can_network_connect on
ausearch -m avc -ts recent
```

## Files, text and certificates

```bash
find /data -user ana -size +1M -mtime -7 -exec cp -p {} /found/ \;
find /usr/bin -perm -4000                       # SUID
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -5
sed -i 's,http://,https://,g' urls.txt
tar czf p.tar.gz --exclude='*.tmp' project/ ; tar xJf b.tar.xz -C /extracted
ln -s /target link ; ln /file /hardlink ; stat -c %i /file

openssl x509 -in cert.pem -noout -subject -enddate -issuer
openssl req -x509 -newkey rsa:2048 -nodes -keyout k.pem -out c.pem -days 365 -subj "/CN=lab.local"
openssl s_client -connect host:443 -servername host </dev/null 2>/dev/null | openssl x509 -noout -dates
```

## Validate before you restart

```bash
findmnt --verify        # fstab
sshd -t                 # sshd_config
visudo -c               # sudoers
nginx -t                # nginx
nft -c -f /etc/nftables.conf
```

## Ubuntu vs Rocky

| | Ubuntu | Rocky |
|---|---|---|
| Packages | `apt`, `dpkg` | `dnf`, `rpm` |
| Network | netplan | `nmcli` |
| Firewall | `ufw` or `nft` | `firewalld` |
| MAC | AppArmor | SELinux |
| NFS server | `nfs-kernel-server` | `nfs-utils` / `nfs-server` |
| Time service | `chrony` | `chronyd` |
| Cron service | `cron` | `crond` |
| mdadm config | `/etc/mdadm/mdadm.conf` | `/etc/mdadm.conf` |
| Rebuild initramfs | `update-initramfs -u` | `dracut -f` |

## Time plan

18 tasks, 120 minutes, 67 percent, so about 12 right.

| Minute | What |
|---|---|
| 0 to 3 | Skim every task. Note confidence and host. Order the work. |
| 3 to 105 | Quick tasks first, **firewall and networking last**. About 6 minutes each; flag at 8. |
| 105 to 120 | Verify. Re-ask the reboot question. Confirm every deliverable file exists. |

## The eight that fail people

1. A change that did not survive a reboot. 2. The wrong host. 3. Starting with the hardest task. 4. Blocking an exam port. 5. Editing `/etc/sudoers` directly. 6. Restarting before validating. 7. Hunting for a man page instead of `man -k`. 8. Not verifying.
