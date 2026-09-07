#!/bin/bash
# Q36 archives and links: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

DIR="$COURSE_DIR/36"

echo "Checking the archive..."
check "project.tar.gz exists" test -s "$DIR/project.tar.gz"
check "project.tar.gz really is gzip compressed tar" tar tzf "$DIR/project.tar.gz"
LIST=$(tar tzf "$DIR/project.tar.gz" 2>/dev/null)
check_contains "the archive holds src/app.py" "src/app.py" "$LIST"
check_contains "the archive holds docs/readme.md" "docs/readme.md" "$LIST"
check_eq "the archive holds no .tmp file" "0" "$(printf '%s\n' "$LIST" | grep -c '\.tmp$')"

echo "Checking the extraction..."
check "extracted/v2 is a directory" test -d "$DIR/extracted/v2"
check_file_has "the extracted marker file is intact" '^bundle-v2-ok$' "$DIR/extracted/v2/VERSION"

echo "Checking the symbolic link..."
check "current is a symbolic link" test -L "$DIR/current"
check_eq "current resolves to extracted/v2" "$DIR/extracted/v2" \
  "$(readlink -f "$DIR/current" 2>/dev/null)"

echo "Checking the hard link..."
check "notes.hard exists" test -e "$DIR/notes.hard"
check_not "notes.hard is not a symbolic link" test -L "$DIR/notes.hard"
INO=$(stat -c %i "$DIR/notes.txt" 2>/dev/null)
check_eq "notes.hard shares the inode of notes.txt" "$INO" \
  "$(stat -c %i "$DIR/notes.hard" 2>/dev/null)"
check_eq "notes.txt now has a link count of 2" "2" \
  "$(stat -c %h "$DIR/notes.txt" 2>/dev/null)"

echo ""
echo "Note: this task has no configuration file to persist. The archive, the"
echo "extracted tree and the two links on disk are the whole deliverable."

summary
