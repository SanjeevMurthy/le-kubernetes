# Q41. Host hardening: stop the rogue service and close its port

**Host:** the worker node named in the setup output (root shell: `sudo -i`).

A port scan of that worker found an open TCP port **8888** that nothing in the cluster documentation accounts for. It is served by a systemd unit somebody installed by hand.

1. Find which service is listening on 8888. Start from the socket, not from a guess: `ss -ltnp` names the process, and `systemctl status <pid>` maps that process back to its unit.

2. Write the unit name (for example `foo.service`) on a single line in `/opt/course/41/service.txt` (or `$COURSE_DIR/41/service.txt` on this lab). That file is written on the host you are running the practice CLI from.

3. Stop the service, disable it so it does not come back after a reboot, and delete its unit file from `/etc/systemd/system/`. Reload systemd afterwards so the removed unit disappears from `systemctl list-unit-files`.

When you are done, nothing may listen on 8888 on that node, and the unit must be neither enabled nor present on disk. Leave every other service on the node alone: the kubelet and the container runtime must keep running.
