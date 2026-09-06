#!/bin/bash
# Q7 AppArmor: place an unloaded profile on the worker and create the namespace.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root; require_tool kubectl
W=$(worker_node); [[ -n "$W" ]] || { echo "no worker node found"; exit 1; }
on_worker bash -c 'cat > /etc/apparmor.d/k8s-deny-write <<EOF
#include <tunables/global>
profile k8s-deny-write flags=(attach_disconnected) {
  #include <abstractions/base>
  file,
  deny /** w,
}
EOF
apparmor_parser -R /etc/apparmor.d/k8s-deny-write 2>/dev/null || true'
kubectl create namespace apparmor-lab 2>/dev/null || true
echo "Setup complete: profile file /etc/apparmor.d/k8s-deny-write exists on worker '$W' but is NOT loaded; namespace apparmor-lab is empty."
