# Q15. Time source, NTP serving, timezone (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Find the file and the unit for this distribution.**

```bash
ls -l /etc/chrony.conf /etc/chrony/chrony.conf 2>/dev/null
systemctl list-unit-files | grep -E '^chrony'
```

Ubuntu ships `/etc/chrony/chrony.conf` and a unit called `chrony`. Rocky ships `/etc/chrony.conf` and a unit called `chronyd`.

**2. Add the source and the allow rule.**

```bash
vim /etc/chrony/chrony.conf        # /etc/chrony.conf on Rocky
```

```
server time.google.com iburst
allow 192.168.56.0/24
```

Both lines can also be appended without an editor:

```bash
printf 'server time.google.com iburst\nallow 192.168.56.0/24\n' >> /etc/chrony/chrony.conf
```

**3. Start the daemon and make it come back at boot.**

```bash
systemctl enable --now chrony      # chronyd on Rocky
systemctl is-active chrony; systemctl is-enabled chrony
```

**4. Set the timezone.**

```bash
timedatectl list-timezones | grep -i kolkata
timedatectl set-timezone Asia/Kolkata
timedatectl
```

**5. Watch the source come up.**

```bash
chronyc sources -v
chronyc tracking
chronyc makestep                   # only if the offset is large and you want it corrected now
```

Straight after a restart the source can still show `?` in the first column while the first exchanges complete. That is normal, and `iburst` is what shortens it.

## Why

Two separate ideas share one configuration file. A `server` or `pool` line makes this host a client of a time source. An `allow` line makes it a server for someone else. A task that says "the host must serve time to the lab network" is only complete with the `allow`, and nothing in `chronyc tracking` shows whether it is there, which is why the grader reads the file.

`date -s` sets the system clock directly and fights the daemon. chronyd notices the jump and slews or steps the clock back, so the change either disappears or leaves the clock oscillating. When the clock is genuinely wrong, `chronyc makestep` asks the daemon to correct it in one jump, which is the supported way to do the same thing.

`timedatectl set-timezone` relinks `/etc/localtime` to the matching file under `/usr/share/zoneinfo`. That symlink is the persistent form, so the timezone half of this task needs no extra file. What does need care is that a host can only have one time daemon: `chrony` and `systemd-timesyncd` conflict, and installing chrony normally masks timesyncd. `timedatectl` shows which one is in charge under "NTP service".

Serving time also needs 123/udp to be reachable. On a host with a default-drop firewall the `allow` line is correct and no client can still use it, which is a good reminder that a networking task usually has a firewall half.

## Verify

```bash
chronyc sources                       # the configured source is listed
chronyc tracking                      # the daemon answers, so it read its configuration
timedatectl show -p Timezone --value  # Asia/Kolkata
readlink -f /etc/localtime            # /usr/share/zoneinfo/Asia/Kolkata

grep -E '^(server|pool|allow)' /etc/chrony/chrony.conf /etc/chrony.conf 2>/dev/null
systemctl is-enabled chrony 2>/dev/null || systemctl is-enabled chronyd
```

## Docs

- `man 5 chrony.conf` for `server`, `pool`, `iburst` and `allow`
- `man 1 chronyc` for `sources`, `sourcestats`, `tracking` and `makestep`
- `man 8 chronyd` for how the daemon reads its configuration
- `man 1 timedatectl` for `set-timezone`, `list-timezones` and `set-ntp`
- `man 8 systemd-timesyncd.service` for the daemon chrony replaces
