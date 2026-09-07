# Q11. A service fails to start: find why, fix it, make the journal persistent

`billing.service` is installed and enabled, and it will not start. The unit file and the script it runs are both at the paths you would expect: `/etc/systemd/system/billing.service` and `/opt/billing/billing.sh`.

1. Use the journal to find out why it fails. Do not guess from the unit file.
2. Copy the line that explains the failure into `/opt/course/11/error.txt` (`$COURSE_DIR/11/error.txt` on this lab). The exit code or the reason must appear in it verbatim.
3. Fix the cause and get the service running. It must also still be enabled.
4. This host currently throws its journal away at every reboot, which is why nobody could look at yesterday's failure. Make the journal persistent, so `journalctl -b -1` works after the next reboot. The grader accepts either storage setting that does this: `Storage=persistent`, or `Storage=auto` with `/var/log/journal` in place. It reads the setting out of `/etc/systemd/journald.conf` or a drop-in under `/etc/systemd/journald.conf.d/`, so leaving `Storage=volatile` on disk and only restarting the daemon scores nothing.

Do not change `ExecStart` and do not rewrite the unit to work around the problem.
