#!/bin/bash
# Q05 packages: remove the two packages the task installs, clear any hold, and
# remember what was there first so cleanup can put it back.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

DIR=$(course_dir 5)
STATE="$LFCS_STATE_DIR/q05"
mkdir -p "$STATE"

if [[ ! -f "$STATE/before" ]]; then
  : > "$STATE/before"
  command -v tree >/dev/null 2>&1 && echo tree >> "$STATE/before"
  if [[ "$(distro)" == ubuntu ]]; then
    dpkg-query -W -f='${Status}' nginx 2>/dev/null | grep -q 'install ok installed' && echo nginx >> "$STATE/before"
  else
    rpm -q nginx >/dev/null 2>&1 && echo nginx >> "$STATE/before"
  fi
fi

rm -f "$DIR/version.txt" "$DIR/verify.txt"

if [[ "$(distro)" == ubuntu ]]; then
  apt-mark unhold nginx >/dev/null 2>&1
  DEBIAN_FRONTEND=noninteractive apt-get remove -y -q tree nginx nginx-core nginx-common >/dev/null 2>&1
  DEBIAN_FRONTEND=noninteractive apt-get autoremove -y -q >/dev/null 2>&1
  DEBIAN_FRONTEND=noninteractive apt-get update -q >/dev/null 2>&1
else
  dnf install -y -q python3-dnf-plugin-versionlock >/dev/null 2>&1
  dnf versionlock delete nginx >/dev/null 2>&1
  dnf remove -y -q tree nginx >/dev/null 2>&1
  dnf makecache -q >/dev/null 2>&1
fi

echo "Setup complete."
echo "  Distribution:  $(distro)"
echo "  tree:          $(command -v tree >/dev/null 2>&1 && echo installed || echo not installed)"
echo "  nginx:         removed, and any hold or version lock on it has been cleared"
echo "  Package index: refreshed"
echo "  Deliverables:  $DIR/version.txt and $DIR/verify.txt"
