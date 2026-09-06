#!/bin/bash
# Q8 seccomp: put a custom audit profile on the worker's kubelet seccomp root
# and create the lab namespace. No pod is created — that is the task.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root; require_tool kubectl
W=$(worker_node); [[ -n "$W" ]] || { echo "no worker node found"; exit 1; }
on_worker bash -c 'mkdir -p /var/lib/kubelet/seccomp/profiles
cat > /var/lib/kubelet/seccomp/profiles/audit.json <<EOF
{
  "defaultAction": "SCMP_ACT_LOG"
}
EOF
chmod 0644 /var/lib/kubelet/seccomp/profiles/audit.json'
kubectl create namespace seccomp-lab 2>/dev/null || true
echo "Setup complete on worker '$W':"
echo "  seccomp root    : /var/lib/kubelet/seccomp"
echo "  custom profile  : /var/lib/kubelet/seccomp/profiles/audit.json (defaultAction SCMP_ACT_LOG)"
echo "  localhostProfile paths are relative to the seccomp root, so this one is 'profiles/audit.json'."
echo "  namespace seccomp-lab exists and is empty; no pod uses a seccomp profile yet."
