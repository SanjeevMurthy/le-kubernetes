#!/bin/bash
# Q09 SELinux: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

echo "Checking SELinux mode..."
check_eq "getenforce reports Enforcing right now" "Enforcing" "$(getenforce 2>/dev/null)"
check_persisted "the host is still enforcing after a reboot" \
  '^SELINUX=enforcing' /etc/selinux/config

echo "Checking the service..."
check_eq "httpd is running" "active" "$(systemctl is-active httpd 2>/dev/null)"
check_eq "httpd starts at boot" "enabled" "$(systemctl is-enabled httpd 2>/dev/null)"
check_contains "curl localhost:8081 returns the page" "selinux-ok" \
  "$(curl -s --max-time 5 http://localhost:8081/ 2>/dev/null)"

echo "Checking the file context..."
check_contains "the live label on /srv/site is httpd_sys_content_t" "httpd_sys_content_t" \
  "$(ls -Zd /srv/site 2>/dev/null)"
check_contains "the live label on the page is httpd_sys_content_t" "httpd_sys_content_t" \
  "$(ls -Z /srv/site/index.html 2>/dev/null)"
check_persisted "the file context rule is stored in policy, so a relabel keeps it" \
  '/srv/site' /etc/selinux/targeted/contexts/files/file_contexts.local

echo "Checking the port label and the boolean..."
check_contains "8081 is listed under http_port_t" "8081" \
  "$(semanage port -l 2>/dev/null | awk '/^http_port_t/')"
check_eq "httpd_can_network_connect is on right now" "on" \
  "$(getsebool httpd_can_network_connect 2>/dev/null | awk '{print $3}')"
check_eq "httpd_can_network_connect is on after a reboot" "on" \
  "$(semanage boolean -l 2>/dev/null | awk '$1=="httpd_can_network_connect" {gsub(/[(),]/," "); print $3}')"

echo "Checking the firewall..."
check_eq "firewalld is running" "active" "$(systemctl is-active firewalld 2>/dev/null)"
check_contains "8081/tcp is open right now" "8081/tcp" "$(firewall-cmd --list-ports 2>/dev/null)"
check_contains "8081/tcp is in the permanent configuration" "8081/tcp" \
  "$(firewall-cmd --permanent --list-ports 2>/dev/null)"

summary
