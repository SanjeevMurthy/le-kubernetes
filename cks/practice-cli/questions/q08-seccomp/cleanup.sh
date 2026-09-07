#!/bin/bash
# Q8 seccomp: remove the lab namespace and the profile written by setup.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete namespace seccomp-lab --ignore-not-found >/dev/null 2>&1
on_worker bash -c 'rm -f /var/lib/kubelet/seccomp/profiles/audit.json
rmdir /var/lib/kubelet/seccomp/profiles 2>/dev/null
rmdir /var/lib/kubelet/seccomp 2>/dev/null
true' 2>/dev/null
echo "Cleanup complete"
