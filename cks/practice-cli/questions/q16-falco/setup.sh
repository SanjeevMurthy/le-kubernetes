#!/bin/bash
# Q16 Falco: a workload that spawns shells in a container, and an empty local rules file.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kubectl
RF=/etc/falco/falco_rules.local.yaml
W=$(worker_node); [[ -n "$W" ]] || { echo "no worker node found"; exit 1; }

falco_unit() {
  local u
  for u in falco-modern-bpf falco; do
    if on_worker systemctl is-active --quiet "$u"; then echo "$u"; return 0; fi
  done
  return 1
}
UNIT=$(falco_unit) || {
  echo "Falco is not running on worker '$W' (neither falco-modern-bpf nor falco is active)."
  echo "Install and start it with: sudo bash tools/install-tools.sh falco"
  exit 1
}

# Back up the local rules file on the worker and locally, then hand over an empty one.
on_worker test -f "$RF" || on_worker touch "$RF"
backup_file "$RF" q16
on_worker test -f "$RF.cks-q16.bak" || on_worker cp -p "$RF" "$RF.cks-q16.bak"
printf '# Local Falco rules. Custom rules go here so the shipped rule files stay untouched.\n' \
  | on_worker tee "$RF" >/dev/null

kubectl create namespace falco-lab >/dev/null 2>&1 || true
kubectl apply -f - >/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shell-bot
  namespace: falco-lab
spec:
  replicas: 1
  selector:
    matchLabels: {app: shell-bot}
  template:
    metadata:
      labels: {app: shell-bot}
    spec:
      nodeSelector:
        kubernetes.io/hostname: $W
      containers:
      - name: bot
        image: busybox:1.36
        command: ["sh", "-c", "while true; do sh -c id; sleep 5; done"]
EOF
kubectl -n falco-lab rollout status deploy/shell-bot --timeout=120s >/dev/null 2>&1 || true
echo "Setup complete:"
echo "  - Falco is active on worker '$W' as unit '$UNIT'"
echo "  - $RF is empty (comment only); it is the file to add your rule to"
echo "  - deployment shell-bot in namespace falco-lab runs on '$W' and execs a shell every 5 seconds"
echo "  - no rule fires for it yet: journalctl -u $UNIT is quiet about shells in containers"
