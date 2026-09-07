# Q11. A service fails to start: find why, fix it, make the journal persistent (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Ask the journal, not the unit file.**

```bash
systemctl status billing.service --no-pager
journalctl -u billing.service -b --no-pager
```

Two lines matter:

```
billing.service: Failed to execute /opt/billing/billing.sh: Permission denied
billing.service: Main process exited, code=exited, status=203/EXEC
```

**2. Record the finding.**

```bash
mkdir -p /opt/course/11
journalctl -u billing.service -b --no-pager | grep -E '203/EXEC|Permission denied' > /opt/course/11/error.txt
cat /opt/course/11/error.txt
```

**3. Confirm the cause and fix it.**

```bash
ls -l /opt/billing/billing.sh      # -rw-r--r--, no x anywhere
head -1 /opt/billing/billing.sh    # the shebang is fine
chmod +x /opt/billing/billing.sh

systemctl start billing.service
systemctl is-active billing.service
```

**4. Make the journal survive a reboot.** Both halves are needed.

```bash
mkdir -p /var/log/journal
sed -i 's/^#\?Storage=.*/Storage=persistent/' /etc/systemd/journald.conf
grep '^Storage=' /etc/systemd/journald.conf

systemctl restart systemd-journald
journalctl --header | grep -i 'journal file'
```

`Storage=auto` is the other correct answer, and the grader takes it: `auto` means "use the disk when `/var/log/journal` exists", so the directory plus `Storage=auto` is persistent too. What fails is leaving `Storage=volatile` in the file, whatever the directory looks like.

## Why

Exit code 203 is systemd's own code, not the application's. It means systemd could not execute the thing named in `ExecStart` at all: the file does not exist, has no executable bit, has a shebang pointing at a missing interpreter, or is on a filesystem mounted `noexec`. Learning the small set of systemd exit codes turns a vague "it will not start" into a two-command diagnosis: 203 is exec, 200 to 242 are systemd's range, and anything else came from the program itself.

The reason the task insists on the journal rather than on reading the unit is that the unit file looks completely correct here. Nothing about `ExecStart=/opt/billing/billing.sh` hints at a missing permission bit. Only the log says `Permission denied`.

A persistent journal is also two things, not one. `Storage=persistent` in `/etc/systemd/journald.conf` tells journald to use the disk, and `/var/log/journal` is the directory it writes into. With the default `Storage=auto` the directory alone is enough, because `auto` means "use the disk if the directory exists". With `Storage=volatile`, as on this host, the journal lives in `/run/log/journal` and is destroyed at every boot. That is exactly why `journalctl -b -1` reports "Failed to look up boot" on a host nobody has configured: the previous boot's journal no longer exists to look up.

Restarting `systemd-journald` applies the change immediately, so you do not need a reboot to prove it worked. `journalctl --header` then names the files it is reading, which will be under `/var/log/journal`.

The neighbouring skill is size control, since a persistent journal grows: `journalctl --disk-usage`, then `journalctl --vacuum-size=200M` or `--vacuum-time=14d`, or `SystemMaxUse=` in the same configuration file.

## Verify

```bash
systemctl is-active billing.service       # active
systemctl is-enabled billing.service      # enabled
ls -l /opt/billing/billing.sh             # the x bit is there
cat /opt/course/11/error.txt

grep '^Storage=' /etc/systemd/journald.conf
ls -ld /var/log/journal
ls /var/log/journal/*/ | head
journalctl -u billing.service -b --no-pager | tail -3
```

## Docs

- `man 1 journalctl` for `-u`, `-b`, `-p`, `--since`, `--list-boots`, `--header` and `--vacuum-size`
- `man 5 journald.conf` for `Storage`, `SystemMaxUse` and the drop-in directory
- `man 8 systemd-journald.service` for where the journal lives in each storage mode
- `man 5 systemd.exec`, section "Process Exit Codes", for what 203/EXEC means
- `man 5 systemd.service` for `ExecStart` and `Restart`
- `man 8 logrotate` and `man 5 logrotate.conf` for application log files, which the journal does not manage
