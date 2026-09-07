# Q08. Run a web container with limits and a restart policy that survives reboot (solution)

## Steps

**1. Put the page where the container will read it.**

```bash
mkdir -p /srv/web
echo hello > /srv/web/index.html
```

**2. Run the container with every flag the task asks for.**

```bash
podman run -d --name web \
  -p 8080:80 \
  -m 256m --memory-swap 256m \
  --restart=always \
  -v /srv/web:/usr/share/nginx/html:ro,Z \
  docker.io/library/nginx:1.27
```

**3. Prove it works before making it permanent.**

```bash
podman ps
curl -s http://localhost:8080/
podman inspect web --format '{{.HostConfig.Memory}}'
```

**4. Make it come back after a reboot.** Generate a systemd unit from the running container and enable it.

```bash
podman generate systemd --new --name web > /etc/systemd/system/container-web.service
systemctl daemon-reload
systemctl enable --now container-web.service
systemctl is-enabled container-web.service
```

Note that `--new` makes the unit recreate the container from the image at every start, so the unit file carries the full `podman run` command line. Read it once; it is the record of every flag you chose.

**Alternative, the quadlet form** on a current podman. Write `/etc/containers/systemd/web.container`:

```ini
[Unit]
Description=nginx web container

[Container]
Image=docker.io/library/nginx:1.27
ContainerName=web
PublishPort=8080:80
Memory=256m
Volume=/srv/web:/usr/share/nginx/html:ro,Z

[Service]
Restart=always

[Install]
WantedBy=multi-user.target
```

then `systemctl daemon-reload` and `systemctl start web.service`.

**Alternative, the engine-wide form.** `systemctl enable --now podman-restart.service` starts every container whose restart policy is `always` at boot. It is one command, and it is all or nothing for the host.

## Why

The trap in this task is requirement 7. `--restart=always` tells the podman engine to restart the container when it exits, and podman is not a daemon that survives a reboot. Nothing replays that policy at boot unless a systemd unit exists to do it. This is exactly the runtime versus persistent split that the whole exam turns on, wearing container clothes.

256 MB is 268435456 bytes, and that is the number `podman inspect` prints. Learning the number saves a mental conversion under time pressure. `-m 256m` on its own caps memory but still allows an equal amount of swap, so a task that caps total usage wants `--memory-swap 256m` as well.

`:ro` makes the bind mount read-only. `:Z` relabels the host directory with a private SELinux label so the container can read it on the RHEL family; `:z` shares the label instead, which is right only when more than one container needs the same directory. Using `:Z` on a directory another service already uses will break that other service, so it belongs on a directory created for the container.

Short image names are resolved through the registries list on Ubuntu and must be fully qualified on Rocky. Writing `docker.io/library/nginx:1.27` in full works identically on both, and it removes any doubt about which registry answered.

One exam safety note that has nothing to do with correctness: 8080 is one of the ports the exam grader itself uses. Publishing a container on it is fine. Adding a firewall rule that drops 8080, 4505 or 4506 ends the session.

## Verify

```bash
curl -s http://localhost:8080/                                    # hello
podman inspect web --format '{{.HostConfig.Memory}}'              # 268435456
podman inspect web --format '{{.HostConfig.RestartPolicy.Name}}'  # always
podman inspect web --format '{{.HostConfig.PortBindings}}'
podman inspect web --format '{{range .Mounts}}{{.Source}} {{.Destination}} {{.RW}}{{end}}'
ss -H -ltn 'sport = :8080'

systemctl is-enabled container-web.service
```

## Docs

- `man 1 podman-run` for `-p`, `-m`, `--memory-swap`, `--restart` and the `:ro,Z` volume suffixes
- `man 1 podman-inspect` for the `--format` templates used above
- `man 1 podman-generate-systemd` for the unit generator and `--new`
- `man 5 podman-systemd.unit` for the quadlet file format
- `man 5 containers.conf` and `man 5 containers-registries.conf` for short name resolution
- `man 1 docker-run` on a host that has Docker instead; the flags in this task are the same
