# Q09. Serve a custom document root on a custom port under SELinux enforcing (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. See what is actually wrong before changing anything.**

```bash
getenforce
systemctl status httpd --no-pager
journalctl -u httpd -b --no-pager | tail -20
ausearch -m avc -ts recent
```

The service fails on `make_sock: could not bind to address [::]:8081`, and the AVC records tell you SELinux refused the bind.

**2. Label the port.**

```bash
semanage port -l | grep '^http_port_t'
semanage port -a -t http_port_t -p tcp 8081
```

Use `-m` instead of `-a` if the port is already owned by some other type.

**3. Label the document root, in policy, then apply it.**

```bash
ls -Zd /srv/site
semanage fcontext -a -t httpd_sys_content_t '/srv/site(/.*)?'
restorecon -Rv /srv/site
ls -Zd /srv/site
```

**4. Set the boolean permanently.**

```bash
setsebool -P httpd_can_network_connect on
getsebool httpd_can_network_connect
```

**5. Make the mode itself persistent.** The host is enforcing now, but `/etc/selinux/config` says permissive, so a reboot would quietly weaken it.

```bash
grep '^SELINUX=' /etc/selinux/config
sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
setenforce 1
```

**6. Start the service and open the firewall.**

```bash
systemctl enable --now httpd
firewall-cmd --permanent --add-port=8081/tcp
firewall-cmd --reload
curl http://localhost:8081/
```

## Why

Every part of this task is a pair: one command that changes the running system and one that changes what the system will be after a reboot or a relabel. That pairing is the whole point of SELinux questions on this exam.

`setenforce` sets the mode until the next boot. `/etc/selinux/config` sets it from then on. Setting only the first leaves a host that silently drops back to permissive; setting only the second leaves the current session unprotected and the grader unhappy.

`chcon` writes a label onto a file now. A relabel, or any `restorecon` run, reverts it, because `restorecon` reads the label a file is supposed to have from policy. `semanage fcontext -a` writes that rule into policy, into `/etc/selinux/targeted/contexts/files/file_contexts.local`, and `restorecon -Rv` then applies it. That pair is what a grader checks, and it is why `chcon` alone is the wrong answer even though it makes the page load.

The regular expression `'/srv/site(/.*)?'` covers the directory and everything under it, now and in the future. Without the `(/.*)?` part only the directory itself gets the type, and the files inside keep whatever they had.

`setsebool` without `-P` writes the boolean to the running policy only. The `-P` flag writes it into the policy store as well, which is the half that survives a reboot.

The firewall repeats the pattern one more time. `firewall-cmd --add-port` changes the running configuration, `--permanent` changes the saved one, and `--reload` makes the saved one current. Doing both, in that order, is the habit worth building.

One approach that is always wrong on this exam: `setenforce 0` to make the problem disappear. It scores zero even if everything else works, and the same is true of `SELINUX=disabled`. Going the other way, from `disabled` back to `enforcing`, needs a full filesystem relabel with `touch /.autorelabel` and a reboot, which is far too slow for a two hour exam.

## Verify

```bash
getenforce                                        # Enforcing
grep '^SELINUX=' /etc/selinux/config              # SELINUX=enforcing

systemctl is-active httpd; systemctl is-enabled httpd
curl -s http://localhost:8081/

ls -Zd /srv/site                                  # httpd_sys_content_t
semanage fcontext -l | grep '/srv/site'
semanage port -l | grep '^http_port_t'            # 8081 in the list
getsebool httpd_can_network_connect               # on
firewall-cmd --list-ports; firewall-cmd --permanent --list-ports
```

## Docs

- `man 8 selinux` for the concepts and `man 5 selinux_config` for `/etc/selinux/config`
- `man 8 sestatus` and `man 8 setenforce` for reading and setting the mode
- `man 8 semanage-fcontext` for `-a`, `-d`, `-l` and the path regular expression
- `man 8 semanage-port` for `-a`, `-m` and `-t http_port_t`
- `man 8 semanage-boolean` and `man 8 setsebool` for `-P`
- `man 8 restorecon` and `man 1 chcon` for the difference between applying and overriding a label
- `man 8 ausearch` and `man 8 sealert` for reading the denials
- `man 1 firewall-cmd` for `--add-port`, `--permanent` and `--reload`
