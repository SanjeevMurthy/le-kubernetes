# Q40. A service fails its file-descriptor limit: raise it with a drop-in (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Read what the unit has now and what it is complaining about.**

```bash
systemctl status fdhog.service --no-pager -l
journalctl -u fdhog.service -b --no-pager | tail -10
systemctl show fdhog.service -p LimitNOFILE -p TasksMax
```

```
LimitNOFILE=16
TasksMax=...
```

**2. Write the drop-in.**

```bash
mkdir -p /etc/systemd/system/fdhog.service.d
cat > /etc/systemd/system/fdhog.service.d/limits.conf <<'DROPIN'
[Service]
LimitNOFILE=65536
TasksMax=4096
DROPIN
```

`systemctl edit fdhog.service` opens an editor on `/etc/systemd/system/fdhog.service.d/override.conf` and writes the same thing. Either filename is fine as long as it ends in `.conf`.

**3. Reload and restart, then confirm.**

```bash
systemctl daemon-reload
systemctl restart fdhog.service
systemctl show fdhog.service -p LimitNOFILE -p TasksMax
systemctl cat fdhog.service            # the vendor unit and every drop-in that applied
```

## Why

A drop-in is a fragment that systemd merges on top of the vendor unit. Anything in `/etc/systemd/system/<unit>.d/*.conf` wins over `/usr/lib/systemd/system/<unit>`, and the vendor file stays untouched, so a package upgrade replaces the unit and keeps the local change. Editing the vendor file instead loses the change at the next upgrade, and `systemctl edit --full` copies the whole unit into `/etc` where it then stops picking up vendor fixes entirely.

`daemon-reload` alone changes nothing for a running process. Limits are applied by the kernel when the process is created, so the service has to restart before it sees the new ceiling. `systemctl show` reports what the next start will use; `/proc/<pid>/limits` reports what the running process actually got, and those two disagree exactly when a reload has happened but a restart has not.

Neither `ulimit` nor `/etc/security/limits.conf` reaches this service. PAM applies `limits.conf` at login, and systemd starts services with no login session at all, so a `nofile` line in `limits.conf` for the service account has no effect whatsoever. `LimitNOFILE` is the systemd spelling; `nofile` is the PAM spelling; mixing them silently does nothing. The login side of that pair is drilled in Q44.

`LimitNOFILE=65536` sets both the soft and the hard limit. `LimitNOFILE=4096:65536` sets soft and hard separately, which is what an application that raises its own limit at start wants. `TasksMax` is a cgroup control rather than an rlimit, so it caps threads and processes together, and `DefaultLimitNOFILE` in `/etc/systemd/system.conf` is the host-wide fallback for units that set nothing.

## Verify

```bash
systemctl is-active fdhog.service                       # active
systemctl show fdhog.service -p LimitNOFILE -p TasksMax # 65536 and 4096
systemctl cat fdhog.service                             # lists the drop-in path
cat /etc/systemd/system/fdhog.service.d/*.conf

MAINPID=$(systemctl show -p MainPID --value fdhog.service)
grep 'Max open files' /proc/"$MAINPID"/limits
journalctl -u fdhog.service -b --no-pager | tail -3     # "opened 100 descriptors"
```

## Docs

- `man 5 systemd.exec` for every `Limit*` directive and the `soft:hard` syntax
- `man 5 systemd.resource-control` for `TasksMax`, `MemoryMax` and `CPUQuota`
- `man 5 systemd.unit` for drop-in directories and the order in which they are merged
- `man 1 systemctl` for `edit`, `cat`, `show`, `daemon-reload` and `restart`
- `man 5 systemd-system.conf` for `DefaultLimitNOFILE`
- `man 5 proc` for `/proc/<pid>/limits`
