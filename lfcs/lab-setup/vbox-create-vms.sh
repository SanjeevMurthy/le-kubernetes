#!/usr/bin/env bash
# Create the two LFCS VirtualBox VMs on Apple Silicon (arm64 guests only).
# Run on the Mac, not inside a VM. Safe to re-run: it skips anything that exists.
set -euo pipefail

VMDIR="${VMDIR:-$HOME/VirtualBox VMs}"
UBUNTU_ISO="${UBUNTU_ISO:-}"
ROCKY_ISO="${ROCKY_ISO:-}"

command -v VBoxManage >/dev/null 2>&1 || {
  echo "VBoxManage not found. Install VirtualBox first: brew install --cask virtualbox" >&2
  exit 1
}

# Find the installer images unless they were passed in.
[[ -n "$UBUNTU_ISO" ]] || UBUNTU_ISO=$(ls -1 "$HOME"/Downloads/ubuntu-24.04*-live-server-arm64.iso 2>/dev/null | head -1 || true)
[[ -n "$ROCKY_ISO"  ]] || ROCKY_ISO=$(ls -1 "$HOME"/Downloads/Rocky-9*-aarch64-minimal.iso 2>/dev/null | head -1 || true)

# VirtualBox names its ARM guest types differently across releases, so ask.
ostype_for() {
  local want="$1" found
  found=$(VBoxManage list ostypes | awk -v w="$want" '/^ID:/ && tolower($2) ~ tolower(w) {print $2}' | grep -i arm | head -1)
  [[ -n "$found" ]] || found=$(VBoxManage list ostypes | awk -v w="$want" '/^ID:/ && tolower($2) ~ tolower(w) {print $2}' | head -1)
  echo "${found:-Linux_arm64}"
}

if ! VBoxManage list hostonlynets 2>/dev/null | grep -q '^Name: *lfcsnet$'; then
  VBoxManage hostonlynet add --name lfcsnet --netmask 255.255.255.0 \
    --lower-ip 192.168.56.100 --upper-ip 192.168.56.200 --enable
  echo "created host-only network lfcsnet"
else
  echo "host-only network lfcsnet already exists"
fi

create_vm() {  # name ostype memory_mb root_gb spare_count
  local name="$1" ostype="$2" mem="$3" disk="$4" spares="$5" i
  if VBoxManage showvminfo "$name" >/dev/null 2>&1; then
    echo "$name already exists, skipping"
    return 0
  fi
  VBoxManage createvm --name "$name" --ostype "$ostype" --register --platform-architecture arm 2>/dev/null \
    || VBoxManage createvm --name "$name" --ostype "$ostype" --register
  VBoxManage modifyvm "$name" --cpus 2 --memory "$mem" \
    --nic1 nat --nic2 hostonlynet --host-only-net2 lfcsnet \
    --boot1 dvd --boot2 disk --graphicscontroller vmsvga
  VBoxManage storagectl "$name" --name SCSI --add virtio-scsi --controller VirtIO --bootable on
  mkdir -p "$VMDIR/$name"
  VBoxManage createmedium disk --filename "$VMDIR/$name/$name.vdi" --size $(( disk * 1024 )) >/dev/null
  VBoxManage storageattach "$name" --storagectl SCSI --port 0 --device 0 --type hdd \
    --medium "$VMDIR/$name/$name.vdi"
  for i in $(seq 1 "$spares"); do
    VBoxManage createmedium disk --filename "$VMDIR/$name/$name-spare$i.vdi" --size 2048 >/dev/null
    VBoxManage storageattach "$name" --storagectl SCSI --port "$i" --device 0 --type hdd \
      --medium "$VMDIR/$name/$name-spare$i.vdi"
  done
  echo "created $name: 2 vCPU, ${mem} MB, ${disk} GB root, $spares spare disk(s), 2 NICs"
}

create_vm lfcs-ubuntu "$(ostype_for ubuntu)" 4096 25 3
create_vm lfcs-rocky  "$(ostype_for 'red\|rocky')" 2048 12 2

attach_iso() {  # name iso
  local name="$1" iso="$2"
  if [[ -z "$iso" || ! -f "$iso" ]]; then
    echo "no installer image found for $name; attach it in the GUI, or rerun with UBUNTU_ISO=... ROCKY_ISO=..."
    return 0
  fi
  VBoxManage storageattach "$name" --storagectl SCSI --port 9 --device 0 --type dvddrive --medium "$iso" \
    && echo "attached $(basename "$iso") to $name"
}
attach_iso lfcs-ubuntu "$UBUNTU_ISO"
attach_iso lfcs-rocky  "$ROCKY_ISO"

cat <<'NEXT'

Next steps:
  1. Start each VM from the VirtualBox GUI and install the OS.
     Username lfcs. On Ubuntu tick "Install OpenSSH server". On Rocky choose Minimal Install.
     Give the host-only interface 192.168.56.10 (ubuntu) and 192.168.56.20 (rocky).
  2. Copy in and run the provisioning script for each VM.
  3. Take a snapshot named "clean" on both before any practice.
NEXT
