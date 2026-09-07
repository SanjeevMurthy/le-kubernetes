#!/bin/bash
# Q30 seccomp deny mkdir: create the seccomp root on the worker and an empty
# lab namespace. Writing the profile and the Pod is the task.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
require_tool kubectl

NS=seccomp-lab
PROFILE=/var/lib/kubelet/seccomp/profiles/no-mkdir.json

W=$(worker_node)
[[ -n "$W" ]] || { echo "no worker node found; this question needs a cluster with a separate worker"; exit 1; }

# Only the directory, never the profile: the profile is the answer.
on_worker mkdir -p /var/lib/kubelet/seccomp/profiles
on_worker rm -f "$PROFILE"

kubectl create namespace "$NS" >/dev/null 2>&1 || true
kubectl -n "$NS" delete pod sandboxed --ignore-not-found --now >/dev/null 2>&1 || true

DIR=$(course_dir 30)
rm -f "$DIR/result.txt"

echo "Setup complete on worker '$W':"
echo "  seccomp root:  /var/lib/kubelet/seccomp"
echo "  profiles dir:  /var/lib/kubelet/seccomp/profiles (exists, empty)"
echo "  localhostProfile paths are relative to the seccomp root, so yours is 'profiles/no-mkdir.json'."
echo "  Namespace:     $NS is empty; pod 'sandboxed' does not exist"
echo "  Deliverable:   $DIR/result.txt"
echo "  The Pod has to land on $W, so set spec.nodeName or a nodeSelector."
