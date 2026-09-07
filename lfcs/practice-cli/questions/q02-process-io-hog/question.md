# Q02. Find the disk-reading process, record its PID, lower its priority

Something on this host is reading from disk without pause and the storage team wants it identified before the next batch window.

1. Find the single process that is generating the disk read traffic. `pidstat` is installed.
2. Write its PID, and nothing else, to `/opt/course/2/pid.txt` (`$COURSE_DIR/2/pid.txt` on this lab).
3. Lower its scheduling priority to a nice value of `15`. Do not kill it and do not stop it.

The grader reads the PID from the file and then reads `ps -o ni= -p <pid>`.
