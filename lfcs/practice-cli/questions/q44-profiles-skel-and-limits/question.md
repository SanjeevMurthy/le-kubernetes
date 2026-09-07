# Q44. System-wide environment, skeleton, and per-user limits

The account `ana` exists and uses `/bin/bash`.

1. Every login shell on this host, for every account, must have `EDITOR` set to `vim` and `HISTSIZE` set to `5000`.
2. Every account's own `bin` directory inside its home must be on `PATH` at login. For `ana` that means `/home/ana/bin`, and the same rule must work for any other account without naming it.
3. Every account created from now on must start with a `bin` directory in its home. Then create the account `newbie` with a home directory, to show that it does.
4. `ana` alone must be limited to 100 processes with a hard ceiling of 200, and her sessions must start with 4096 open file descriptors.

The grader runs `su - ana -c '...'` for the environment and the limits, because the shell that wrote the files has already read its own startup files and would report the old values. It also reads the files under `/etc/profile.d/` and `/etc/security/limits.d/`, and looks for `/etc/skel/bin` and `/home/newbie/bin`.
