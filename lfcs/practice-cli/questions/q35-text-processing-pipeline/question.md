# Q35. Reports from a log with grep, sort, uniq, sed and awk

Three input files sit in `/opt/course/35` (`$COURSE_DIR/35` on this lab): `access.log`, `urls.txt` and `data.csv`. Each line of `access.log` starts with the client address and carries the HTTP status code in the field after the quoted request.

1. Write `/opt/course/35/top-ips.txt`: the five client addresses that appear most often in `access.log`, most frequent first, in the layout `uniq -c` produces, which is the count followed by the address.
2. Write `/opt/course/35/errors.txt`: every line of `access.log` whose status code is in the 500 range, unchanged and in the order they appear in the log.
3. Edit `urls.txt` in place so that every `http://` becomes `https://`, and leave the original untouched beside it as `urls.txt.bak`.
4. Write `/opt/course/35/col3.txt`: the third comma separated field of every line of `data.csv` except the header line, in the original order.

The grader compares each output with the result it computes from the same inputs, so extra labels, sorted output where none was asked for, or a missing backup all fail.
