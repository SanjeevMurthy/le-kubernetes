#!/bin/bash
# Q43 strace: one workload that calls kill in a loop and one that does nothing,
# both pinned to the worker so their processes can be traced there.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kubectl

NS=strace-lab
W=$(worker_node)
[[ -n "$W" ]] || { echo "no worker node found"; exit 1; }

on_worker command -v strace >/dev/null 2>&1 || {
  echo "strace is not installed on $W. Install it there with: sudo bash tools/install-tools.sh strace"
  exit 1
}
on_worker command -v crictl >/dev/null 2>&1 || {
  echo "warning: crictl is not on $W, so mapping a container to a pid will not work there."
}

kubectl create namespace "$NS" >/dev/null 2>&1 || true
kubectl -n "$NS" delete deploy worker-a worker-b --ignore-not-found >/dev/null 2>&1 || true

kubectl apply -n "$NS" -f - >/dev/null <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: worker-a
spec:
  replicas: 1
  selector: {matchLabels: {app: worker-a}}
  template:
    metadata: {labels: {app: worker-a}}
    spec:
      nodeName: $W
      containers:
      - name: worker
        image: busybox:1.36
        command: ["sh", "-c", "while true; do kill -0 1; sleep 1; done"]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: worker-b
spec:
  replicas: 1
  selector: {matchLabels: {app: worker-b}}
  template:
    metadata: {labels: {app: worker-b}}
    spec:
      nodeName: $W
      containers:
      - name: worker
        image: busybox:1.36
        command: ["sleep", "3600"]
YAML

kubectl -n "$NS" rollout status deploy/worker-a --timeout=90s >/dev/null 2>&1 || true
kubectl -n "$NS" rollout status deploy/worker-b --timeout=90s >/dev/null 2>&1 || true

DIR=$(course_dir 43)
rm -f "$DIR/pod.txt"

echo "Setup complete."
echo "  Worker node:   $W"
echo "  Namespace:     $NS holds deployments worker-a and worker-b, one replica each, both on $W"
echo "  One of the two calls the kill syscall about once a second. The names say nothing."
echo "  Deliverable:   $DIR/pod.txt   (one line: <namespace>/<pod-name>)"
echo "  Start with:    ssh $W 'crictl ps --name worker'"
echo "  Trace with:    strace -p <pid> -f -e trace=kill -o /tmp/trace.log"
