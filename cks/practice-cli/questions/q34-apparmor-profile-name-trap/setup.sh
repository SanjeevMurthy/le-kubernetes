#!/bin/bash
# Q34 AppArmor name trap: put an unloaded profile on the worker whose inner name
# differs from its file name, and a pod manifest that names the file.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kubectl

NS=apparmor-trap
PROFILE_FILE=/etc/apparmor.d/k8s-lab-deny-write
W=$(worker_node)
[[ -n "$W" ]] || { echo "no worker node found"; exit 1; }

on_worker command -v apparmor_parser >/dev/null 2>&1 || {
  echo "apparmor_parser is not installed on $W. Install it there with: sudo bash tools/install-tools.sh apparmor"
  exit 1
}

on_worker bash -s <<'REMOTE'
set -e
FILE=/etc/apparmor.d/k8s-lab-deny-write
cat > "$FILE" <<'PROFILE'
#include <tunables/global>

# The file is called k8s-lab-deny-write. The profile is not.
profile deny-write-lab flags=(attach_disconnected) {
  #include <abstractions/base>

  file,
  deny /** w,
}
PROFILE
chmod 0644 "$FILE"
apparmor_parser -R "$FILE" 2>/dev/null || true
echo "profile file written and unloaded on $(hostname)"
REMOTE

kubectl create namespace "$NS" >/dev/null 2>&1 || true
kubectl -n "$NS" delete pod guarded --ignore-not-found --wait=false >/dev/null 2>&1 || true

DIR=$(course_dir 34)
cat > "$DIR/pod.yaml" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: guarded
  namespace: $NS
spec:
  nodeName: $W
  containers:
  - name: guarded
    image: busybox:1.36
    command: ["sleep", "3600"]
    securityContext:
      appArmorProfile:
        type: Localhost
        localhostProfile: k8s-lab-deny-write
EOF

LOADED=$(on_worker aa-status 2>/dev/null | grep -c 'deny-write-lab' || true)

echo "Setup complete."
echo "  Worker node:      $W"
echo "  Profile file:     $PROFILE_FILE   (present, NOT loaded)"
echo "  Loaded profiles matching deny-write-lab right now: ${LOADED:-0}"
echo "  Namespace:        $NS (empty)"
echo "  Draft manifest:   $DIR/pod.yaml   (it does not work as written)"
echo "  Read the profile file before editing the manifest."
