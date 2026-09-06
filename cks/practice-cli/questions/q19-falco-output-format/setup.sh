#!/bin/bash
# Q19 Falco output format: deploy a workload that trips a shipped rule, and put
# the local rules file back to a clean state.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kubectl

W=$(worker_node)
[[ -n "$W" ]] || { echo "no worker node found"; exit 1; }

on_worker test -f /etc/falco/falco.yaml || { echo "Falco is not installed on $W. Run: sudo bash tools/install-tools.sh falco"; exit 1; }

backup_file /etc/falco/falco_rules.local.yaml q19
backup_file /etc/falco/falco.yaml q19
on_worker bash -c 'cp -p /etc/falco/falco_rules.local.yaml /etc/falco/falco_rules.local.yaml.q19bak 2>/dev/null || true'

kubectl create namespace falco-lab 2>/dev/null || true
kubectl -n falco-lab delete deploy secret-reader --ignore-not-found >/dev/null 2>&1
kubectl apply -n falco-lab -f - >/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata: {name: secret-reader}
spec:
  replicas: 1
  selector: {matchLabels: {app: secret-reader}}
  template:
    metadata: {labels: {app: secret-reader}}
    spec:
      nodeName: $W
      containers:
      - name: reader
        image: busybox:1.36
        command: ["sh", "-c", "while true; do cat /etc/shadow >/dev/null 2>&1; sleep 3; done"]
EOF
kubectl -n falco-lab rollout status deploy/secret-reader --timeout=90s >/dev/null 2>&1 || true

DIR=$(course_dir 19)
echo "Setup complete."
echo "  Worker node:      $W"
echo "  Noisy workload:   deployment secret-reader in namespace falco-lab (reads /etc/shadow every 3s)"
echo "  Falco rules:      /etc/falco/falco_rules.yaml (shipped, do not edit)"
echo "                    /etc/falco/falco_rules.local.yaml (your overrides, loads last)"
echo "  Falco config:     /etc/falco/falco.yaml"
echo "  Deliverable:      $DIR/falco.log"
