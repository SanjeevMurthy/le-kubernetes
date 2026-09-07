# Q42. Host hardening: users, sudo and kernel modules (solution)

## Steps

Everything happens on the worker node, as root.

```bash
ssh <worker>
sudo -i
```

**1. Look at what the account can do before changing it.**

```bash
id tempadmin
getent passwd tempadmin
passwd -S tempadmin                 # tempadmin P ... -> a usable password
sudo -l -U tempadmin                # (ALL) NOPASSWD: ALL
cat /etc/sudoers.d/tempadmin
lsmod | grep sctp
```

**2. Lock the password and take away the shell.** One `usermod` does both.

```bash
usermod -L -s /usr/sbin/nologin tempadmin
passwd -S tempadmin                 # tempadmin L ...
getent passwd tempadmin             # ...:/usr/sbin/nologin
```

`passwd -l tempadmin` is the same lock. Do not use `userdel`: the task keeps the account for the audit trail.

**3. Remove the sudo grant.**

```bash
rm -f /etc/sudoers.d/tempadmin
sudo -l -U tempadmin                # User tempadmin is not allowed to run sudo
visudo -c                           # the remaining sudoers files still parse
```

**4. Take the account out of the group.**

```bash
gpasswd -d tempadmin lab-ops        # or: deluser tempadmin lab-ops
id tempadmin                        # lab-ops is gone from the list
```

**5. Unload the module and keep it out.**

```bash
lsmod | grep sctp
modprobe -r sctp
lsmod | grep sctp                   # no output

cat > /etc/modprobe.d/blacklist-sctp.conf <<CONF
blacklist sctp
install sctp /bin/true
CONF

modprobe --showconfig | grep sctp
modprobe sctp && lsmod | grep sctp  # still no output
```

If `modprobe -r` reports the module is in use, find the user with `lsmod | grep sctp` (the third column counts references) before forcing anything.

## Why

Three of the four steps close the same kind of hole: a local identity on a node that can become root. A node is where the kubelet's credentials, the container runtime socket and every mounted Secret live, so root on a worker is a path to everything scheduled there. A contractor account with `NOPASSWD:ALL` needs no password and no exploit; a password that can be guessed or reused is enough, and the sudo drop-in does the rest.

Locking and disabling are two different locks, which is why the task asks for both. `usermod -L` prefixes the hash in `/etc/shadow` with `!`, so no password can match, but key-based ssh and any service that authenticates without a password still let the account in. Setting the shell to `/usr/sbin/nologin` closes the interactive login instead, but a command run over ssh, or a cron job, does not always need a shell. Together they make the account inert while leaving it in `/etc/passwd`, which keeps file ownership readable and the audit trail intact. Deleting it would orphan every file it owns to a bare numeric uid, and a later account can be created with that same uid and inherit them.

The sudoers drop-in matters more than the group membership, but the group is the quieter risk. Membership is evaluated at login and grants whatever the group is allowed elsewhere on the node, most dangerously `docker`, `lxd` or a group with write access to a unit file directory. Each of those is root by another route. Removing the drop-in is `rm`, not an edit, and `visudo -c` afterwards confirms the remaining files still parse, because a syntax error in `/etc/sudoers.d/` breaks sudo for everyone.

The module is a different kind of surface. Every loaded module is kernel code reachable from an unprivileged process, and rarely used network protocol modules such as `sctp` and `dccp` are a recurring source of kernel vulnerabilities. Unloading is only half the fix: any process that opens a socket of that family triggers an automatic load through the module alias. `blacklist sctp` suppresses that alias-driven load, but it does not stop an explicit `modprobe sctp`, which is why `install sctp /bin/true` is added next to it. That line tells modprobe to run `/bin/true` instead of loading, so both paths end in nothing being loaded.

## Verify

```bash
passwd -S tempadmin | awk '{print $2}'          # L
getent passwd tempadmin | cut -d: -f7           # /usr/sbin/nologin
test -f /etc/sudoers.d/tempadmin; echo $?       # 1
sudo -l -U tempadmin | grep -c NOPASSWD         # 0
id -nG tempadmin | tr ' ' '\n' | grep -x lab-ops  # no output
lsmod | awk '{print $1}' | grep -x sctp         # no output
modprobe --showconfig | grep -E 'blacklist sctp|install sctp'
```

## Docs

**Allowed:** the exam allows the man pages on the node itself, which is where this question is answered: `man usermod` for `-L` and `-s`, `man 5 sudoers` and `man sudo` for `-l -U`, `man gpasswd`, and `man 5 modprobe.d` for the difference between `blacklist` and `install`. There is no Kubernetes documentation page for any of it.

Worth memorising: `usermod -L -s /usr/sbin/nologin <user>`, `passwd -S <user>` and its `P`, `L` and `NP` states, `sudo -l -U <user>`, `gpasswd -d <user> <group>`, `modprobe -r <module>`, and the two-line blacklist file with both `blacklist <mod>` and `install <mod> /bin/true`.
