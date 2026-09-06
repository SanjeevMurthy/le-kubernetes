#!/bin/bash
# Q28 gVisor dmesg: confirm runsc is usable on the worker, then hand over an
# empty namespace with no RuntimeClass. Creating both is the task.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kubectl
require_tool runsc

NS=gvisor-lab

W=$(worker_node)
[[ -n "$W" ]] || { echo "no worker node found; this question needs a cluster with a separate worker"; exit 1; }

if ! on_worker runsc --version >/dev/null 2>&1; then
  echo "gVisor (runsc) is not installed on worker '$W'."
  echo "Install it with: sudo bash tools/install-tools.sh gvisor"
  exit 1
fi
RUNSC=$(on_worker runsc --version 2>/dev/null | head -1)

if on_worker grep -q runsc /etc/containerd/config.toml 2>/dev/null; then
  HANDLER="registered in /etc/containerd/config.toml"
else
  HANDLER="NOT found in /etc/containerd/config.toml; register the runsc handler and restart containerd first"
fi

kubectl delete runtimeclass gvisor --ignore-not-found >/dev/null 2>&1 || true
kubectl create namespace "$NS" >/dev/null 2>&1 || true
kubectl -n "$NS" delete pod gvisor-test --ignore-not-found --now >/dev/null 2>&1 || true

DIR=$(course_dir 28)
rm -f "$DIR/dmesg.txt"

echo "Setup complete:"
echo "  Worker node:     $W has $RUNSC"
echo "  containerd:      runtime handler 'runsc' $HANDLER"
echo "  RuntimeClass:    none named 'gvisor' exists"
echo "  Namespace:       $NS is empty; pod 'gvisor-test' does not exist"
echo "  Deliverable:     $DIR/dmesg.txt"
echo "  The Pod has to land on $W, so set spec.nodeName or a nodeSelector."
