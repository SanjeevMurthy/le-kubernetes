#!/bin/bash
# Q05 packages: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q05"

if [[ "$(distro)" == ubuntu ]]; then
  apt-mark unhold nginx >/dev/null 2>&1
else
  dnf versionlock delete nginx >/dev/null 2>&1
fi

systemctl disable --now nginx >/dev/null 2>&1

# Remove only what was not on the host before setup ran.
for p in tree nginx; do
  if [[ -f "$STATE/before" ]] && grep -qx "$p" "$STATE/before"; then
    continue
  fi
  if [[ "$(distro)" == ubuntu ]]; then
    DEBIAN_FRONTEND=noninteractive apt-get remove -y -q "$p" >/dev/null 2>&1
  else
    dnf remove -y -q "$p" >/dev/null 2>&1
  fi
done

if [[ "$(distro)" == ubuntu ]]; then
  DEBIAN_FRONTEND=noninteractive apt-get autoremove -y -q >/dev/null 2>&1
fi

rm -rf "$COURSE_DIR/5"
rm -rf "${LFCS_STATE_DIR:?}/q05"

echo "Cleanup complete. Holds cleared, $COURSE_DIR/5 removed, and packages that were not present before setup are gone."
