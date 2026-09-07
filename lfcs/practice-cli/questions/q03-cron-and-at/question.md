# Q03. Scheduled jobs for a user, root, and a one-off

The user `backupop` and the scripts `/usr/local/bin/backup.sh` and `/usr/local/bin/cleanup.sh` already exist. Schedule three jobs.

1. As the user `backupop`, run `/usr/local/bin/backup.sh` every day at 02:30.
2. As `root`, run `/usr/local/bin/cleanup.sh` every Sunday at 04:00.
3. Queue a one-off run of `/usr/local/bin/backup.sh` for 23:00 today using `at`. Make sure the `at` daemon is enabled so a queued job still runs after a reboot.

Do not log in as `backupop` to do the first one, and do not edit the spool files by hand.

The grader reads `crontab -l -u backupop`, `crontab -l` for root, the crontab files under the spool directory, and `atq`.
