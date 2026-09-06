#!/bin/bash
# Q17 audit logging: restore the apiserver manifest and remove the audit files.
source "$(dirname "$0")/../../lib/env.sh"
restore_file "$KAS_MANIFEST" q17
wait_apiserver
rm -rf /etc/kubernetes/audit /var/log/kubernetes/audit
echo "Cleanup complete"
