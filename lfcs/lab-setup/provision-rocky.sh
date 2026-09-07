#!/usr/bin/env bash
# Provision lfcs-rocky (Rocky Linux 9) for the LFCS practice CLI. Run as root inside the VM.
# This VM exists for the RHEL-family half of the curriculum: SELinux, firewalld, nmcli, dnf.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root: sudo bash $0" >&2; exit 1; }

echo "== enabling EPEL =="
dnf install -y -q epel-release || echo "  note: EPEL unavailable, continuing"

echo "== installing the curriculum tool set =="
dnf install -y -q \
  lvm2 mdadm cryptsetup xfsprogs parted gdisk quota acl attr tree \
  nfs-utils autofs nbd \
  podman qemu-kvm libvirt virt-install \
  chrony git openssl sysstat nftables iptables-nft firewalld \
  policycoreutils-python-utils setools-console \
  sssd-ldap openldap-clients tcpdump traceroute nmap-ncat \
  curl wget vim bash-completion python3 at cronie man-db man-pages

echo "== enabling the services questions rely on =="
for u in chronyd atd crond libvirtd firewalld; do
  systemctl enable --now "$u" >/dev/null 2>&1 || echo "  note: could not enable $u"
done
systemctl enable --now sysstat >/dev/null 2>&1 || true

echo "== loading the modules the storage questions need =="
modprobe loop 2>/dev/null || true
modprobe nbd 2>/dev/null || true
printf 'loop\nnbd\n' > /etc/modules-load.d/lfcs.conf

echo "== lab plumbing =="
usermod -aG libvirt lfcs 2>/dev/null || true
mkdir -p /opt/course /var/lib/lfcs
grep -q 'node1' /etc/hosts 2>/dev/null || printf '192.168.56.10 node1 node1.lab.local\n192.168.56.20 node2 node2.lab.local\n' >> /etc/hosts
[[ -f /root/.ssh/id_ed25519 ]] || { mkdir -p /root/.ssh; chmod 700 /root/.ssh; ssh-keygen -q -t ed25519 -N '' -f /root/.ssh/id_ed25519; }

echo "rocky $(date -Is)" > /etc/lfcs-lab

echo ""
echo "SELinux mode: $(getenforce)"
if [[ "$(getenforce)" != "Enforcing" ]]; then
  echo "  The SELinux questions need Enforcing. Set SELINUX=enforcing in /etc/selinux/config and reboot."
fi
echo ""
echo "LFCS lab marker written: /etc/lfcs-lab"
echo "Spare block devices found:"
lsblk -dpno NAME,SIZE,TYPE | awk '$3=="disk"' | sed 's/^/  /'
echo ""
echo "Snapshot this VM as \"clean\" before you start practising."
