#!/bin/bash
# Q42 users, sudo and modules: undo exactly what setup recorded creating, and
# leave anything that was already on the node alone.
source "$(dirname "$0")/../../lib/env.sh"

SUDOERS=/etc/sudoers.d/tempadmin
BLACKLIST=/etc/modprobe.d/blacklist-sctp.conf
STATE="$CKS_STATE_DIR/q42.state"

sget() { if [[ -f "$STATE" ]]; then sed -n "s/^$1=//p" "$STATE" | head -1; fi; return 0; }

if [[ ! -f "$STATE" ]]; then
  echo "No state file at $STATE, so this cleanup does not know what setup created."
  echo "Nothing on the worker is removed. Check tempadmin, lab-ops and the sctp module by hand."
fi

restore_file "$SUDOERS" q42

TMP=$(mktemp)
{
  echo "USER_STATE=$(sget user)"
  echo "GROUP_STATE=$(sget group)"
  echo "SUDOERS_STATE=$(sget sudoers)"
  echo "BL_STATE=$(sget blacklist)"
  echo "SCTP_STATE=$(sget sctp)"
  cat <<'REMOTE'
USERNAME=tempadmin
GROUP=lab-ops
SUDOERS=/etc/sudoers.d/tempadmin
BLACKLIST=/etc/modprobe.d/blacklist-sctp.conf
BAK=/root/q42-sudoers-tempadmin.bak

if [ "$SUDOERS_STATE" = pre ] && [ -f "$BAK" ]; then
  cp -p "$BAK" "$SUDOERS"
  rm -f "$BAK"
elif [ "$SUDOERS_STATE" = created ]; then
  rm -f "$SUDOERS"
fi

if [ "$USER_STATE" = created ] && id "$USERNAME" >/dev/null 2>&1; then
  pkill -u "$USERNAME" 2>/dev/null || true
  userdel -r "$USERNAME" 2>/dev/null || userdel "$USERNAME" 2>/dev/null || true
fi

if [ "$GROUP_STATE" = created ] && getent group "$GROUP" >/dev/null 2>&1; then
  groupdel "$GROUP" 2>/dev/null || true
fi

# Only the path the question names. A blacklist written anywhere else was not
# created here and is not this script's to delete.
if [ "$BL_STATE" = absent ]; then rm -f "$BLACKLIST"; fi

case "$SCTP_STATE" in
  loaded)    modprobe -r sctp 2>/dev/null || true ;;
  preloaded) modprobe sctp 2>/dev/null || true ;;
esac
REMOTE
} > "$TMP"
on_worker bash -s < "$TMP" >/dev/null 2>&1 || true
rm -f "$TMP"
rm -f "$STATE"
echo "Cleanup complete"
echo "If you blacklisted sctp in a file other than $BLACKLIST, remove that file by hand."
