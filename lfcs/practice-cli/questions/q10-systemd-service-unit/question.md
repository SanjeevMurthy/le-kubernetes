# Q10. Write a service unit for an application

The application `/opt/inventory/server.sh` listens on TCP port 9090 and stays in the foreground. The unprivileged account `inventory` already exists and owns `/opt/inventory`.

Write `/etc/systemd/system/inventory.service` so that all of the following are true.

1. The service runs `/opt/inventory/server.sh`.
2. It runs as the user `inventory`, not as root.
3. systemd restarts it if it exits with a failure.
4. It is running now, and it starts again at the next boot.

The grader reads `systemctl is-active`, `systemctl is-enabled`, `systemctl show`, `ss -H -ltn`, the owner of the running process, and the unit file itself.
