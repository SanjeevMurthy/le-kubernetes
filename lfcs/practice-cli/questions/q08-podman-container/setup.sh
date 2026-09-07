#!/bin/bash
# Q08 podman: pull the image, empty the document root, and remove any container
# or unit left from an earlier run.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

if ! has_needs "tool:podman"; then
  echo "This question needs podman on PATH."
  exit 1
fi

STATE="$LFCS_STATE_DIR/q08"
mkdir -p "$STATE"

IMAGE=docker.io/library/nginx:1.27

if [[ ! -f "$STATE/image-existed" ]]; then
  if podman image exists "$IMAGE"; then echo yes > "$STATE/image-existed"; else echo no > "$STATE/image-existed"; fi
fi
if [[ ! -f "$STATE/podman-restart" ]]; then
  systemctl is-enabled podman-restart.service >/dev/null 2>&1 && echo enabled > "$STATE/podman-restart" || echo other > "$STATE/podman-restart"
fi

podman rm -f web >/dev/null 2>&1
systemctl disable --now container-web.service >/dev/null 2>&1
rm -f /etc/systemd/system/container-web.service /etc/containers/systemd/web.container
systemctl daemon-reload >/dev/null 2>&1

mkdir -p /srv/web
rm -f /srv/web/index.html

if ! podman image exists "$IMAGE"; then
  podman pull -q "$IMAGE" >/dev/null 2>&1
fi

echo "Setup complete."
echo "  Image:          $IMAGE ($(podman image exists "$IMAGE" && echo present || echo 'PULL FAILED, check the network'))"
echo "  Document root:  /srv/web (empty)"
echo "  Containers now: $(podman ps -a --format '{{.Names}}' 2>/dev/null | tr '\n' ' ')"
echo "  Required:       name web, 8080 to 80, 256 MB cap, read-only bind mount, restart always, and back after a reboot."
