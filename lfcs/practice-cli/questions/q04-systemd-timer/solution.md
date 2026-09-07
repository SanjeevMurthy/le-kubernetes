# Q04. A timer that runs a script every 15 minutes (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. The service that does the work.**

```bash
cat >/etc/systemd/system/logsync.service <<'EOF'
[Unit]
Description=Sync logs

[Service]
Type=oneshot
ExecStart=/usr/local/bin/logsync.sh
EOF
```

**2. The timer that schedules it.**

```bash
cat >/etc/systemd/system/logsync.timer <<'EOF'
[Unit]
Description=Run logsync every 15 minutes

[Timer]
OnCalendar=*:0/15
Persistent=true
Unit=logsync.service

[Install]
WantedBy=timers.target
EOF
```

**3. Load and start it.**

```bash
systemctl daemon-reload
systemctl enable --now logsync.timer
```

**4. Confirm the schedule before moving on.**

```bash
systemd-analyze calendar '*:0/15'
systemctl list-timers --all | grep logsync
```

## Why

A systemd timer is always a pair. The `.service` unit says what to run and the `.timer` unit says when. Enabling the `.service` instead of the `.timer` is the classic wrong answer: it either does nothing useful or, with a one-shot service, runs the job once at boot and never again. The unit that gets enabled is the timer.

`OnCalendar=*:0/15` reads as "any hour, at minute 0 and every 15th minute after it", which is 00, 15, 30 and 45. `systemd-analyze calendar` expands the expression and prints the next elapse time, which is the quickest way to prove an expression means what you think before the grader disagrees.

`Persistent=true` stores the last trigger time on disk. If the host was off when a run was due, the job runs once shortly after the next boot instead of being skipped silently. Cron has no equivalent.

`Unit=logsync.service` is optional when the timer and the service share a base name, since systemd falls back to the timer's own name with a `.service` suffix. Writing it out costs one line and removes any doubt.

Enabling the timer creates the symlink `/etc/systemd/system/timers.target.wants/logsync.timer`. That symlink is the persistence: `systemctl start` alone leaves nothing on disk and the timer is gone after a reboot.

Every edit to a unit file needs `systemctl daemon-reload`, otherwise systemd keeps running the version it already parsed and the change looks ignored.

## Verify

```bash
systemctl is-active logsync.timer      # active
systemctl is-enabled logsync.timer     # enabled
systemctl show logsync.timer -p TimersCalendar
systemctl list-timers --all | grep logsync
ls -l /etc/systemd/system/timers.target.wants/
journalctl -u logsync.service --no-pager | tail -5
```

## Docs

- `man 5 systemd.timer` for `OnCalendar`, `OnBootSec`, `Persistent` and `Unit`
- `man 7 systemd.time` for the calendar expression grammar
- `man 5 systemd.service` for `Type=oneshot`
- `man 5 systemd.unit` for `[Install]` and `WantedBy`
- `man 1 systemctl` for `list-timers`, `cat`, `daemon-reload` and `enable --now`
- `man 1 systemd-analyze` for `calendar`
