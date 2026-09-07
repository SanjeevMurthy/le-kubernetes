#!/bin/bash
# Q09 SELinux: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"
require_distro rocky || exit 0

STATE="$LFCS_STATE_DIR/q09"

systemctl stop httpd >/dev/null 2>&1
[[ "$(cat "$STATE/httpd" 2>/dev/null)" == enabled ]] || systemctl disable httpd >/dev/null 2>&1

rm -f /etc/httpd/conf.d/lab-site.conf

semanage port -d -t http_port_t -p tcp 8081 >/dev/null 2>&1
semanage fcontext -d '/srv/site(/.*)?' >/dev/null 2>&1
setsebool -P httpd_can_network_connect off >/dev/null 2>&1
rm -rf /srv/site

firewall-cmd --permanent --remove-port=8081/tcp >/dev/null 2>&1
firewall-cmd --remove-port=8081/tcp >/dev/null 2>&1
firewall-cmd --reload >/dev/null 2>&1
if [[ "$(cat "$STATE/firewalld" 2>/dev/null)" != enabled ]]; then
  systemctl disable --now firewalld >/dev/null 2>&1
fi

restore_file /etc/selinux/config q09
case "$(cat "$STATE/enforce" 2>/dev/null)" in
  Permissive) setenforce 0 >/dev/null 2>&1 ;;
  Enforcing)  setenforce 1 >/dev/null 2>&1 ;;
esac

rm -rf "${LFCS_STATE_DIR:?}/q09"

echo "Cleanup complete."
echo "  Port label, file context rule, boolean, firewall port and /srv/site removed."
echo "  /etc/selinux/config restored and the live mode set back to $(getenforce)."
echo "  The httpd package itself is left installed."
