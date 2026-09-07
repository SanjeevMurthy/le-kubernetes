#!/bin/bash
# Q16 sshd hardening: create the deploy user and its key pair, put the OpenSSH
# configuration back to a permissive baseline, and remove any hardening or
# authorized_keys file left behind by an earlier attempt.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q16"
mkdir -p "$STATE/removed"
DIR=$(course_dir 16)
KEY="$DIR/id_deploy"

SSHD=$(command -v sshd 2>/dev/null)
[[ -n "$SSHD" ]] || SSHD=/usr/sbin/sshd
echo "$SSHD" > "$STATE/sshd"

UNIT=ssh
systemctl list-unit-files 2>/dev/null | grep -q '^sshd\.service' && UNIT=sshd
echo "$UNIT" > "$STATE/unit"

list_dropins() {
  local f
  for f in /etc/ssh/sshd_config.d/*.conf; do [[ -f "$f" ]] && echo "$f"; done
  return 0
}

id deploy >/dev/null 2>&1 || useradd -m -s /bin/bash deploy
rm -rf /home/deploy/.ssh

if [[ ! -f "$KEY" ]]; then
  rm -f "$KEY" "$KEY.pub"
  ssh-keygen -q -t ed25519 -N '' -C 'lfcs-q16-deploy' -f "$KEY"
fi
chmod 600 "$KEY"
chmod 644 "$KEY.pub"

mkdir -p /etc/ssh/sshd_config.d
backup_file /etc/ssh/sshd_config q16

while read -r f; do
  [[ -n "$f" ]] || continue
  b="$LFCS_STATE_DIR/backup/q16/$(echo "$f" | tr / _)"
  [[ -f "$b" ]] && restore_file "$f" q16
done < <(list_dropins)

[[ -f "$STATE/orig" ]] || list_dropins > "$STATE/orig"

# Anything in sshd_config.d that is not one of this host's own files was written
# by an earlier attempt at this question.
while read -r f; do
  [[ -n "$f" ]] || continue
  grep -Fxq "$f" "$STATE/orig" && continue
  mv -f "$f" "$STATE/removed/$(basename "$f")"
  echo "  Moved $f into $STATE/removed (it was written by an earlier attempt)."
done < <(list_dropins)

# Comment out the graded keywords wherever this host already sets them, so the
# candidate's own drop-in is the only thing that decides the answer.
while read -r f; do
  [[ -n "$f" ]] || continue
  backup_file "$f" q16
  sed -i -E 's/^([[:space:]]*)(PermitRootLogin|PasswordAuthentication|MaxAuthTries)([[:space:]])/\1#\2\3/I' "$f"
done < <(list_dropins)

set_baseline() {   # set_baseline key value
  local k="$1" v="$2" inc
  sed -i -E "/^[[:space:]]*$k([[:space:]]|\$)/Id" /etc/ssh/sshd_config
  inc=$(grep -nE '^[[:space:]]*Include[[:space:]]' /etc/ssh/sshd_config | head -1 | cut -d: -f1)
  if [[ -n "$inc" ]]; then
    sed -i "${inc}a $k $v" /etc/ssh/sshd_config
  else
    sed -i "1i $k $v" /etc/ssh/sshd_config
  fi
}
set_baseline PermitRootLogin yes
set_baseline PasswordAuthentication yes
set_baseline MaxAuthTries 6

if ! "$SSHD" -t 2>"$STATE/sshd-t.err"; then
  echo "The baseline configuration does not parse. Restoring the original file."
  cat "$STATE/sshd-t.err"
  restore_file /etc/ssh/sshd_config q16
  exit 1
fi

systemctl reload "$UNIT" >/dev/null 2>&1 || systemctl restart "$UNIT" >/dev/null 2>&1

echo "Setup complete."
echo "  User:                deploy ($(getent passwd deploy | cut -d: -f6), shell $(getent passwd deploy | cut -d: -f7))"
echo "  Key pair:            $KEY and $KEY.pub"
echo "  Service unit:        $UNIT ($(systemctl is-active "$UNIT" 2>/dev/null))"
echo "  Effective now:       $("$SSHD" -T 2>/dev/null | grep -E '^(permitrootlogin|passwordauthentication|maxauthtries)' | tr '\n' ' ')"
echo "  /home/deploy/.ssh has been removed, so key login for deploy does not work yet."
echo "  Wanted: permitrootlogin no, passwordauthentication no, maxauthtries 3,"
echo "          and passwordauthentication yes for user deploy only."
echo "  Run sshd -t before restarting the service."
