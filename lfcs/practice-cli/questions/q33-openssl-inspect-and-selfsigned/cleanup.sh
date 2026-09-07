#!/bin/bash
# Q33 openssl: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

rm -rf /etc/ssl/lab
rm -rf "${COURSE_DIR:?}/33"

echo "Cleanup complete. /etc/ssl/lab and $COURSE_DIR/33 are gone."
