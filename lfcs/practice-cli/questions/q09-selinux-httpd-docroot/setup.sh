#!/bin/bash
# Q09 SELinux: a correct Apache configuration that cannot work until SELinux is
# taught about the port, the label and the boolean. The live mode is enforcing
# while /etc/selinux/config says permissive, so the persistence half is wrong too.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"
require_distro rocky || exit 1

STATE="$LFCS_STATE_DIR/q09"
mkdir -p "$STATE"

command -v semanage >/dev/null 2>&1 || pkg_install policycoreutils-python-utils
command -v httpd >/dev/null 2>&1 || pkg_install httpd
command -v firewall-cmd >/dev/null 2>&1 || pkg_install firewalld

if ! has_needs "rocky tool:semanage"; then
  echo "semanage is missing. Install policycoreutils-python-utils and run setup again."
  exit 1
fi

# Remember the host as it was, so cleanup can put it back.
[[ -f "$STATE/enforce" ]]  || getenforce > "$STATE/enforce" 2>/dev/null
[[ -f "$STATE/firewalld" ]] || systemctl is-enabled firewalld > "$STATE/firewalld" 2>/dev/null
[[ -f "$STATE/httpd" ]]    || systemctl is-enabled httpd > "$STATE/httpd" 2>/dev/null

backup_file /etc/selinux/config q09

systemctl enable --now firewalld >/dev/null 2>&1
firewall-cmd --permanent --remove-port=8081/tcp >/dev/null 2>&1
firewall-cmd --remove-port=8081/tcp >/dev/null 2>&1
firewall-cmd --reload >/dev/null 2>&1

mkdir -p /srv/site
echo "selinux-ok" > /srv/site/index.html

cat > /etc/httpd/conf.d/lab-site.conf <<'CONFEOF'
# Lab site for LFCS Q09. This configuration is correct; SELinux is not yet.
Listen 8081
DocumentRoot /srv/site

<Directory "/srv/site">
    Require all granted
</Directory>
CONFEOF

# Wrong label, wrong port label, wrong boolean.
semanage fcontext -d '/srv/site(/.*)?' >/dev/null 2>&1
restorecon -R /srv/site >/dev/null 2>&1
chcon -R -t admin_home_t /srv/site >/dev/null 2>&1
semanage port -d -t http_port_t -p tcp 8081 >/dev/null 2>&1
setsebool -P httpd_can_network_connect off >/dev/null 2>&1

# Enforcing now, permissive at the next boot.
setenforce 1 >/dev/null 2>&1
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

systemctl disable httpd >/dev/null 2>&1
systemctl stop httpd >/dev/null 2>&1
systemctl start httpd >/dev/null 2>&1

echo "Setup complete."
echo "  Mode now:            $(getenforce)"
echo "  /etc/selinux/config: $(grep '^SELINUX=' /etc/selinux/config)"
echo "  Apache config:       /etc/httpd/conf.d/lab-site.conf (Listen 8081, DocumentRoot /srv/site)"
echo "  Page:                /srv/site/index.html, label $(ls -Zd /srv/site | awk '{print $1}')"
echo "  httpd is currently:  $(systemctl is-active httpd), $(systemctl is-enabled httpd 2>/dev/null)"
echo "  firewalld is:        $(systemctl is-active firewalld), ports $(firewall-cmd --list-ports 2>/dev/null)"
echo "  Do not disable SELinux and do not edit the Apache configuration."
