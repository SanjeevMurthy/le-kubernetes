#!/bin/bash
# Q08 podman: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

pf() { podman inspect web --format "$1" 2>/dev/null; }

echo "Checking the container is running..."
check "a container named web exists" podman container exists web
check_eq "web is running" "running" "$(pf '{{.State.Status}}')"

echo "Checking it serves the page on 8080..."
check_contains "curl localhost:8080 returns hello" "hello" "$(curl -s --max-time 5 http://localhost:8080/ 2>/dev/null)"
check_contains "something is listening on 8080" ":8080" "$(ss -H -ltn 2>/dev/null)"

echo "Checking the limits and the mount..."
check_eq "the memory cap is 256 MB in bytes" "268435456" "$(pf '{{.HostConfig.Memory}}')"
check_contains "port 80 in the container is published on 8080" "8080" "$(pf '{{.HostConfig.PortBindings}}')"
check_contains "container port 80/tcp is the one published" "80/tcp" "$(pf '{{.HostConfig.PortBindings}}')"
check_contains "/srv/web is mounted read-only on the document root" \
  "/srv/web|/usr/share/nginx/html|false" \
  "$(pf '{{range .Mounts}}{{.Source}}|{{.Destination}}|{{.RW}} {{end}}')"

echo "Checking it comes back after a reboot..."
check_eq "the restart policy is always" "always" "$(pf '{{.HostConfig.RestartPolicy.Name}}')"
ENAB=no
for u in container-web.service web.service podman-restart.service; do
  systemctl is-enabled "$u" >/dev/null 2>&1 && ENAB=yes
done
check_eq "an enabled systemd unit starts the container at boot" "yes" "$ENAB"
check_persisted "the unit that brings the container back is on disk" \
  'podman|Image=' \
  /etc/systemd/system/container-web.service \
  /etc/containers/systemd/web.container \
  /etc/systemd/system/multi-user.target.wants/podman-restart.service

summary
