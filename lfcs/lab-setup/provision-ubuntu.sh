#!/usr/bin/env bash
# Provision lfcs-ubuntu (Ubuntu 24.04) for the LFCS practice CLI. Run as root inside the VM.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root: sudo bash $0" >&2; exit 1; }
export DEBIAN_FRONTEND=noninteractive

echo "== updating package lists =="
apt-get update -q

echo "== installing the curriculum tool set =="
apt-get install -y -q \
  lvm2 mdadm cryptsetup xfsprogs parted gdisk quota acl attr tree \
  nfs-kernel-server nfs-common autofs nbd-client nbd-server \
  podman qemu-system-arm qemu-utils libvirt-daemon-system libvirt-clients virtinst \
  chrony git openssl sysstat nftables iptables ufw \
  sssd-ldap ldap-utils slapd bridge-utils tcpdump traceroute netcat-openbsd \
  curl wget vim bash-completion python3 at cron man-db manpages apparmor-utils

echo "== enabling the services questions rely on =="
for u in chrony atd cron libvirtd; do
  systemctl enable --now "$u" >/dev/null 2>&1 || echo "  note: could not enable $u"
done
# sysstat collects the data `sar` reads; off by default on Debian family.
sed -i 's/^ENABLED=.*/ENABLED="true"/' /etc/default/sysstat 2>/dev/null || true
systemctl enable --now sysstat >/dev/null 2>&1 || true
# slapd is only needed by the LDAP client question; leave it stopped until then.
systemctl disable --now slapd >/dev/null 2>&1 || true

echo "== loading the modules the storage questions need =="
modprobe loop 2>/dev/null || true
modprobe nbd 2>/dev/null || true
printf 'loop\nnbd\n' > /etc/modules-load.d/lfcs.conf

echo "== lab plumbing =="
usermod -aG libvirt,kvm lfcs 2>/dev/null || true
mkdir -p /opt/course /var/lib/lfcs
grep -q 'node2' /etc/hosts 2>/dev/null || printf '192.168.56.10 node1 node1.lab.local\n192.168.56.20 node2 node2.lab.local\n' >> /etc/hosts
[[ -f /root/.ssh/id_ed25519 ]] || { mkdir -p /root/.ssh; chmod 700 /root/.ssh; ssh-keygen -q -t ed25519 -N '' -f /root/.ssh/id_ed25519; }

echo "ubuntu $(date -Is)" > /etc/lfcs-lab

cat <<'DONE'

LFCS lab marker written: /etc/lfcs-lab
The practice CLI refuses to run without it, which is what keeps these questions
away from a machine you care about.

Spare block devices found:
DONE
lsblk -dpno NAME,SIZE,TYPE | awk '$3=="disk"' | sed 's/^/  /'
cat <<'NEXT'

For the two-host questions (NFS, NBD), copy this key to the other VM:
  ssh-copy-id -i /root/.ssh/id_ed25519.pub root@node2
Then snapshot the VM as "clean" before you start practising.
NEXT
