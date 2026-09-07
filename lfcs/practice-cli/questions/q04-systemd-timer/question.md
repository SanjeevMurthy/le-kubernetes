# Q04. A timer that runs a script every 15 minutes

The script `/usr/local/bin/logsync.sh` already exists and is executable. It runs once and exits.

Schedule it with systemd, not with cron.

1. Create `logsync.service`, a one-shot unit that runs `/usr/local/bin/logsync.sh`.
2. Create `logsync.timer`, which triggers that service every 15 minutes, on the hour and at 15, 30 and 45 minutes past.
3. The timer must be running now and must start again by itself after a reboot.

Put both units in `/etc/systemd/system/`.

The grader reads `systemctl is-active logsync.timer`, `systemctl is-enabled logsync.timer`, `systemctl show logsync.timer -p TimersCalendar`, and the unit files themselves.
