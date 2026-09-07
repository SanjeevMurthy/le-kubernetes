#!/bin/bash
# Q38 SBOM: remove the deliverables setup made room for.
source "$(dirname "$0")/../../lib/env.sh"
rm -rf "$COURSE_DIR/38"
echo "Cleanup complete"
