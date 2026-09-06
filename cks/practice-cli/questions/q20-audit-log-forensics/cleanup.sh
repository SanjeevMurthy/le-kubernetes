#!/bin/bash
# Q20 audit forensics: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
rm -rf "$COURSE_DIR/20"
rm -f "$CKS_STATE_DIR/q20.answer"
echo "Cleanup complete"
