# Q16. Harden sshd, key-only login with one password exception (solution)

## Steps

**1. Read the effective configuration before changing it.**

```bash
sshd -T | grep -E '^(permitrootlogin|passwordauthentication|maxauthtries|pubkeyauthentication)'
grep -n '^Include' /etc/ssh/sshd_config
```

The `Include` line tells you whether `/etc/ssh/sshd_config.d/` is read and, just as important, where in the file it sits.

**2. Write the hardening as a drop-in.**

```bash
printf '%s\n' 'PermitRootLogin no' 'PasswordAuthentication no' 'MaxAuthTries 3' \
  'PubkeyAuthentication yes' > /etc/ssh/sshd_config.d/90-hardening.conf
```

**3. Write the exception as a second drop-in that sorts last.**

```bash
printf '%s\n' 'Match User deploy' '    PasswordAuthentication yes' \
  > /etc/ssh/sshd_config.d/99-match-deploy.conf
```

Everything after a `Match` line belongs to that block until the next `Match` or the end of the file, so the block goes last and nothing unconditional may follow it.

**4. Install the key for deploy.**

```bash
install -d -m 700 -o deploy -g deploy /home/deploy/.ssh
install -m 600 -o deploy -g deploy /opt/course/16/id_deploy.pub /home/deploy/.ssh/authorized_keys
ls -ld /home/deploy /home/deploy/.ssh
stat -c '%a %U %G' /home/deploy/.ssh/authorized_keys
```

**5. Check the syntax, then reload.**

```bash
sshd -t && echo config-ok
systemctl reload ssh        # sshd on Rocky
```

On Ubuntu 24.04 the daemon is socket activated, so `systemctl restart ssh.socket` is what rebinds the port if the listening address or port changed.

**6. Prove all three outcomes.**

```bash
sshd -T | grep -E 'permitrootlogin|passwordauthentication|maxauthtries'
sshd -T -C user=deploy,host=lab,addr=127.0.0.1 | grep passwordauthentication   # yes
ssh -i /opt/course/16/id_deploy -o BatchMode=yes deploy@localhost true && echo key-login-ok
```

## Why

`sshd -T` prints the configuration the daemon will actually use, with defaults filled in and every `Include` followed. Reading `/etc/ssh/sshd_config` with grep misses both, and on a distribution that ships drop-ins it routinely reports the opposite of the truth. `sshd -T -C ...` goes one step further and evaluates the `Match` blocks for a hypothetical connection, which is the only way to check a conditional rule without opening a session.

Keyword precedence in sshd is unusual: the first occurrence of a keyword wins, not the last. That is the opposite of most configuration systems, and it is why the position of the `Include` line decides whether drop-ins can override the main file at all. Both Ubuntu and Rocky put the `Include` near the top, so a file in `sshd_config.d` wins, and within that directory the files are read in lexical order, so `50-cloud-init.conf` beats `90-hardening.conf` for any keyword both of them set.

The permissions on the key files are a silent failure. sshd refuses an `authorized_keys` file that is group or world writable, or one in a `.ssh` directory that is not 700, or in a home directory that is group writable, and it says nothing to the client beyond "Permission denied (publickey)". The evidence is in `journalctl -u ssh`, and the fix is `chmod`, not more configuration.

`PasswordAuthentication no` on its own is not always the end of password logins. On a PAM host, `KbdInteractiveAuthentication yes` can still ask for a password through the keyboard-interactive path, so a full hardening turns that off as well. This task grades the three keywords a grader would check, but the fourth setting is worth knowing about.

## Verify

```bash
sshd -t
sshd -T | grep -E '^(permitrootlogin no|passwordauthentication no|maxauthtries 3)$'
sshd -T -C user=deploy,host=lab,addr=127.0.0.1 | grep '^passwordauthentication yes$'
stat -c '%a %U %G' /home/deploy/.ssh/authorized_keys      # 600 deploy deploy
ssh -i /opt/course/16/id_deploy -o BatchMode=yes deploy@localhost true

grep -Rn 'PasswordAuthentication\|PermitRootLogin\|MaxAuthTries' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/
systemctl is-enabled ssh 2>/dev/null || systemctl is-enabled sshd
```

## Docs

- `man 5 sshd_config` for `PermitRootLogin`, `PasswordAuthentication`, `MaxAuthTries`, `Include` and `Match`
- `man 8 sshd` for `-t`, `-T` and `-C`, and for the `authorized_keys` permission rules
- `man 1 ssh-keygen` and `man 1 ssh-copy-id` for making and installing keys
- `man 1 ssh` for `-i`, `-o BatchMode=yes` and the verbose output that explains a refused key
