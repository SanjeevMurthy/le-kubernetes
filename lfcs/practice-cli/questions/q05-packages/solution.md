# Q05. Install, hold, verify, and report packages (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

Run `cat /etc/os-release` first if there is any doubt about which family you are on.

**Debian family, Ubuntu 24.04.**

```bash
apt-get update
apt-get install -y tree nginx

systemctl disable --now nginx
apt-mark hold nginx

mkdir -p /opt/course/5
dpkg-query -W -f='${Version}\n' openssl > /opt/course/5/version.txt
dpkg -V bash > /opt/course/5/verify.txt
```

**RHEL family, Rocky 9.**

```bash
dnf makecache
dnf install -y tree nginx

systemctl disable --now nginx
dnf install -y python3-dnf-plugin-versionlock
dnf versionlock add nginx

mkdir -p /opt/course/5
rpm -q --qf '%{VERSION}-%{RELEASE}\n' openssl > /opt/course/5/version.txt
rpm -V bash > /opt/course/5/verify.txt
```

`dpkg -V` and `rpm -V` exit non-zero when they find a difference and print nothing when the files are intact, so an empty `verify.txt` is the expected result on a clean host. Redirecting still creates the file, which is what the task asks for.

**The same jobs, side by side.**

| Job | Ubuntu 24.04 | Rocky 9 |
|---|---|---|
| Refresh metadata | `apt-get update` | `dnf makecache` |
| Version available | `apt-cache policy nginx` | `dnf list --available nginx` |
| Owner of a file | `dpkg -S /usr/sbin/nginx` | `rpm -qf /usr/sbin/nginx` |
| Files in a package | `dpkg -L nginx` | `rpm -ql nginx` |
| Verify files | `dpkg -V bash` | `rpm -V bash` |
| Freeze a version | `apt-mark hold nginx` | `dnf versionlock add nginx` |
| List frozen | `apt-mark showhold` | `dnf versionlock list` |

## Why

Installing a service does not mean the same thing on both families. The Debian family runs the maintainer scripts, which start the service and enable it, so after `apt-get install nginx` the service is already up. The RHEL family installs the unit and leaves it alone. A task that says "installed but not running" therefore needs `systemctl disable --now nginx` on Ubuntu and usually needs nothing at all on Rocky. Read the wording of the task, and check both `is-active` and `is-enabled` before you move on.

A hold and a version lock are both recorded on disk, which is what makes them persistent. `apt-mark hold` writes the state into the dpkg database, and `dnf versionlock add` writes a line into `/etc/dnf/plugins/versionlock.list`. Neither is undone by a reboot, and neither is undone by reinstalling; only `apt-mark unhold` or `dnf versionlock delete` clears them.

`dpkg -V` and `rpm -V` compare the files on disk with the checksums, sizes, modes and owners recorded when the package was installed. They are the fastest honest answer to "has anything been tampered with", and unlike a manual `ls -l` comparison they need no reference host.

## Verify

```bash
command -v tree
systemctl is-active nginx; systemctl is-enabled nginx
apt-mark showhold 2>/dev/null || dnf versionlock list

cat /opt/course/5/version.txt
dpkg-query -W -f='${Version}\n' openssl 2>/dev/null || rpm -q --qf '%{VERSION}-%{RELEASE}\n' openssl
cat /opt/course/5/verify.txt
```

## Docs

- `man 8 apt-get`, `man 8 apt-cache`, `man 8 apt-mark` for the Debian family
- `man 1 dpkg`, `man 1 dpkg-query` for `-L`, `-S`, `-V` and the `-W -f` query format
- `man 5 sources.list` for adding a repository on the Debian family, plus the examples under `/usr/share/doc/apt`
- `man 8 dnf` and `man 8 rpm` for the RHEL family, including `-q`, `-ql`, `-qf`, `-V` and `--qf`
- `man 1 dnf-config-manager` for adding a repository, and `dnf versionlock --help` for the lock plugin
