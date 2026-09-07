# Q10. Write a service unit for an application (solution)

## Steps

**1. Write the unit.**

```bash
cat >/etc/systemd/system/inventory.service <<'EOF'
[Unit]
Description=Inventory API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=inventory
Group=inventory
WorkingDirectory=/opt/inventory
ExecStart=/opt/inventory/server.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

**2. Load it and start it.**

```bash
systemctl daemon-reload
systemctl enable --now inventory.service
```

**3. Check it before moving on.**

```bash
systemctl status inventory.service --no-pager
ss -H -ltnp 'sport = :9090'
systemctl show inventory.service -p User -p Restart -p MainPID
```

If it failed, the reason is in `journalctl -u inventory.service -b --no-pager`, not in `systemctl status` alone.

## Why

The three sections do different jobs. `[Unit]` carries the description and the ordering, `[Service]` says how to run the process, and `[Install]` says what enabling the unit should hook it into. A unit with no `[Install]` section cannot be enabled at all: `systemctl enable` refuses with "no installation config", which is a confusing error until you know it means that one missing section.

`WantedBy=multi-user.target` is what makes `systemctl enable` create the symlink `/etc/systemd/system/multi-user.target.wants/inventory.service`. That symlink is the persistence. `systemctl start` on its own runs the service now and leaves nothing behind, so the service is gone after a reboot even though everything looked right at the time.

`User=inventory` drops the privileges of the process. It does not change file ownership, so the application still needs read access to whatever it serves, which is why `/opt/inventory` is owned by that account. Checking the owner of the running process, rather than trusting the unit, is how a grader catches a unit that failed to start as the intended user and silently ran as root.

`Restart=on-failure` restarts the service when it exits non-zero or is killed by a signal, and leaves it alone after a clean exit. `Restart=always` also restarts after a clean exit, which is wrong for a job that is meant to finish. `RestartSec` sets the pause between attempts and stops a broken service from spinning.

`Type=simple` tells systemd the process stays in the foreground, which this one does because the script ends in `exec`. A program that forks into the background needs `Type=forking` and usually `PIDFile=`, otherwise systemd tracks a process that has already exited.

Two habits worth carrying: `ExecStart` is not a shell, so a pipe, a glob, a redirection or a `$VAR` needs `ExecStart=/bin/bash -c '...'`; and every edit to a unit needs `systemctl daemon-reload` before it means anything.

## Verify

```bash
systemctl is-active inventory.service     # active
systemctl is-enabled inventory.service    # enabled
systemctl cat inventory.service
systemctl show inventory.service -p User -p Restart -p ExecStart

ss -H -ltn 'sport = :9090'
curl -s http://localhost:9090/
ps -o pid,uid,user:20,args -p "$(systemctl show inventory.service -p MainPID --value)"
ls -l /etc/systemd/system/multi-user.target.wants/
```

## Docs

- `man 5 systemd.service` for `Type`, `ExecStart`, `Restart` and `RestartSec`
- `man 5 systemd.exec` for `User`, `Group` and `WorkingDirectory`
- `man 5 systemd.unit` for `[Install]`, `WantedBy`, `After` and `Wants`
- `man 5 systemd.resource-control` for `MemoryMax` and the other limits
- `man 1 systemctl` for `daemon-reload`, `enable --now`, `cat`, `show` and `edit`
- `man 8 ss` for `-ltnp` and the `sport` filter
