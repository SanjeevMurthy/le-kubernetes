#!/bin/bash
# Q36 archives and links: build a source tree that contains files to exclude, an
# xz archive to unpack, and a file to hard link. Remove any earlier answer.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

DIR=$(course_dir 36)
STATE="$LFCS_STATE_DIR/q36"
mkdir -p "$STATE"

rm -rf "$DIR/project" "$DIR/extracted" "$STATE/stage"
rm -f "$DIR/project.tar.gz" "$DIR/bundle.tar.xz" "$DIR/notes.txt" "$DIR/notes.hard" "$DIR/current"

mkdir -p "$DIR/project/src" "$DIR/project/docs"
echo 'print("app")'   > "$DIR/project/src/app.py"
echo 'shared helpers' > "$DIR/project/src/lib.py"
echo 'the manual'     > "$DIR/project/docs/readme.md"
echo 'scratch'        > "$DIR/project/src/build.tmp"
echo 'scratch'        > "$DIR/project/docs/notes.tmp"

mkdir -p "$STATE/stage/v2"
echo 'bundle-v2-ok' > "$STATE/stage/v2/VERSION"
tar cJf "$DIR/bundle.tar.xz" -C "$STATE/stage" v2
rm -rf "$STATE/stage"

echo 'release notes for the lab build' > "$DIR/notes.txt"

if [[ ! -s "$DIR/bundle.tar.xz" ]]; then
  echo "Could not build bundle.tar.xz. Install the xz tools and run setup again."
  exit 1
fi

echo "Setup complete."
echo "  Source tree:   $DIR/project (three source files and two .tmp files)"
echo "  Archive to unpack: $DIR/bundle.tar.xz (holds v2/)"
echo "  File to link:  $DIR/notes.txt, link count $(stat -c %h "$DIR/notes.txt")"
echo "  Deliverables:  project.tar.gz, extracted/v2, current, notes.hard"
