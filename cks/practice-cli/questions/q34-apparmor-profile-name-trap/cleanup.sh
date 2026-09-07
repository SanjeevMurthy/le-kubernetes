#!/bin/bash
# Q34 AppArmor name trap: unload and remove the profile, drop the namespace and
# the draft manifest.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete namespace apparmor-trap --ignore-not-found >/dev/null 2>&1
on_worker bash -s >/dev/null 2>&1 <<'REMOTE' || true
FILE=/etc/apparmor.d/k8s-lab-deny-write
[ -f "$FILE" ] && apparmor_parser -R "$FILE" 2>/dev/null
rm -f "$FILE"
REMOTE
rm -rf "$COURSE_DIR/34"
echo "Cleanup complete"
