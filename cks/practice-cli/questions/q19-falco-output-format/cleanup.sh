#!/bin/bash
# Q19 Falco output format: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete namespace falco-lab --ignore-not-found >/dev/null 2>&1
restore_file /etc/falco/falco_rules.local.yaml q19
restore_file /etc/falco/falco.yaml q19
on_worker bash -c 'if [ -f /etc/falco/falco_rules.local.yaml.q19bak ]; then mv /etc/falco/falco_rules.local.yaml.q19bak /etc/falco/falco_rules.local.yaml; fi' 2>/dev/null
on_worker bash -c 'systemctl restart falco-modern-bpf 2>/dev/null || systemctl restart falco 2>/dev/null' 2>/dev/null
rm -rf "$COURSE_DIR/19"
echo "Cleanup complete"
