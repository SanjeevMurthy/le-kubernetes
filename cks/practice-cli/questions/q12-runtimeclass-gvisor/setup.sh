#!/bin/bash
# Q12 gVisor: confirm runsc is installed on the worker and hand over an empty namespace.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_tool kubectl
W=$(worker_node); [[ -n "$W" ]] || { echo "no worker node found"; exit 1; }
if ! on_worker runsc --version >/dev/null 2>&1; then
  echo "gVisor (runsc) is not installed on worker '$W'."
  echo "Install it with: sudo bash tools/install-tools.sh gvisor"
  exit 1
fi
RUNSC=$(on_worker runsc --version 2>/dev/null | head -1)
if on_worker grep -q runsc /etc/containerd/config.toml 2>/dev/null; then
  HANDLER="registered in /etc/containerd/config.toml"
else
  HANDLER="NOT found in /etc/containerd/config.toml — register the runsc handler and restart containerd first"
fi
kubectl delete runtimeclass gvisor --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace gvisor-lab >/dev/null 2>&1 || true
kubectl -n gvisor-lab delete pod sandboxed --ignore-not-found >/dev/null 2>&1 || true
echo "Setup complete:"
echo "  - worker node '$W' has $RUNSC"
echo "  - containerd runtime handler 'runsc': $HANDLER"
echo "  - no RuntimeClass named 'gvisor' exists; namespace gvisor-lab is empty"
