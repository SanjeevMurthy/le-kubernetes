#!/usr/bin/env bash
# LFCS environment: privilege and lab guards, distribution detection, needs tags,
# loop-backed disks, a network-namespace peer host, and file backup and restore.
# Source it; do not execute it.

LFCS_STATE_DIR="${LFCS_STATE_DIR:-/var/lib/lfcs}"
COURSE_DIR="${COURSE_DIR:-/opt/course}"
export LFCS_STATE_DIR COURSE_DIR

# ─── privilege and safety ──────────────────────────────────────────
# These questions create users, repartition disks, rewrite firewall rules and
# restart services. Both guards below exist so that can only happen in the lab.
require_root() {
  if [[ $EUID -ne 0 ]]; then
    exec sudo -E "$0" "$@"
  fi
  mkdir -p "$LFCS_STATE_DIR/backup" "$LFCS_STATE_DIR/disks" "$COURSE_DIR" 2>/dev/null
}

require_lab_host() {
  [[ "${LFCS_ALLOW_HOST:-0}" == "1" ]] && return 0
  [[ -f /etc/lfcs-lab ]] && return 0
  echo "Refusing to run: /etc/lfcs-lab is missing."
  echo "This CLI creates users, repartitions disks, rewrites firewall rules and restarts services."
  echo "Run it only inside the lab VMs, which the provisioning scripts mark, or set LFCS_ALLOW_HOST=1"
  echo "if you are certain this machine is disposable."
  return 1
}

# ─── distribution ──────────────────────────────────────────────────
distro() {
  # shellcheck disable=SC1091
  [[ -r /etc/os-release ]] && . /etc/os-release
  case "${ID:-}" in
    ubuntu|debian)                     echo ubuntu ;;
    rocky|rhel|centos|almalinux|fedora) echo rocky ;;
    *)                                 echo "${ID:-unknown}" ;;
  esac
}

require_distro() {
  [[ "$(distro)" == "$1" ]] && return 0
  echo "This question runs on $1 only; this host is $(distro)."
  return 1
}

pkg_install() {
  if [[ "$(distro)" == ubuntu ]]; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$@" >/dev/null
  else
    dnf install -y -q "$@" >/dev/null
  fi
}

course_dir() { mkdir -p "$COURSE_DIR/$1" && echo "$COURSE_DIR/$1"; }

# ─── block devices ─────────────────────────────────────────────────
# Prefer a real spare disk, because lsblk then behaves exactly as it does in the
# exam. Fall back to a loop-backed file so a single-disk VM still works.
spare_disk() {
  local d
  for d in $(lsblk -dpno NAME,TYPE | awk '$2=="disk" {print $1}'); do
    if [[ -z "$(lsblk -no FSTYPE "$d" | tr -d ' \n')" ]] &&
       [[ -z "$(lsblk -no MOUNTPOINT "$d" | tr -d ' \n')" ]] &&
       [[ "$(lsblk -no NAME "$d" | wc -l | tr -d ' ')" -eq 1 ]]; then
      echo "$d"
      return 0
    fi
  done
  return 1
}

make_loop_disk() {   # make_loop_disk name sizeMB  -> prints /dev/loopN
  local name="$1" size="$2" img="$LFCS_STATE_DIR/disks/$1.img" dev
  mkdir -p "$LFCS_STATE_DIR/disks"
  dev=$(losetup -j "$img" 2>/dev/null | cut -d: -f1 | head -1)
  if [[ -z "$dev" ]]; then
    [[ -f "$img" ]] || truncate -s "${size}M" "$img"
    dev=$(losetup -fP --show "$img") || return 1
  fi
  echo "$dev"
}

free_loop_disk() {   # free_loop_disk name
  local img="$LFCS_STATE_DIR/disks/$1.img" dev
  for dev in $(losetup -j "$img" 2>/dev/null | cut -d: -f1); do
    wipefs -aq "$dev" 2>/dev/null
    losetup -d "$dev" 2>/dev/null
  done
  rm -f "$img"
  return 0
}

# ─── a second host, without a second VM ────────────────────────────
# NFS, NBD, routing and firewall questions need a peer. A network namespace on
# the far end of a veth pair is one, and it costs nothing to create or destroy.
make_netns_peer() {   # make_netns_peer name octet [http|sshd|nfs] -> prints the peer IP
  local ns="$1" n="$2" svc="${3:-}" h="veth-$1" p="veth-$1-p"
  ip netns list 2>/dev/null | grep -qw "$ns" || ip netns add "$ns"
  if ! ip link show "$h" >/dev/null 2>&1; then
    ip link add "$h" type veth peer name "$p"
    ip link set "$p" netns "$ns"
  fi
  ip addr replace "10.99.$n.1/24" dev "$h"
  ip link set "$h" up
  ip netns exec "$ns" ip addr replace "10.99.$n.2/24" dev "$p"
  ip netns exec "$ns" ip link set "$p" up
  ip netns exec "$ns" ip link set lo up
  ip netns exec "$ns" ip route replace default via "10.99.$n.1" 2>/dev/null
  case "$svc" in
    http)
      mkdir -p "$LFCS_STATE_DIR/$ns/www"
      echo "peer-ok" > "$LFCS_STATE_DIR/$ns/www/index.html"
      ip netns exec "$ns" sh -c "cd '$LFCS_STATE_DIR/$ns/www' && nohup python3 -m http.server 80 --bind 10.99.$n.2 >/dev/null 2>&1 &"
      ;;
    sshd)
      mkdir -p "$LFCS_STATE_DIR/$ns"
      [[ -f "$LFCS_STATE_DIR/$ns/hostkey" ]] || ssh-keygen -q -t ed25519 -N '' -f "$LFCS_STATE_DIR/$ns/hostkey"
      ip netns exec "$ns" /usr/sbin/sshd -h "$LFCS_STATE_DIR/$ns/hostkey" \
        -o "ListenAddress=10.99.$n.2" -o "PidFile=$LFCS_STATE_DIR/$ns/sshd.pid" 2>/dev/null
      ;;
  esac
  echo "10.99.$n.2"
}

del_netns_peer() {
  local ns="$1"
  ip netns pids "$ns" 2>/dev/null | xargs -r kill 2>/dev/null
  ip link del "veth-$ns" 2>/dev/null
  ip netns del "$ns" 2>/dev/null
  rm -rf "${LFCS_STATE_DIR:?}/$ns"
  return 0
}

in_peer() { ip netns exec "$1" "${@:2}"; }   # in_peer name cmd...

# ─── needs tags ────────────────────────────────────────────────────
has_needs() {
  local n
  for n in $1; do
    case "$n" in
      ""|none) ;;
      linux)   [[ "$(uname -s)" == Linux ]] || return 1 ;;
      disk)    spare_disk >/dev/null 2>&1 || losetup -f >/dev/null 2>&1 || return 1 ;;
      netns)   ip netns add lfcs-probe 2>/dev/null && ip netns del lfcs-probe 2>/dev/null || return 1 ;;
      host2)   ssh -o BatchMode=yes -o ConnectTimeout=3 node2 true >/dev/null 2>&1 || return 1 ;;
      nic2)    [[ "$(ip -o link 2>/dev/null | awk -F': ' '{print $2}' | grep -Evc '^(lo|docker|veth|virbr|br-|podman|cni)')" -ge 2 ]] || return 1 ;;
      rocky)   [[ "$(distro)" == rocky ]] || return 1 ;;
      ubuntu)  [[ "$(distro)" == ubuntu ]] || return 1 ;;
      virt)    command -v virsh >/dev/null 2>&1 && systemctl is-active libvirtd >/dev/null 2>&1 || return 1 ;;
      tool:*)  command -v "${n#tool:}" >/dev/null 2>&1 || return 1 ;;
      *)       echo "unknown need tag: $n" >&2; return 1 ;;
    esac
  done
  return 0
}

# ─── file backups ──────────────────────────────────────────────────
backup_file() {
  local f="$1" q="$2" b
  mkdir -p "$LFCS_STATE_DIR/backup/$q"
  b="$LFCS_STATE_DIR/backup/$q/$(echo "$f" | tr / _)"
  [[ -f "$f" && ! -f "$b" ]] && cp -p "$f" "$b"
  return 0
}

# Remove this question's own lines from /etc/fstab, matching on either the
# source or the mount point.
#
# Cleanups must never restore a whole-file snapshot of /etc/fstab. Several
# storage questions can be set up at once, most obviously during a mock exam,
# and a snapshot taken when this question was set up does not know about the
# lines the others added since. Restoring it deletes their mounts, and a later
# cleanup restoring its own newer snapshot puts this question's line back,
# pointing at a device that no longer exists. A wrong /etc/fstab stops the next
# boot, which is the one failure this lab must not cause on purpose.
#
# So: take the line out, leave every other line alone. The backup_file copy
# stays on disk as a reference if a candidate ever needs to see the original.
# FSTAB is an override for the unit tests only; questions never set it.
fstab_drop_target() {   # fstab_drop_target /mount/point   (or the source field)
  local t="$1" f="${FSTAB:-/etc/fstab}" tmp
  [[ -n "$t" && -f "$f" ]] || return 0
  mkdir -p "$LFCS_STATE_DIR"
  tmp="$LFCS_STATE_DIR/fstab.$$"
  if awk -v t="$t" '$1 ~ /^[[:space:]]*#/ || ($1 != t && $2 != t)' "$f" > "$tmp"; then
    cat "$tmp" > "$f"
  fi
  rm -f "$tmp"
  return 0
}
restore_file() {
  local f="$1" q="$2" b
  b="$LFCS_STATE_DIR/backup/$q/$(echo "$f" | tr / _)"
  if [[ -f "$b" ]]; then cp -p "$b" "$f" && rm -f "$b"; fi
  return 0
}

# ─── persistence helper ────────────────────────────────────────────
# The exam's defining rule is that a change must survive a reboot. Verifiers use
# this to state plainly which file was expected to carry the change.
check_persisted() {   # check_persisted "label" 'extended-regex' file [file...]
  local label="$1" pat="$2"
  shift 2
  local f
  for f in "$@"; do
    if [[ -f "$f" ]] && grep -Eq -- "$pat" "$f"; then
      echo "  PASS: $label (persisted in $f)"
      PASS=$((PASS + 1))
      return 0
    fi
  done
  echo "  FAIL: $label (not found in: $*; the change will not survive a reboot)"
  FAIL=$((FAIL + 1))
  return 1
}
