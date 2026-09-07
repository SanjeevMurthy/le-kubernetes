#!/bin/bash
# Q20 reverse proxy: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q20"

list_sites() {
  local f
  for f in /etc/nginx/conf.d/*.conf /etc/nginx/sites-enabled/* /etc/nginx/sites-available/*; do
    [[ -e "$f" ]] && echo "$f"
  done
  return 0
}

while read -r f; do
  [[ -n "$f" ]] || continue
  if [[ -f "$STATE/orig" ]] && grep -Fxq "$f" "$STATE/orig"; then continue; fi
  rm -f "$f"
  echo "  Removed $f, which was written for this question."
done < <(list_sites)

if [[ -s "$STATE/default-site" ]]; then
  TARGET=$(cat "$STATE/default-site")
  [[ -e "$TARGET" ]] && ln -sf "$TARGET" /etc/nginx/sites-enabled/default
fi
restore_file /etc/nginx/nginx.conf q20

if [[ -s "$STATE/bool" ]] && command -v setsebool >/dev/null 2>&1; then
  setsebool -P httpd_can_network_connect "$(cat "$STATE/bool")" >/dev/null 2>&1
fi

systemctl disable --now lab-backend >/dev/null 2>&1
rm -f /etc/systemd/system/lab-backend.service
systemctl daemon-reload
rm -rf /srv/backend

if [[ "$(cat "$STATE/nginx-enabled" 2>/dev/null)" == enabled ]]; then
  systemctl enable --now nginx >/dev/null 2>&1
else
  systemctl disable --now nginx >/dev/null 2>&1
fi

rm -rf "${LFCS_STATE_DIR:?}/q20"

echo "Cleanup complete."
echo "  The backend unit and its files are gone, the proxy configuration was removed,"
echo "  and nginx was put back the way setup found it. The nginx package is left installed."
