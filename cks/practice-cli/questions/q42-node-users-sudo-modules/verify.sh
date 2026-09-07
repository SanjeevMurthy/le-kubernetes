#!/bin/bash
# Q42 users, sudo and modules: verify. The module part is graded only when the
# setup managed to load sctp on this kernel, which it recorded in the state file.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

USERNAME=tempadmin
GROUP=lab-ops
SUDOERS=/etc/sudoers.d/tempadmin
STATE="$CKS_STATE_DIR/q42.state"
W=$(worker_node)

echo "Checking the account on ${W:-the worker}..."
# Precondition and requirement at once: the task is to lock the account, not to
# delete it, and every check below is meaningless if the account is gone.
check "the account $USERNAME still exists on the worker" on_worker id "$USERNAME"

PW=$(on_worker passwd -S "$USERNAME" 2>/dev/null | awk '{print $2}')
check_eq "passwd -S reports the password as locked" L "$PW"

SH=$(on_worker getent passwd "$USERNAME" 2>/dev/null | cut -d: -f7)
if [[ "$SH" =~ (nologin|false)$ ]]; then
  echo "  PASS: the login shell is $SH"; PASS=$((PASS + 1))
else
  echo "  FAIL: expected /usr/sbin/nologin as the login shell, got '${SH:-<unreadable>}'"; FAIL=$((FAIL + 1))
fi

echo "Checking sudo..."
# Prove a remote `test` reaches the worker before asking whether a file is
# absent, otherwise a broken ssh would read as a solved question.
check "/etc/sudoers.d is readable on ${W:-the worker}" on_worker test -d /etc/sudoers.d
check_not "the drop-in $SUDOERS is gone" on_worker test -f "$SUDOERS"

SUDOL=$(on_worker sudo -l -U "$USERNAME" 2>&1)
if [[ -z "$(echo "$SUDOL" | tr -d '[:space:]')" ]]; then
  echo "  FAIL: sudo -l -U $USERNAME returned nothing, so its answer cannot be trusted"; FAIL=$((FAIL + 1))
elif echo "$SUDOL" | grep -q 'NOPASSWD'; then
  echo "  FAIL: sudo still grants NOPASSWD rights to $USERNAME"; FAIL=$((FAIL + 1))
else
  echo "  PASS: sudo lists no NOPASSWD rights for $USERNAME"; PASS=$((PASS + 1))
fi

echo "Checking group membership..."
MEMBEROF=$(on_worker id -nG "$USERNAME" 2>/dev/null)
if [[ -z "$(echo "$MEMBEROF" | tr -d '[:space:]')" ]]; then
  echo "  FAIL: could not read the group list for $USERNAME, so nothing can be concluded"; FAIL=$((FAIL + 1))
else
  echo "  PASS: read the group list for $USERNAME ($MEMBEROF)"; PASS=$((PASS + 1))
  if [[ " $MEMBEROF " == *" $GROUP "* ]]; then
    echo "  FAIL: $USERNAME is still a member of $GROUP"; FAIL=$((FAIL + 1))
  else
    echo "  PASS: $USERNAME is no longer a member of $GROUP"; PASS=$((PASS + 1))
  fi
fi

SCTP=$(sed -n 's/^sctp=//p' "$STATE" 2>/dev/null | head -1)
if [[ "$SCTP" == "loaded" || "$SCTP" == "preloaded" ]]; then
  echo "Checking the sctp kernel module..."
  LSMOD=$(on_worker lsmod 2>/dev/null)
  LN=$(echo "$LSMOD" | grep -c .)
  if [[ "${LN:-0}" -lt 2 ]]; then
    echo "  FAIL: lsmod returned no modules from ${W:-the worker}, so 'sctp is unloaded' cannot be trusted"; FAIL=$((FAIL + 1))
  else
    echo "  PASS: read $LN lines of lsmod from ${W:-the worker}"; PASS=$((PASS + 1))
    if echo "$LSMOD" | awk '{print $1}' | grep -qx sctp; then
      echo "  FAIL: the sctp module is still loaded"; FAIL=$((FAIL + 1))
    else
      echo "  PASS: the sctp module is not loaded any more"; PASS=$((PASS + 1))
    fi
  fi

  CONF=$(on_worker modprobe --showconfig 2>/dev/null)
  if [[ -z "$(echo "$CONF" | tr -d '[:space:]')" ]]; then
    echo "  FAIL: modprobe --showconfig returned nothing, so the blacklist cannot be checked"; FAIL=$((FAIL + 1))
  elif echo "$CONF" | grep -Eq 'blacklist[[:space:]]+sctp|install[[:space:]]+sctp[[:space:]]+/bin/(true|false)'; then
    echo "  PASS: the modprobe configuration blacklists sctp"; PASS=$((PASS + 1))
  else
    echo "  FAIL: no 'blacklist sctp' or 'install sctp /bin/true' line in the modprobe configuration"; FAIL=$((FAIL + 1))
  fi
elif [[ "$SCTP" == "unavailable" ]]; then
  echo "Skipping the sctp module: this kernel has no such module, so the setup never loaded it."
else
  echo "Skipping the sctp module: $STATE holds no record of it. Run the setup again to grade that part."
fi

summary
