# Q41. Host hardening: stop the rogue service and close its port (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

Everything happens on the worker node, as root.

```bash
ssh <worker>
sudo -i
```

**1. Go from the port to the process.** `-p` needs root and prints the pid.

```bash
ss -ltnp | grep 8888
# LISTEN 0 5 0.0.0.0:8888 0.0.0.0:* users:(("python3",pid=2417,fd=3))
```

**2. Go from the process to the unit.** A pid is enough for systemd to name the unit that owns it.

```bash
systemctl status 2417
# ● lab-fileshare.service - Lab file share
#      Loaded: loaded (/etc/systemd/system/lab-fileshare.service; enabled; ...)

systemctl cat lab-fileshare.service
```

`systemctl cat` prints the unit file with its path, which is the file to delete in step 4. If `ss -p` is unavailable, `lsof -i :8888` or `fuser -n tcp 8888` answers the same question, and `systemctl list-units --type=service --state=running` narrows it down when nothing else works.

**3. Record the answer** on the host running the practice CLI.

```bash
mkdir -p /opt/course/41
echo "lab-fileshare.service" > /opt/course/41/service.txt
```

**4. Stop it, disable it, remove it.**

```bash
systemctl disable --now lab-fileshare.service
rm -f /etc/systemd/system/lab-fileshare.service
systemctl daemon-reload
systemctl reset-failed lab-fileshare.service
```

`disable --now` is `stop` plus `disable` in one command. The order matters in the other direction: deleting the unit file first leaves the enabled symlink in `/etc/systemd/system/multi-user.target.wants/` pointing at nothing, and systemd then complains on every boot.

**5. Confirm the socket is really gone.**

```bash
ss -ltnp | grep 8888          # no output
systemctl is-enabled lab-fileshare.service   # Failed to get unit file state
systemctl is-active kubelet   # active, so the node was not damaged
```

## Why

A worker node is part of the cluster's attack surface, and anything listening on it is reachable from every Pod on that node and from anywhere the node's network allows. This particular service is the textbook case: an unauthenticated HTTP server, running as root, serving a directory. Nothing in Kubernetes sees it. NetworkPolicies govern Pod traffic, not host sockets, and a PodSecurity standard cannot constrain a process that was never in a container.

Three things have to be true before the finding is closed, and each of them is a separate command. Stopping the service closes the socket now. Disabling it removes the symlink under `multi-user.target.wants/`, without which the service returns at the next reboot, which is the state auditors find most often. Deleting the unit file removes the ability to start it again by name, deliberately or by an automation run that still references it. A service that is stopped but enabled, or disabled but still on disk, is a finding that has been half fixed.

Reading the socket table first, rather than guessing at unit names, is the habit that transfers to the exam. `ss -ltnp` is the ground truth for what is reachable: it names the port, the bind address and the owning process. Binding to `0.0.0.0` rather than `127.0.0.1` is what turns a local convenience into a remote exposure, and that column is worth reading on every finding. From the pid, systemd closes the loop back to a unit, so the chain socket, process, unit, file never depends on knowing what to look for in advance.

## Verify

```bash
ss -H -ltn | awk '{print $4}' | grep 8888      # no output
systemctl is-enabled lab-fileshare.service     # not "enabled"
systemctl is-active  lab-fileshare.service     # not "active"
test -f /etc/systemd/system/lab-fileshare.service; echo $?   # 1
cat /opt/course/41/service.txt                 # lab-fileshare.service
systemctl is-active kubelet && kubectl get nodes
```

## Docs

**Allowed:** the Kubernetes documentation has nothing on systemd, and none is needed. `man ss`, `man systemctl` and `systemctl --help` are on the node and cover every command here. The one Kubernetes page worth knowing nearby is `https://kubernetes.io/docs/reference/networking/ports-and-protocols/`, which lists the ports that are supposed to be open on a control plane and on a worker, so that a scan can be read against a baseline.

Worth memorising: `ss -ltnp` for listening TCP sockets with their processes, `systemctl status <pid>` to map a process back to a unit, `systemctl cat <unit>` for the unit file and its path, and `disable --now` plus `rm` plus `daemon-reload` as the three parts of removing a service for good.
