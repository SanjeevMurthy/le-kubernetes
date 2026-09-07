#!/bin/bash
# Q20 reverse proxy: run an application on 127.0.0.1:9000, install nginx but
# leave it stopped and disabled, take the packaged default site out of the way,
# and on Rocky turn the outbound-connection boolean off.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q20"
mkdir -p "$STATE/removed"

command -v nginx >/dev/null 2>&1 || pkg_install nginx
if ! command -v nginx >/dev/null 2>&1; then
  echo "nginx could not be installed. Install it and run setup again."
  exit 1
fi

mkdir -p /srv/backend
printf 'backend-ok\n' > /srv/backend/index.html

cat > /etc/systemd/system/lab-backend.service <<'UNITEOF'
[Unit]
Description=LFCS Q20 backend application on 127.0.0.1:9000
After=network.target

[Service]
ExecStart=/usr/bin/python3 -u -m http.server 9000 --bind 127.0.0.1 --directory /srv/backend
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNITEOF
systemctl daemon-reload
systemctl enable --now lab-backend >/dev/null 2>&1

list_sites() {
  local f
  for f in /etc/nginx/conf.d/*.conf /etc/nginx/sites-enabled/* /etc/nginx/sites-available/*; do
    [[ -e "$f" ]] && echo "$f"
  done
  return 0
}

[[ -f "$STATE/orig" ]] || list_sites > "$STATE/orig"
[[ -f "$STATE/nginx-enabled" ]] || systemctl is-enabled nginx > "$STATE/nginx-enabled" 2>/dev/null

# Remove any proxy configuration written by an earlier attempt.
while read -r f; do
  [[ -n "$f" ]] || continue
  grep -Fxq "$f" "$STATE/orig" && continue
  mv -f "$f" "$STATE/removed/$(basename "$f")" 2>/dev/null
  echo "  Moved $f into $STATE/removed (it was written by an earlier attempt)."
done < <(list_sites)

if [[ "$(distro)" == ubuntu ]]; then
  if [[ -e /etc/nginx/sites-enabled/default ]]; then
    readlink -f /etc/nginx/sites-enabled/default > "$STATE/default-site" 2>/dev/null
    rm -f /etc/nginx/sites-enabled/default
    echo "  Removed the packaged default site from /etc/nginx/sites-enabled."
  fi
else
  backup_file /etc/nginx/nginx.conf q20
  if grep -q 'default_server' /etc/nginx/nginx.conf 2>/dev/null; then
    sed -i 's/[[:space:]]default_server//g' /etc/nginx/nginx.conf
    echo "  Demoted the packaged default server block in /etc/nginx/nginx.conf."
  fi
  if command -v getsebool >/dev/null 2>&1; then
    [[ -f "$STATE/bool" ]] || getsebool httpd_can_network_connect | awk '{print $3}' > "$STATE/bool"
    setsebool -P httpd_can_network_connect off >/dev/null 2>&1
  fi
fi

systemctl disable --now nginx >/dev/null 2>&1

echo "Setup complete."
echo "  Backend unit:     lab-backend.service on 127.0.0.1:9000, $(systemctl is-active lab-backend 2>/dev/null)"
echo "  Backend answers:  $(curl -s --max-time 3 http://127.0.0.1:9000/ 2>/dev/null || echo 'no answer yet')"
echo "  nginx:            $(systemctl is-active nginx 2>/dev/null), $(systemctl is-enabled nginx 2>/dev/null)"
echo "  Configuration:    /etc/nginx/conf.d/ and, on Ubuntu, /etc/nginx/sites-available with a symlink"
echo "  Wanted:           curl -s http://localhost/ returns backend-ok, nginx enabled at boot"
if [[ "$(distro)" == rocky ]]; then
  echo "  SELinux boolean:  httpd_can_network_connect is $(getsebool httpd_can_network_connect 2>/dev/null | awk '{print $3}')"
  echo "                    A correct configuration returns 502 until it is on, with -P."
fi
