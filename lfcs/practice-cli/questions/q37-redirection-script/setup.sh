#!/bin/bash
# Q37 redirection: provide an empty deliverable directory and remove any script
# or output left from an earlier attempt.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

DIR=$(course_dir 37)

rm -f "$DIR/report.sh" "$DIR/report.txt" "$DIR/errors.txt"
rm -rf "$DIR/missing"

echo "Setup complete."
echo "  Script to write:  $DIR/report.sh, executable, shebang #!/bin/bash"
echo "  Files it creates: $DIR/report.txt (df, free, then the date) and $DIR/errors.txt"
echo "  $DIR/missing does not exist, and the script must try to list it"
echo "  The grader runs the script from another directory, so use absolute paths"
