# Q38. A service cannot start because another one owns its port (solution)

## Steps

**1. Ask the journal what the failure actually was.**

```bash
systemctl status webapp.service --no-pager -l
journalctl -u webapp.service -b --no-pager | tail -20
```

```
OSError: [Errno 98] Address already in use
webapp.service: Main process exited, code=exited, status=1/FAILURE
```

**2. Find who owns the port.**

```bash
ss -tlpn | grep ':8090'
```

```
LISTEN 0 5 0.0.0.0:8090 0.0.0.0:* users:(("python3",pid=1234,fd=3))
```

The process id is enough to name the unit:

```bash
systemctl status 1234 --no-pager
ps -o unit= -p 1234
```

Both report `legacy.service`.

**3. Record the answer.**

```bash
mkdir -p /opt/course/38
echo legacy.service > /opt/course/38/answer.txt
```

**4. Stop the old unit and make it unstartable.**

```bash
systemctl disable --now legacy.service
systemctl mask legacy.service
systemctl is-enabled legacy.service        # masked
```

**5. Start the application and make it persistent.**

```bash
systemctl enable --now webapp.service
systemctl is-active webapp.service
curl -s http://127.0.0.1:8090/
```

## Why

"Address already in use" is the one error message that points at another process rather than at the unit that failed. `ss -tlpn` is the fastest way to turn the port into a process id: `-t` TCP, `-l` listening, `-p` the owning process, `-n` numeric ports so nothing is translated into a service name. `systemctl status <pid>` then walks from the process back to the cgroup and prints the unit that owns it, which is quicker than reading unit files.

`stop` and `disable` are not the same as unstartable. `stop` ends this run. `disable` removes the `WantedBy` symlink so the unit is not pulled in at boot. Neither stops another unit from starting it as a dependency, and neither stops a person running `systemctl start`. `mask` is the one that does: it replaces the unit with a symlink to `/dev/null` under `/etc/systemd/system`, and every attempt to start it then fails with "Unit is masked". `systemctl is-enabled` reports `masked`, which is what a grader reads, and `systemctl unmask` is the way back.

Masking works here because `legacy.service` ships in the vendor directory `/usr/lib/systemd/system`. The symlink in `/etc/systemd/system` shadows it, exactly the way a local override shadows a packaged unit. A unit whose only file already sits in `/etc/systemd/system` cannot be masked without moving it first.

The persistent half of this task is two symlinks: `/etc/systemd/system/legacy.service` pointing at `/dev/null`, and `/etc/systemd/system/multi-user.target.wants/webapp.service` pointing at the unit. A host where `webapp` was only started, never enabled, comes back after a reboot with the port free and nothing serving on it.

## Verify

```bash
cat /opt/course/38/answer.txt
systemctl is-enabled legacy.service        # masked
readlink /etc/systemd/system/legacy.service   # /dev/null
systemctl is-active legacy.service         # inactive

systemctl is-active webapp.service         # active
systemctl is-enabled webapp.service        # enabled
ss -H -ltn | grep ':8090'
curl -s http://127.0.0.1:8090/             # webapp-ok
```

## Docs

- `man 1 systemctl` for `mask`, `unmask`, `disable`, `enable --now`, `is-active`, `is-enabled` and `status <pid>`
- `man 1 journalctl` for `-u` and `-b`
- `man 8 ss` for `-t`, `-l`, `-p` and `-n`
- `man 5 systemd.unit` for the unit directory search order and what masking does to it
- `man 5 systemd.service` for `Type`, `ExecStart` and `Restart`
