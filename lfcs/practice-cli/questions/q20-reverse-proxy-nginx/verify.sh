#!/bin/bash
# Q20 reverse proxy: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

echo "Control test: the backend itself answers on loopback..."
check_eq "lab-backend is running" "active" "$(systemctl is-active lab-backend 2>/dev/null)"
check_contains "http://127.0.0.1:9000/ returns backend-ok" "backend-ok" \
  "$(curl -s --max-time 4 http://127.0.0.1:9000/ 2>/dev/null)"

echo "Checking nginx itself..."
check "nginx -t reports no configuration error" nginx -t
check_eq "nginx is running" "active" "$(systemctl is-active nginx 2>/dev/null)"
check_contains "something is listening on port 80" ":80 " \
  "$(ss -H -ltn 2>/dev/null | awk '{print $4}' | tr '\n' ' ') "

echo "Effect test: the proxy answers with the backend's page..."
check_contains "curl http://localhost/ returns backend-ok" "backend-ok" \
  "$(curl -s --max-time 5 http://localhost/ 2>/dev/null)"

echo "Checking the proxy survives a reboot..."
NGFILES=(/etc/nginx/nginx.conf /etc/nginx/conf.d/*.conf /etc/nginx/sites-enabled/*
         /etc/nginx/sites-available/*)
check_persisted "a proxy_pass directive is in the nginx configuration" \
  'proxy_pass' "${NGFILES[@]}"
check_persisted "the backend 127.0.0.1:9000 is named in the nginx configuration" \
  '127\.0\.0\.1:9000' "${NGFILES[@]}"
check_eq "nginx starts at boot" "enabled" "$(systemctl is-enabled nginx 2>/dev/null)"

if [[ "$(distro)" == rocky ]]; then
  echo "Checking SELinux..."
  check_eq "httpd_can_network_connect is on right now" "on" \
    "$(getsebool httpd_can_network_connect 2>/dev/null | awk '{print $3}')"
  if command -v semanage >/dev/null 2>&1; then
    check_eq "httpd_can_network_connect is on after a reboot" "on" \
      "$(semanage boolean -l 2>/dev/null | awk '$1=="httpd_can_network_connect" {gsub(/[(),]/," "); print $3}')"
  else
    echo "  NOTE: semanage is not installed, so the persistent value of the boolean cannot be read."
  fi
fi

summary
