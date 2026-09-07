#!/bin/bash
# Q39 kubeadm patch upgrade: work out the newest kubelet patch the worker's own
# repositories offer. When there is nothing newer than what is running, the
# question cannot be solved on this cluster, so say so and exit non-zero rather
# than leaving a scenario behind that can never pass.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kubectl

W=$(worker_node)
[[ -n "$W" ]] || { echo "no worker node found"; exit 1; }

RC=0
OUT=$(on_worker bash -s <<'REMOTE'
set -e
command -v apt-cache >/dev/null 2>&1 || { echo "ERR=no-apt"; exit 3; }
CUR=$(kubelet --version 2>/dev/null | awk '{print $2}' | tr -d 'v')
[ -n "$CUR" ] || { echo "ERR=no-kubelet"; exit 4; }
echo "HOST=$(hostname)"
echo "CUR=$CUR"
MINOR=$(echo "$CUR" | cut -d. -f1,2)
apt-get update -qq >/dev/null 2>&1 || true
PKG=$(apt-cache madison kubelet 2>/dev/null | awk '{print $3}' | grep "^${MINOR}\." | sort -V | tail -1)
[ -n "$PKG" ] || { echo "ERR=no-candidate"; exit 5; }
NEW=${PKG%%-*}
echo "PKG=$PKG"
echo "NEW=$NEW"
NEWEST=$(printf '%s\n%s\n' "$CUR" "$NEW" | sort -V | tail -1)
if [ "$NEW" = "$CUR" ] || [ "$NEWEST" = "$CUR" ]; then
  echo "ERR=no-newer"
  exit 6
fi
REMOTE
) || RC=$?

field() { printf '%s\n' "$OUT" | grep -m1 "^$1=" | cut -d= -f2-; }
CUR=$(field CUR)
PKG=$(field PKG)
NEW=$(field NEW)

if [[ "$RC" -ne 0 ]]; then
  echo "Cannot set this question up on $W."
  case "$OUT" in
    *ERR=no-apt*)
      echo "  $W has no apt-cache, so there is no package repository to upgrade from."
      echo "  This question is written for a kubeadm cluster on Debian or Ubuntu." ;;
    *ERR=no-kubelet*)
      echo "  No kubelet binary was found on $W." ;;
    *ERR=no-candidate*)
      echo "  The repositories configured on $W list no kubelet package for the running"
      echo "  minor version. The pkgs.k8s.io repository is per minor version, so a node"
      echo "  pinned to an old one sees nothing." ;;
    *ERR=no-newer*)
      echo "  The kubelet on $W is already at $CUR, the newest patch its repositories offer."
      echo "  There is nothing to upgrade to, so this question has no solution here." ;;
    *)
      echo "  The worker did not answer as expected:"
      printf '%s\n' "$OUT" | sed 's/^/    /' ;;
  esac
  echo ""
  echo "Practise the upgrade on the Killercoda Killer Shell scenario 'Cluster Upgrade'"
  echo "instead, which ships a cluster one patch behind on purpose:"
  echo "  https://killercoda.com/killer-shell-cks"
  exit 1
fi

printf '%s\n' "$NEW" > "$CKS_STATE_DIR/q39.target"
printf '%s\n' "$PKG" > "$CKS_STATE_DIR/q39.package"

# A rerun after an abandoned attempt should start from a schedulable node.
kubectl uncordon "$W" >/dev/null 2>&1 || true

READY=$(kubectl get node "$W" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)

echo "Setup complete."
echo "  Worker node:      $W"
echo "  Node status:      Ready=${READY:-unknown}, schedulable"
echo "  Running kubelet:  $CUR"
echo "  Target version:   $NEW   (apt package $PKG)"
echo "  The target is also in $CKS_STATE_DIR/q39.target"
echo "  Upgrade kubelet and kubectl on $W to that version, and leave the node"
echo "  Ready and schedulable. The control plane is not part of this task."
