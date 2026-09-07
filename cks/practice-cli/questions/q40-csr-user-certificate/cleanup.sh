#!/bin/bash
# Q40 CSR: drop the request, the namespace (which takes the Role and the
# RoleBinding with it) and the key material.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete csr jane --ignore-not-found >/dev/null 2>&1
kubectl delete namespace csr-lab --ignore-not-found >/dev/null 2>&1
rm -rf "$COURSE_DIR/40"
echo "Cleanup complete"
