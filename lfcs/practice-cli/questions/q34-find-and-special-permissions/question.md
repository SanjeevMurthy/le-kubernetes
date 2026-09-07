# Q34. Locate files by owner and size, list SUID binaries, set SGID and sticky

The tree under `/opt/course/34/data` (`$COURSE_DIR/34/data` on this lab) holds files belonging to several accounts. The account `auditor` and the group `devs` already exist.

1. Copy every regular file under `/opt/course/34/data` that is owned by `auditor` and larger than 1 MiB into `/opt/course/34/found/`. Copy nothing else, and keep each file's original mode, owner and timestamps.
2. Write the full path of every SUID binary under `/usr/bin` to `/opt/course/34/suid.txt`, one path per line and nothing else on the line.
3. Turn `/opt/course/34/shared` into a collaboration directory: group `devs`, mode `3775`, so that files created inside it inherit the group `devs` and only a file's own owner can delete it.

The grader compares the contents of `found/` and the mode, owner and timestamp of each file in it, counts the lines of `suid.txt` against the SUID binaries it finds itself, reads `stat` on `shared`, and creates one file inside `shared` as `auditor` to confirm the group is inherited.
