#!/bin/bash
# Q31 Falco hunt: run one noisy workload and one innocent workload on the worker
# so that the alert has to be traced back to a single Pod.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kubectl

NS=falco-hunt
W=$(worker_node)
[[ -n "$W" ]] || { echo "no worker node found"; exit 1; }

on_worker test -f /etc/falco/falco.yaml || {
  echo "Falco is not installed on $W. Install it there with: sudo bash tools/install-tools.sh falco"
  exit 1
}

# Falco has to be running for the question to be answerable at all.
on_worker bash -s >/dev/null 2>&1 <<'REMOTE' || true
systemctl is-active --quiet falco-modern-bpf && exit 0
systemctl is-active --quiet falco && exit 0
systemctl start falco-modern-bpf 2>/dev/null || systemctl start falco 2>/dev/null || true
REMOTE

kubectl create namespace "$NS" >/dev/null 2>&1 || true
kubectl -n "$NS" delete deploy inventory catalog --ignore-not-found >/dev/null 2>&1

kubectl apply -n "$NS" -f - >/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inventory
spec:
  replicas: 1
  selector: {matchLabels: {app: inventory}}
  template:
    metadata: {labels: {app: inventory}}
    spec:
      nodeName: $W
      containers:
      - name: inventory
        image: busybox:1.36
        command: ["sh", "-c", "while true; do cat /etc/shadow >/dev/null 2>&1; sleep 2; done"]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog
spec:
  replicas: 1
  selector: {matchLabels: {app: catalog}}
  template:
    metadata: {labels: {app: catalog}}
    spec:
      nodeName: $W
      containers:
      - name: catalog
        image: nginx:1.27
        ports:
        - containerPort: 80
EOF

kubectl -n "$NS" rollout status deploy/inventory --timeout=90s >/dev/null 2>&1 || true
kubectl -n "$NS" rollout status deploy/catalog --timeout=90s >/dev/null 2>&1 || true

DIR=$(course_dir 31)
rm -f "$DIR/offender.txt"

echo "Setup complete."
echo "  Worker node:     $W"
echo "  Namespace:       $NS"
echo "  Deployments:     inventory (1 replica) and catalog (1 replica), both pinned to $W"
echo "  One of them trips the shipped rule 'Read sensitive file untrusted' every 2 seconds."
echo "  Falco journal:   journalctl -u falco-modern-bpf -u falco --since '-3 min' --no-pager"
echo "  Deliverable:     $DIR/offender.txt  (one line: <namespace>/<pod-name>)"
echo "  Give Falco about 30 seconds to produce the first alerts."
