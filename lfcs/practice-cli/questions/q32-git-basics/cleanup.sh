#!/bin/bash
# Q32 git: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

rm -rf "${COURSE_DIR:?}/32"

echo "Cleanup complete. The bare repository, the clone and the seed tree under $COURSE_DIR/32 are gone."
echo "A git identity you set with 'git config --global' is still in your ~/.gitconfig; remove it by hand if you want the host back exactly."
