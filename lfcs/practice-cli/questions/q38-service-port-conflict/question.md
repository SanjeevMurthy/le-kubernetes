# Q38. A service cannot start because another one owns its port

`webapp.service` will not start on this host. It is meant to serve on TCP port 8090 and it fails every time it is started. Another unit is already listening there.

1. Find out which unit holds port 8090 and why `webapp.service` fails.
2. Write the name of that unit, and nothing else, to `/opt/course/38/answer.txt` (`$COURSE_DIR/38/answer.txt` on this lab). Use the full unit name, for example `something.service`.
3. Stop that unit and make sure it can never start again: not now, not at the next boot, and not when another unit pulls it in as a dependency.
4. Get `webapp.service` running, and make sure it comes back at the next boot.

The grader reads `systemctl is-active`, `systemctl is-enabled`, the mask symlink under `/etc/systemd/system`, the enable symlink for `webapp`, the listener on port 8090, and what that listener answers.
