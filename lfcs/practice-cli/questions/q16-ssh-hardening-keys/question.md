# Q16. Harden sshd, key-only login with one password exception

A user called `deploy` exists on this host, and a key pair for that user is waiting in `/opt/course/16/`:

- private key `/opt/course/16/id_deploy`
- public key `/opt/course/16/id_deploy.pub`

Harden the OpenSSH server so that, for everyone:

- root cannot log in over ssh at all
- password authentication is off
- at most three authentication attempts are allowed per connection

Then make one exception: the user `deploy` may still authenticate with a password.

Install the public key for `deploy` so that `ssh -i /opt/course/16/id_deploy deploy@localhost` logs in without a password. The `authorized_keys` file must be mode 600 and owned by `deploy`.

The grader reads the effective configuration with `sshd -T`, reads it again with `sshd -T -C user=deploy,host=lab,addr=127.0.0.1` to see the exception, opens a real ssh connection as `deploy`, and greps `/etc/ssh/sshd_config` and `/etc/ssh/sshd_config.d/` for the persistent settings.

Two warnings. Run `sshd -t` before restarting the service, because a syntax error with no running daemon cannot be fixed over the network. And make sure your own login still works after the change. Cleanup restores the original configuration, so nothing here is permanent.
