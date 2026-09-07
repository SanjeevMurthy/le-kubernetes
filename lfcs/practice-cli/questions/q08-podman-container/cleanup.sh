#!/bin/bash
# Q08 podman: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

STATE="$LFCS_STATE_DIR/q08"
IMAGE=docker.io/library/nginx:1.27

systemctl disable --now container-web.service >/dev/null 2>&1
systemctl disable --now web.service >/dev/null 2>&1
rm -f /etc/systemd/system/container-web.service /etc/containers/systemd/web.container
if [[ "$(cat "$STATE/podman-restart" 2>/dev/null)" != enabled ]]; then
  systemctl disable --now podman-restart.service >/dev/null 2>&1
fi
systemctl daemon-reload >/dev/null 2>&1

podman rm -f web >/dev/null 2>&1
if [[ "$(cat "$STATE/image-existed" 2>/dev/null)" == no ]]; then
  podman rmi "$IMAGE" >/dev/null 2>&1
fi

rm -rf /srv/web
rm -rf "${LFCS_STATE_DIR:?}/q08"

echo "Cleanup complete. Container web, its unit, /srv/web and any image this lab pulled are gone."
