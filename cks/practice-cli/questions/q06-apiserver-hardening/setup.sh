#!/bin/bash
# Q6 apiserver hardening: seed three insecure flags on the kube-apiserver
# static pod and wait for the API server to come back with them.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_node_root
[[ -f "$KAS_MANIFEST" ]] || { echo "missing $KAS_MANIFEST — run this on the control-plane node"; exit 1; }

backup_file "$KAS_MANIFEST" q06

# set_flag <name> <value> — replace the flag if present, otherwise add it
# straight after the "- kube-apiserver" command line.
set_flag() {
  local name="$1" value="$2"
  if grep -q -- "- --$name=" "$KAS_MANIFEST"; then
    sed -i -E "s|- --$name=.*|- --$name=$value|" "$KAS_MANIFEST"
  else
    sed -i -E "s|^( *)- kube-apiserver\$|\\1- kube-apiserver\\n\\1- --$name=$value|" "$KAS_MANIFEST"
  fi
}

set_flag anonymous-auth true
set_flag authorization-mode AlwaysAllow
set_flag profiling true
wait_apiserver

echo "Setup complete on node $(hostname):"
echo "  manifest: $KAS_MANIFEST"
echo "  --anonymous-auth=true            (unauthenticated callers are accepted)"
echo "  --authorization-mode=AlwaysAllow (every request is authorized)"
echo "  --profiling=true                 (/debug/pprof is exposed)"
echo "  The API server is up with these flags; harden it and bring it back ready."
