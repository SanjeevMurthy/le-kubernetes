# Q03. Scheduled jobs for a user, root, and a one-off (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. The job for another user.** `crontab -u` is how root edits somebody else's crontab without becoming them.

```bash
EDITOR=vi crontab -e -u backupop
```

Add one line and save:

```
30 2 * * * /usr/local/bin/backup.sh
```

The same thing without an editor, which is faster under time pressure but replaces the whole crontab:

```bash
printf '30 2 * * * /usr/local/bin/backup.sh\n' | crontab -u backupop -
```

**2. The job for root.**

```bash
printf '0 4 * * 0 /usr/local/bin/cleanup.sh\n' | crontab -
```

Sunday is day 0. Day 7 and the name `sun` also work.

**3. The one-off job.**

```bash
echo /usr/local/bin/backup.sh | at 23:00
atq
at -c 1        # show what job 1 will actually run
```

**4. Make sure the scheduler itself comes back after a reboot.**

```bash
systemctl enable --now atd
systemctl is-enabled atd
```

## Why

A user crontab has five time fields and then the command: minute, hour, day of month, month, day of week. A file in `/etc/cron.d` looks almost identical but carries a sixth field, the user, between the time fields and the command. Putting a user field in a user crontab, or leaving it out of a `/etc/cron.d` file, produces a job that never runs and no error anywhere obvious.

`crontab -e -u backupop` writes the spool file for that user, `/var/spool/cron/crontabs/backupop` on the Debian family or `/var/spool/cron/backupop` on the RHEL family. Editing that file directly skips the syntax check that `crontab` performs and skips the notification to the cron daemon, so use the command.

`at` hands a single job to `atd` and forgets it. The job text lives under the at spool directory, so it survives a reboot, but only if `atd` is enabled and therefore running again to execute it. That is why the third part of this task is really two parts.

The dangerous neighbour of the commands above is `crontab -r -u <user>`, which deletes that user's crontab immediately and without a prompt. It sits one key away from `-e` on the keyboard.

Cron runs jobs with a minimal `PATH` and no login shell, so every command in a crontab should be an absolute path, exactly as written here.

## Verify

```bash
crontab -l -u backupop
crontab -l
atq
systemctl is-enabled atd

cat /var/spool/cron/crontabs/backupop 2>/dev/null || cat /var/spool/cron/backupop
```

## Docs

- `man 5 crontab` for the five field order and the special strings such as `@daily`
- `man 1 crontab` for `-e`, `-l`, `-u` and the destructive `-r`
- `man 8 cron` for how the daemon picks up changes
- `man 1 at` for `at`, `atq`, `atrm` and the time expressions such as `now + 2 hours`
- `man 8 atd` for the daemon and its spool directory
