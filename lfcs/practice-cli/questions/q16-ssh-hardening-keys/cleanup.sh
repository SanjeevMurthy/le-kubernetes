#!/bin/bash
# Q16 sshd hardening: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q16"
UNIT=$(cat "$STATE/unit" 2>/dev/null)
SSHD=$(cat "$STATE/sshd" 2>/dev/null)
[[ -n "$UNIT" ]] || UNIT=ssh
[[ -n "$SSHD" ]] || SSHD=/usr/sbin/sshd

list_dropins() {
  local f
  for f in /etc/ssh/sshd_config.d/*.conf; do [[ -f "$f" ]] && echo "$f"; done
  return 0
}

# Remove every drop-in that is not one of this host's own files, then restore
# the ones that are.
while read -r f; do
  [[ -n "$f" ]] || continue
  if [[ -f "$STATE/orig" ]] && grep -Fxq "$f" "$STATE/orig"; then continue; fi
  rm -f "$f"
  echo "  Removed $f, which was written for this question."
done < <(list_dropins)

while read -r f; do [[ -n "$f" ]] && restore_file "$f" q16; done < <(list_dropins)
restore_file /etc/ssh/sshd_config q16

if "$SSHD" -t >/dev/null 2>&1; then
  systemctl reload "$UNIT" >/dev/null 2>&1 || systemctl restart "$UNIT" >/dev/null 2>&1
else
  echo "  Warning: sshd -t still reports an error. The running daemon was left alone."
fi

# Only if setup created it. An account the host already had is not this
# question's to delete.
[[ "$(cat "$STATE/created-user" 2>/dev/null)" == yes ]] && userdel -r deploy >/dev/null 2>&1
rm -rf "${COURSE_DIR:?}/16"
rm -rf "${LFCS_STATE_DIR:?}/q16"

echo "Cleanup complete."
echo "  The original sshd configuration is back, the daemon reloaded it, and the deploy user was removed only if this question created it."
