# LFCS Study Notes — The Exam Environment

Facts, not technique. Verified against Linux Foundation pages on 6 September 2026. Re-read the page linked at the bottom the week before you book, and again the week before you sit.

<!-- toc -->
## Table of Contents

- [Exam facts at a glance](#exam-facts-at-a-glance)
- [The one rule that decides the outcome](#the-one-rule-that-decides-the-outcome)
- [Hosts](#hosts)
- [Documentation](#documentation)
- [Ports you must never block](#ports-you-must-never-block)
- [The desktop](#the-desktop)
- [Which distribution](#which-distribution)
- [The first two minutes on a task host](#the-first-two-minutes-on-a-task-host)
- [Habits the environment rewards](#habits-the-environment-rewards)
- [Before you book](#before-you-book)
- [Memorise](#memorise)

<!-- toc stop -->

## Exam facts at a glance

| | |
|---|---|
| Format | **17 to 20 performance-based tasks** |
| Duration | 2 hours |
| Pass mark | **67 percent** |
| Prerequisites | None |
| Retake | One free retake per purchase, within 12 months of the original purchase date |
| Results | Emailed within 24 hours. No per-task breakdown. |
| Validity | 2 years |
| Price | 445 US dollars, which includes the retake and the simulator |
| Simulator | Two killer.sh sessions, 36 hours of access each. Unlike the Kubernetes exams, **both sessions have the same 20 questions.** |

At 18 tasks and 67 percent you need roughly 12 solved cleanly. Three tasks can be left untouched if the rest are right, which makes finishing what you start worth more than starting everything.

## The one rule that decides the outcome

**A change that works now but does not survive a reboot scores zero.**

This is the most reported cause of failure, and it is what separates LFCS from a Kubernetes exam. `ip addr add` is not a network configuration. `sysctl -w` is not a kernel parameter. `swapon` is not swap. `mount` is not a mount. Each has a file behind it, and the file is the answer.

| Live change | What makes it persist |
|---|---|
| `ip addr add`, `ip route add` | a netplan YAML, or an nmcli connection with `ipv4.method manual` |
| `sysctl -w` | a file in `/etc/sysctl.d/`, then `sysctl --system` |
| `mount` | an `/etc/fstab` line, verified with `findmnt --verify` and `mount -a` |
| `swapon` | an `/etc/fstab` line with the `swap` type |
| `nft add rule` | `/etc/nftables.conf` on Ubuntu, `/etc/sysconfig/nftables.conf` on Rocky, plus an enabled service |
| `firewall-cmd --add-port` | the same command with `--permanent`, then `--reload` |
| `cryptsetup luksOpen` | an `/etc/crypttab` entry |
| `mdadm --create` | an `ARRAY` line in `mdadm.conf`, then rebuild the initramfs |
| starting a service | `systemctl enable`, not just `start` |
| an exported directory | an `/etc/exports` line, then `exportfs -ra` |

Before leaving any task, ask what happens after a reboot. If the answer is not obvious, the task is not finished.

## Hosts

- You begin on a host whose hostname is `base`. **Never reboot it.** Rebooting `base` does not restart the exam environment.
- Every task names its own host. Reach it with `ssh <nodename>`.
- **Nested SSH is not supported.** Finish the task, `exit` back to `base`, then connect to the next host.
- `sudo -i` gives you root on any host.
- Candidates report one machine per task, and at least one reports losing marks by doing two tasks on the wrong host. Run `hostname` after every connection.

Every host has vim, nano, emacs, git and sudo installed. The `base` host deliberately does not, because no work is meant to happen there.

## Documentation

This is the hard part if you are coming from CKA, CKAD or CKS.

> The following tools and resources are allowed during the Exam as long as they are accessed from within the Linux server terminal on which the Exam is delivered: man pages, documents installed by the distribution (`/usr/share` and its subdirectories), and packages that are part of the distribution.

**There is no browser and no internet.** No kubernetes.io, no manual pages online, no search. Everything you need must come from `man`, from `--help`, from `/usr/share/doc`, or from memory.

The practical consequences shape how to study:

- Learn `man -k` and `apropos` properly. Finding the right page fast is the skill, not memorising every flag.
- Know the man section numbers: 1 for commands, 5 for file formats, 8 for administration. `man 5 fstab` and `man 5 sudoers` answer more exam questions than any command page.
- `/usr/share/doc/<package>/examples/` often contains a working configuration file to copy rather than write.
- If a package you want is missing, you are allowed to install it from the distribution repositories.

## Ports you must never block

> Do not block incoming ports 8080/tcp, 4505/tcp and 4506/tcp. This includes firewall rules found within the distribution's default firewall configuration files as well as interactive firewall commands.

Blocking any of them ends your session. Firewall tasks that say "deny everything except X" therefore mean "except X, and the exam's own ports". A default-drop policy without an explicit allow for these three is how candidates lock themselves out mid-exam.

The same instruction warns not to stop or tamper with the `certterminal` process, which is how the exam is delivered.

## The desktop

- Delivered through PSI Bridge in the PSI Secure Browser, as a remote Linux desktop.
- **One monitor only.** Dual monitors are not supported.
- A terminal, and VSCodium with an integrated terminal as an alternative. Extensions are disabled.
- Timer alerts at 30, 15 and 5 minutes remaining. The timer does not stop for breaks and time cannot be added back after a disconnect.
- `Ctrl+Shift+C` and `Ctrl+Shift+V` copy and paste in the terminal. Use `Ctrl+Alt+W` rather than `Ctrl+W`.
- **The INSERT key is disabled.** Press `i` in vim.

## Which distribution

The Linux Foundation does not say, and declined to answer when asked directly on its own forum in July 2025. The exam is described as independent of distribution-specific tasks, and platform selection was removed from the preparation checklist in May 2023.

What is known:

- Vendor staff describe Ubuntu as typical, with CentOS-family nodes possible.
- The curriculum contains "Create and enforce MAC using SELinux", which is not an Ubuntu technology.
- The instructions tell candidates to be familiar with `apt`, `dpkg`, `dnf` **and** `yum`.

So prepare for both families. The practical split:

| | Debian family | RHEL family |
|---|---|---|
| Packages | `apt`, `dpkg` | `dnf`, `rpm` |
| Network | netplan, or `nmcli` | `nmcli` |
| Firewall | `ufw`, or `nft` directly | `firewalld` |
| MAC | AppArmor | **SELinux** |
| NFS server package | `nfs-kernel-server` | `nfs-utils` |
| Time sync service | `chrony` | `chronyd` |
| Cron service | `cron` | `crond` |

The lab in [`../lab-setup/README.md`](../lab-setup/README.md) gives you one VM of each for exactly this reason.

## The first two minutes on a task host

```bash
ssh <nodename>          # the host the task names
sudo -i                 # root; without it half these commands look broken
hostname                # confirm where you are
cat /etc/os-release     # which family, which decides half your commands
```

Then read the whole task before typing. Note the deliverable: if it names a file, that file is the mark.

## Habits the environment rewards

- **Do the quick tasks first.** There are no visible weights, so a two-minute task scores like a fifteen-minute one of the same size.
- **Leave firewall and networking until last.** They are the tasks most likely to cut you off from the host you are working on.
- **Budget about 6 minutes per task.** Flag anything past 8 and come back.
- **Verify with a machine-readable command**, not by re-reading the file you just edited. `findmnt --verify`, `sshd -t`, `visudo -c`, `nft list ruleset`, `systemctl is-enabled` all exist for this.
- **Then ask what a reboot would do.**
- **`exit` back to `base`** before the next task.

## Before you book

Re-read `https://docs.linuxfoundation.org/tc-docs/certification/instructions-lfcs-and-lfce`, which carries the task count, the allowed resources, the host rules and the port warning. It changes without notice.

## Memorise

- 17 to 20 tasks, 2 hours, **67 percent**, roughly 12 of 18 solved cleanly.
- **Man pages only.** No browser. `man -k`, `apropos`, section 5 for file formats, section 8 for administration.
- `ssh <nodename>` from `base`, `sudo -i` for root, no nested SSH, **never reboot `base`**.
- **Never block 8080, 4505 or 4506.**
- Every change needs a file behind it, or it dies at the next reboot.
- Quick tasks first, firewall and networking last, 6 minutes each, verify persistence before moving on.
