# Finding Answers With No Internet

The LFCS exam allows man pages, `/usr/share/doc`, and packages installed on the system. There is no browser. If you are coming from CKA, CKAD or CKS, this is the biggest adjustment, and it is a skill you can practise rather than a limitation you endure.

The skill is not memorising flags. It is finding the right page in under thirty seconds.

<!-- toc -->
## Table of Contents

- [Finding the page](#finding-the-page)
- [The sections that matter](#the-sections-that-matter)
- [Reading a page quickly](#reading-a-page-quickly)
- [When man is not the fastest route](#when-man-is-not-the-fastest-route)
- [The examples nobody remembers to look for](#the-examples-nobody-remembers-to-look-for)
- [Command to page, for this exam](#command-to-page-for-this-exam)
- [Practise this before the exam](#practise-this-before-the-exam)

<!-- toc stop -->

## Finding the page

```bash
man -k quota                  # search page names and descriptions (same as apropos)
apropos "logical volume"      # the same search, phrase form
man -f fstab                  # what sections is this name in? (same as whatis)
man -k . | grep -i acl        # broad sweep when you do not know the name
```

`man -k` searches a database. If it returns "nothing appropriate", the database is stale and `mandb` rebuilds it, which occasionally matters on a minimal install.

## The sections that matter

| Section | Holds | Reach for it when |
|---|---|---|
| **1** | user commands | you know the command, want a flag |
| **5** | **file formats** | you are editing a config file |
| **8** | **administration commands** | the command needs root |
| 7 | overviews and conventions | you want the concept |

**Section 5 is the one candidates forget, and it answers the most exam questions.** When a task says to configure something, the answer is usually a file, and the file has a page:

```bash
man 5 fstab           # mount options, the six fields, what the last two mean
man 5 crontab         # the five time fields, and the @reboot shortcuts
man 5 sudoers         # the grammar, NOPASSWD, host and command aliases
man 5 exports         # rw, ro, sync, no_root_squash, the network forms
man 5 sshd_config     # every directive, including Match block rules
man 5 nfs             # client mount options, including _netdev
man 5 systemd.unit    # Unit, Install, After, Wants, Requires
man 5 systemd.service # Type, ExecStart, Restart, User
man 5 systemd.timer   # OnCalendar, OnBootSec, Persistent
man 5 login.defs      # PASS_MAX_DAYS and the defaults useradd reads
man 5 limits.conf     # soft and hard, nofile and nproc
man 5 crypttab        # the four fields for an encrypted volume
man 5 mdadm.conf      # the ARRAY line that makes RAID reassemble
man 5 sssd.conf       # id_provider, ldap_uri, ldap_search_base
man 5 netplan         # renderer, ethernets, addresses, routes, bridges
man 5 nsswitch.conf   # where passwd, group and hosts lookups actually go
```

Say the file name out loud and add a 5. That is the whole technique.

## Reading a page quickly

| Key | Does |
|---|---|
| `/pattern` | search forward |
| `n` and `N` | next and previous match |
| `G` and `g` | end and start of the page |
| `q` | quit |

Two habits that save the most time:

- **Search rather than scroll.** Inside `man 5 sudoers`, `/NOPASSWD` lands on the answer immediately.
- **Read SEE ALSO.** It is the fastest route from a command page to the file-format page you actually needed.

```bash
man 8 useradd         # then /-e to find the expiry flag
man 1 setfacl         # then /default to find the -d behaviour
```

## When man is not the fastest route

```bash
<command> --help | less           # usually a one-screen summary
<command> --help | grep -i expire # when you know the concept, not the flag
help <builtin>                    # for shell builtins: cd, export, ulimit, trap
```

`--help` beats `man` when you want one flag and already know the command. `man` wins when you need the semantics of a file.

## The examples nobody remembers to look for

```bash
ls /usr/share/doc/<package>/
ls /usr/share/doc/<package>/examples/
zcat /usr/share/doc/<package>/examples/*.gz | less
```

Many packages ship a working, commented configuration file. Copying and editing one beats writing from memory, and it is explicitly allowed.

Systemd's own units are the best examples of unit files on the machine:

```bash
ls /lib/systemd/system/*.service
systemctl cat sshd          # the unit as loaded, including drop-ins
```

## Command to page, for this exam

| The task mentions | Read |
|---|---|
| a mount, a filesystem, fstab | `man 5 fstab`, `man 8 mount`, `man 8 findmnt` |
| LVM | `man 8 lvm`, then `man 8 lvextend` |
| RAID | `man 8 mdadm`, `man 5 mdadm.conf` |
| encryption | `man 8 cryptsetup`, `man 5 crypttab` |
| quotas | `man 8 setquota`, `man 8 repquota` |
| a user or a group | `man 8 useradd`, `man 8 usermod`, `man 1 chage`, `man 5 login.defs` |
| sudo | `man 5 sudoers`, `man 8 visudo` |
| ACLs | `man 1 setfacl`, `man 1 getfacl` |
| a service or a timer | `man 5 systemd.service`, `man 5 systemd.timer`, `man 1 systemctl` |
| cron or at | `man 5 crontab`, `man 1 at` |
| logs | `man 1 journalctl`, `man 8 logrotate` |
| the firewall | `man 8 nft`, `man 8 firewall-cmd`, `man 8 ufw` |
| addresses and routes | `man 8 ip`, `man 5 netplan`, `man 1 nmcli` |
| SSH | `man 5 sshd_config`, `man 5 ssh_config`, `man 1 ssh-keygen` |
| NFS | `man 5 exports`, `man 8 exportfs`, `man 5 nfs` |
| time | `man 1 timedatectl`, `man 5 chrony.conf` |
| SELinux | `man 8 semanage-fcontext`, `man 8 restorecon`, `man 8 setsebool` |
| containers | `man 1 podman-run`, `man 1 podman-generate-systemd` |
| virtual machines | `man 1 virsh`, `man 1 virt-install` |
| certificates | `man 1 openssl-x509`, `man 1 openssl-req` |
| kernel parameters | `man 8 sysctl`, `man 5 sysctl.d` |
| packages | `man 8 apt`, `man 8 dnf`, `man 1 dpkg`, `man 8 rpm` |

## Practise this before the exam

During study, close the browser. When you reach for a search engine, use `man -k` instead and note how long it took. By January it should be under thirty seconds for anything in the table above.

The second habit worth building: after solving a task, read the man page for the file you edited. That is where the flag you did not know you needed lives, and it is the cheapest revision there is.
