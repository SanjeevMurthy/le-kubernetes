#!/bin/bash
# Q16 Falco: drop the workload, restore the local rules file, restart Falco.
source "$(dirname "$0")/../../lib/env.sh"
RF=/etc/falco/falco_rules.local.yaml
kubectl delete namespace falco-lab --ignore-not-found >/dev/null 2>&1
if on_worker test -f "$RF.cks-q16.bak"; then
  on_worker cp -p "$RF.cks-q16.bak" "$RF"
  on_worker rm -f "$RF.cks-q16.bak"
fi
restore_file "$RF" q16
on_worker systemctl restart falco-modern-bpf >/dev/null 2>&1 \
  || on_worker systemctl restart falco >/dev/null 2>&1 || true
echo "Cleanup complete"
