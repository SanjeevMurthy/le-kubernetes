#!/bin/bash
# Q41 accounts: provide bob with a usable password so locking him is a real
# change, and remove any account or group the task is meant to create.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q41"
mkdir -p "$STATE"
rm -f "$STATE/created-bob"

# Record what the host already had, once and before anything is removed or
# created, so cleanup deletes only what exists because of this question. ana,
# devs and qa are shared with Q42, Q43 and Q44: in a mock exam they may already
# belong to one of those, and are then not this question's to delete. The
# records are written once, so a second setup run keeps the first answer.
for u in ana svc-batch; do
  f="$STATE/created-user-$u"
  [[ -f "$f" ]] && continue
  if id "$u" >/dev/null 2>&1; then echo no > "$f"; else echo yes > "$f"; fi
done
for g in devs qa; do
  f="$STATE/created-group-$g"
  [[ -f "$f" ]] && continue
  if getent group "$g" >/dev/null 2>&1; then echo no > "$f"; else echo yes > "$f"; fi
done

EXISTED=""
[[ "$(cat "$STATE/created-user-ana" 2>/dev/null)" == no ]]       && EXISTED="$EXISTED ana"
[[ "$(cat "$STATE/created-user-svc-batch" 2>/dev/null)" == no ]] && EXISTED="$EXISTED svc-batch"
[[ "$(cat "$STATE/created-group-devs" 2>/dev/null)" == no ]]     && EXISTED="$EXISTED devs"
[[ "$(cat "$STATE/created-group-qa" 2>/dev/null)" == no ]]       && EXISTED="$EXISTED qa"

# The task is to create all four from nothing, so setup still clears them.
userdel -r ana >/dev/null 2>&1
userdel -r svc-batch >/dev/null 2>&1
groupdel devs >/dev/null 2>&1
groupdel qa >/dev/null 2>&1
rm -rf /home/ana

if ! id bob >/dev/null 2>&1; then
  useradd -m -s /bin/bash -c 'Bob Lawson' bob
  touch "$STATE/created-bob"
fi
echo 'bob:Lfcs2026Bob' | chpasswd
usermod -U bob >/dev/null 2>&1

echo "Setup complete."
echo "  bob exists and his password is currently $(passwd -S bob 2>/dev/null | awk '{print $2}') (usable)."
echo "  ana, svc-batch, devs and qa do not exist."
if [[ -n "$EXISTED" ]]; then
  echo "  Note: these already existed on this host and were removed so the task can be"
  echo "  answered from nothing:$EXISTED. Cleanup will leave whatever you create in"
  echo "  place, but any other question that was using them has to be set up again."
fi
echo "  Next free system UID range on this host: below $(awk '/^UID_MIN/ {print $2}' /etc/login.defs 2>/dev/null | head -1)"
echo "  The nologin shell on this host is $( [[ -x /usr/sbin/nologin ]] && echo /usr/sbin/nologin || echo /sbin/nologin )"
