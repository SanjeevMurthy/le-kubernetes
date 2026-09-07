#!/bin/bash
# Q42 users, sudo and modules: create the contractor account, its sudo drop-in
# and its group on the worker, and load the sctp module when the kernel has one.
# Everything setup creates is recorded in the state directory so that cleanup
# can undo exactly that and nothing else.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kubectl

USERNAME=tempadmin
GROUP=lab-ops
SUDOERS=/etc/sudoers.d/tempadmin
BLACKLIST=/etc/modprobe.d/blacklist-sctp.conf
STATE="$CKS_STATE_DIR/q42.state"

W=$(worker_node)
[[ -n "$W" ]] || { echo "no worker node found"; exit 1; }

# What a previous run of this setup created, so a second run resets the lab
# instead of refusing, and cleanup never removes something it did not create.
sget() { if [[ -f "$STATE" ]]; then sed -n "s/^$1=//p" "$STATE" | head -1; fi; return 0; }
PREV_USER=$(sget user)
PREV_GROUP=$(sget group)
PREV_SUDOERS=$(sget sudoers)
PREV_BLACKLIST=$(sget blacklist)
PREV_SCTP=$(sget sctp)

# Backs up the local copy for the common case of running this on the worker.
# The remote script keeps its own copy of a pre-existing drop-in.
backup_file "$SUDOERS" q42

TMP=$(mktemp)
{
  echo "PREV_USER=$PREV_USER"
  echo "PREV_GROUP=$PREV_GROUP"
  echo "PREV_SUDOERS=$PREV_SUDOERS"
  echo "PREV_BLACKLIST=$PREV_BLACKLIST"
  echo "PREV_SCTP=$PREV_SCTP"
  cat <<'REMOTE'
set -e
USERNAME=tempadmin
GROUP=lab-ops
SUDOERS=/etc/sudoers.d/tempadmin
BLACKLIST=/etc/modprobe.d/blacklist-sctp.conf
BAK=/root/q42-sudoers-tempadmin.bak
MARK='# CKS practice CLI q42 lab drop-in'

if id "$USERNAME" >/dev/null 2>&1; then
  if [ "$PREV_USER" != created ]; then
    echo "user $USERNAME already exists on $(hostname) and was not created by this question."
    echo "Refusing to modify a real account. Run this on a disposable lab node."
    exit 1
  fi
else
  useradd -m -s /bin/bash "$USERNAME"
fi
USER_STATE=created

# A usable password, so that `passwd -S` reports P now and L only after the
# candidate locks it. A fresh account has no password at all, which already
# reads as L and would make the check pass before anything was done.
echo "$USERNAME:Cks-Lab-42" | chpasswd || { echo "could not set a password for $USERNAME on $(hostname); the account state would be wrong"; exit 1; }
usermod -s /bin/bash "$USERNAME"

if getent group "$GROUP" >/dev/null 2>&1; then
  if [ "$PREV_GROUP" = created ]; then GROUP_STATE=created; else GROUP_STATE=pre; fi
else
  groupadd "$GROUP"
  GROUP_STATE=created
fi
usermod -aG "$GROUP" "$USERNAME"

if [ -f "$SUDOERS" ] && ! grep -qF "$MARK" "$SUDOERS"; then
  cp -p "$SUDOERS" "$BAK"
  SUDOERS_STATE=pre
elif [ "$PREV_SUDOERS" = pre ]; then
  SUDOERS_STATE=pre
else
  SUDOERS_STATE=created
fi
printf '%s\n%s ALL=(ALL) NOPASSWD:ALL\n' "$MARK" "$USERNAME" > "$SUDOERS"
chmod 0440 "$SUDOERS"
if command -v visudo >/dev/null 2>&1; then
  visudo -cf "$SUDOERS" >/dev/null || { echo "the sudo drop-in did not validate; removing it again"; rm -f "$SUDOERS"; exit 1; }
fi

# A blacklist file left behind by a previous solve is removed, so the module
# can be loaded again and the lab starts where it is supposed to.
if [ -f "$BLACKLIST" ]; then
  if [ "$PREV_BLACKLIST" = absent ]; then rm -f "$BLACKLIST"; BL_STATE=absent; else BL_STATE=pre; fi
else
  BL_STATE=absent
fi

# A module that was already on the node before this question ran stays recorded
# as preloaded, so a second setup run never turns it into something cleanup
# would unload.
if lsmod | awk '{print $1}' | grep -qx sctp; then
  if [ "$PREV_SCTP" = loaded ]; then SCTP_STATE=loaded; else SCTP_STATE=preloaded; fi
elif modinfo sctp >/dev/null 2>&1 && modprobe sctp >/dev/null 2>&1 && lsmod | awk '{print $1}' | grep -qx sctp; then
  if [ "$PREV_SCTP" = preloaded ]; then SCTP_STATE=preloaded; else SCTP_STATE=loaded; fi
else
  SCTP_STATE=unavailable
fi

echo "state:user=$USER_STATE"
echo "state:group=$GROUP_STATE"
echo "state:sudoers=$SUDOERS_STATE"
echo "state:blacklist=$BL_STATE"
echo "state:sctp=$SCTP_STATE"
echo "seeded on $(hostname)"
REMOTE
} > "$TMP"

OUT=$(on_worker bash -s < "$TMP") || {
  rm -f "$TMP"
  echo "Setup failed on $W. Nothing was left half-configured; read the message above."
  exit 1
}
rm -f "$TMP"

echo "$OUT" | grep -v '^state:' || true
echo "$OUT" | sed -n 's/^state://p' > "$STATE"
SCTP=$(sed -n 's/^sctp=//p' "$STATE" | head -1)

echo "Setup complete."
echo "  Worker node:   $W"
echo "  Account:       $USERNAME, shell /bin/bash, password set and unlocked"
echo "  Sudo:          $SUDOERS grants NOPASSWD:ALL"
echo "  Group:         $USERNAME is a member of $GROUP"
case "$SCTP" in
  loaded)      echo "  Kernel module: sctp was loaded by this setup and is graded" ;;
  preloaded)   echo "  Kernel module: sctp was already loaded on this node and is graded" ;;
  *)           echo "  Kernel module: this kernel has no sctp module, so step 4 is not graded here" ;;
esac
echo "  Blacklist path the question asks for: $BLACKLIST"
echo "  State recorded in: $STATE"
echo "  Look around with: ssh $W 'id $USERNAME; sudo -l -U $USERNAME; lsmod | grep sctp'"
