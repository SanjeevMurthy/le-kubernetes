# LFCS Exam Day Playbook

Read this the evening before and skim it the morning of. No new material. These are the habits that turn what you know into marks.

Exam: **Saturday 6 February 2027**.

<!-- toc -->
## Table of Contents

- [The night before](#the-night-before)
- [Thirty minutes before](#thirty-minutes-before)
- [The first three minutes](#the-first-three-minutes)
- [The first thirty seconds of each task](#the-first-thirty-seconds-of-each-task)
- [While you work](#while-you-work)
- [The question to ask before leaving every task](#the-question-to-ask-before-leaving-every-task)
- [Verify with a command, not by re-reading the file](#verify-with-a-command-not-by-re-reading-the-file)
- [Recovering from the things that go wrong](#recovering-from-the-things-that-go-wrong)
- [The last fifteen minutes](#the-last-fifteen-minutes)
- [Afterwards](#afterwards)
- [The eight that cost other people the exam](#the-eight-that-cost-other-people-the-exam)

<!-- toc stop -->

## The night before

- [ ] Run the PSI system check on the exact machine you will use.
- [ ] One monitor. Dual monitors are not supported and will stop the exam.
- [ ] Quiet, private, well-lit room. Clear desk.
- [ ] Charge and plug in; use a wired connection if you have one.
- [ ] No new material. Re-read [`../cheatsheets/lfcs-exam-cheatsheet.md`](../cheatsheets/lfcs-exam-cheatsheet.md) and [`../cheatsheets/man-page-navigation.md`](../cheatsheets/man-page-navigation.md), then stop.
- [ ] Sleep.

## Thirty minutes before

- [ ] Join early. Check-in, ID and the room scan take real time and the clock has not started.
- [ ] Close every other application and browser window.
- [ ] Water within reach. Breaks do not stop the timer.

## The first three minutes

1. Read the instructions tab.
2. **Skim every task.** For each, note how confident you are and which host it runs on.
3. Order the work: quick and confident first, **firewall and networking last**. Those are the tasks most likely to cut you off from the machine you are working on.

There are no visible weights, so a two-minute task is worth the same as a fifteen-minute one of the same size. Finishing eight small tasks beats half-finishing four large ones.

## The first thirty seconds of each task

```bash
ssh <nodename>          # exactly the host the task names
sudo -i                 # root; without it half these commands look broken
hostname                # confirm you are where you think you are
cat /etc/os-release     # Debian family or RHEL family decides your commands
```

Then read the whole task before typing. If it names a file, that file is the mark.

## While you work

- **Man pages are your only reference.** No browser, no internet. `man -k <keyword>` and `apropos` find the page; section 5 is file formats and section 8 is administration.
- **`/usr/share/doc/<package>/examples/`** often holds a working config to copy rather than write from memory.
- You may install packages from the distribution repositories if something is missing.
- **Never block ports 8080, 4505 or 4506.** A default-drop firewall policy without an explicit allow for those three ends your session.
- **`exit` back to `base`** before the next task. Nested SSH is not supported.
- **Never reboot `base`.** It does not restart the environment.
- Flag anything past 8 minutes and come back.

## The question to ask before leaving every task

**What happens after a reboot?**

This is the single most reported cause of failure. The live command is never the answer on its own.

| You did | The mark is in |
|---|---|
| `ip addr add`, `ip route add` | a netplan YAML, or `nmcli con mod` with `ipv4.method manual` |
| `sysctl -w` | `/etc/sysctl.d/*.conf`, then `sysctl --system` |
| `mount` | `/etc/fstab`, checked with `findmnt --verify` and `mount -a` |
| `swapon` | `/etc/fstab` with `pri=` if a priority was asked for |
| `nft add rule` | `/etc/nftables.conf` or `/etc/sysconfig/nftables.conf`, plus `systemctl enable nftables` |
| `firewall-cmd --add-x` | the same command with `--permanent`, then `--reload` |
| `systemctl start` | `systemctl enable`, or `enable --now` for both |
| `cryptsetup luksOpen` | `/etc/crypttab` |
| `mdadm --create` | an `ARRAY` line in mdadm.conf, then rebuild the initramfs |
| edited `/etc/exports` | `exportfs -ra` |
| `useradd` defaults | `/etc/login.defs` or `/etc/skel` when the task means future users too |

If a reboot would undo it, the task is not finished.

## Verify with a command, not by re-reading the file

Sixty seconds per task, and it is where the difference between 64 and 74 percent lives.

| Area | The command that proves it |
|---|---|
| Users | `getent passwd <u>`, `id <u>`, `chage -l <u>`, `sudo -l -U <u>` |
| Permissions and ACLs | `stat -c '%a %U:%G' <f>`, `getfacl -p <d>` |
| Storage | `lsblk -f`, `findmnt --verify`, `findmnt -no OPTIONS <m>`, `swapon --show`, `lvs`, `df -hT` |
| Services | `systemctl is-active <u>`, `systemctl is-enabled <u>`, `systemctl show -p <Prop> <u>` |
| Timers and cron | `systemctl list-timers --no-pager`, `crontab -l -u <user>` |
| Network | `ip -br a`, `ip r`, `resolvectl status`, `ss -H -ltnp` |
| Firewall | `nft list ruleset`, `firewall-cmd --list-all`, `ufw status numbered` |
| SSH | `sshd -t`, `sshd -T \| grep -i <setting>` |
| NFS | `exportfs -v`, `showmount -e localhost` |
| Time | `timedatectl`, `chronyc sources -v` |
| SELinux | `getenforce`, `ls -Z`, `semanage port -l \| grep <port>`, `ausearch -m avc -ts recent` |
| Containers | `podman ps`, `podman inspect --format '{{.HostConfig.Memory}}' <name>` |
| Git | `git -C <repo> log --oneline -1`, `git -C <repo> rev-parse --abbrev-ref HEAD` |

## Recovering from the things that go wrong

**A config file you edited breaks its service.** Every major one has a validator. Use it before restarting, not after.

```bash
findmnt --verify        # /etc/fstab
sshd -t                 # /etc/ssh/sshd_config
visudo -c               # /etc/sudoers and /etc/sudoers.d
nginx -t                # nginx
named-checkconf         # bind
nft -c -f /etc/nftables.conf
```

**You locked yourself out with a firewall rule.** You cannot reconnect, so prevent it: add the allow rules before the drop policy, and never touch 8080, 4505 or 4506. If the console is still open, `nft flush ruleset` or `ufw disable` restores access.

**Networking changes cut the connection.** `netplan try` applies a change and rolls it back automatically after 120 seconds unless you confirm. Use it whenever you edit the interface you are connected over.

**A broken `/etc/fstab` stops the boot.** This is on the syllabus, so it may even be the task. At the emergency prompt, mount the root filesystem read-write, fix or comment the line, and reboot:

```bash
mount -o remount,rw /
vi /etc/fstab
```

**A service will not start.** `systemctl status <unit>` gives the exit code, `journalctl -u <unit> -b --no-pager` gives the reason. Exit code 203 means the binary is missing or not executable. A port conflict shows in `ss -tlpn`.

## The last fifteen minutes

Stop starting new work.

1. Return to flagged tasks and take partial credit where you can.
2. Re-run one verification command per completed task. A later task may have changed something.
3. Re-ask the reboot question for every task that changed persistent state.
4. Confirm nothing was done on the wrong host.

## Afterwards

Results arrive by email within 24 hours, with no per-task breakdown. If it did not pass, reschedule the free retake immediately while the environment is fresh. There are roughly four weeks before the voucher expires, which is enough but leaves no room for delay.

Passing completes the Golden Kubestronaut requirement that sits outside the CNCF exams.

## The eight that cost other people the exam

1. **A change that did not survive a reboot.** The most reported failure by a distance.
2. **Work done on the wrong host.** The task names it; `hostname` confirms it.
3. **Running out of time** by starting the hardest task first.
4. **Blocking an exam port** with a default-drop firewall policy.
5. **Editing `/etc/sudoers` directly** and locking sudo, instead of using `/etc/sudoers.d/` and `visudo -c`.
6. **Restarting a service before validating its config**, turning one broken task into two.
7. **Hunting for a man page** instead of using `man -k`.
8. **Not verifying**, when sixty seconds and one command would have caught it.
