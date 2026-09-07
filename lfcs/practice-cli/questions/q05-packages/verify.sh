#!/bin/bash
# Q05 packages: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

DIR="$COURSE_DIR/5"
norm() { tr -s '[:space:]' ' ' | sed -e 's/^ //' -e 's/ $//'; }

if [[ "$(distro)" == ubuntu ]]; then
  NGINX_STATUS=$(dpkg-query -W -f='${Status}' nginx 2>/dev/null)
  EXPECT_VER=$(dpkg-query -W -f='${Version}' openssl 2>/dev/null)
  EXPECT_VFY=$(dpkg -V bash 2>/dev/null)
else
  NGINX_STATUS=$(rpm -q nginx >/dev/null 2>&1 && echo 'install ok installed')
  EXPECT_VER=$(rpm -q --qf '%{VERSION}-%{RELEASE}' openssl 2>/dev/null)
  EXPECT_VFY=$(rpm -V bash 2>/dev/null)
fi

echo "Checking the installed packages..."
check "tree is on PATH" command -v tree
check_contains "the package database records nginx as installed" "install ok installed" "$NGINX_STATUS"
check_persisted "nginx put its unit file on disk" \
  'ExecStart[[:space:]]*=.*nginx' \
  /lib/systemd/system/nginx.service /usr/lib/systemd/system/nginx.service

echo "Checking nginx is down and stays down..."
check_eq "nginx is not running" "inactive" "$(systemctl is-active nginx 2>/dev/null)"
EN=$(systemctl is-enabled nginx 2>/dev/null)
case "$EN" in disabled|masked) EN=disabled ;; esac
check_eq "nginx will not start at the next boot" "disabled" "$EN"

echo "Checking the version is frozen..."
if [[ "$(distro)" == ubuntu ]]; then
  check_contains "apt-mark showhold lists nginx" "nginx" "$(apt-mark showhold 2>/dev/null)"
else
  check_contains "dnf versionlock list mentions nginx" "nginx" "$(dnf versionlock list 2>/dev/null)"
  check_persisted "the version lock is written to disk" 'nginx' /etc/dnf/plugins/versionlock.list
fi

echo "Checking the two reports..."
check "version.txt exists" test -f "$DIR/version.txt"
check_eq "version.txt holds the installed openssl version" \
  "$(printf '%s' "$EXPECT_VER" | norm)" "$(cat "$DIR/version.txt" 2>/dev/null | norm)"
check "verify.txt exists" test -f "$DIR/verify.txt"
check_eq "verify.txt matches the package verification of bash" \
  "$(printf '%s' "$EXPECT_VFY" | norm)" "$(cat "$DIR/verify.txt" 2>/dev/null | norm)"

summary
