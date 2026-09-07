# Q37. A script with separate stdout and stderr files

Write `/opt/course/37/report.sh` (`$COURSE_DIR/37/report.sh` on this lab). It must be executable, start with the `#!/bin/bash` shebang, and behave the same no matter which directory it is run from.

Running it must:

1. Write the output of `df -h` to `/opt/course/37/report.txt`, replacing whatever that file held before.
2. Append the output of `free -m` to the same file.
3. Append the current date to the same file, as the last line.
4. Run `ls /opt/course/37/missing`, a path that does not exist.
5. Send the error output of every command in the script to `/opt/course/37/errors.txt` instead of to the terminal.
6. Print `DONE` on standard output, and nothing else.

The grader checks the shebang and the executable bit, parses the script with `bash -n`, then runs it from a different directory and reads its standard output, its standard error, and both files it produced.
