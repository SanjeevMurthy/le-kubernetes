# LFCS Linux Basics Refresher

The May 2023 curriculum stopped naming the classic Linux basics as competency bullets. Permissions, `find`, archives, text processing, redirection and man page navigation no longer appear in the official domain list, and they are still required by almost every task in it. The exam research report says exactly that in section 1.2: those topics are implicitly required by every other task, and several candidates still report needing them.

This note is the refresher. It has no recipe blocks and no frequency counts, because none of this is a task on its own. It is the layer underneath the tasks. Read it first, type the commands once, and then spend the remaining time on the five domain notes.

Two exam facts shape everything here. The exam is 17 to 20 performance-based tasks in 2 hours with a 67 percent pass mark, which is about six minutes per task. And the only documentation allowed is man pages, the files the distribution installs under `/usr/share/doc`, and packages that are part of the distribution. There is no browser and no internet. A candidate who can drive `man` quickly has a reference book; one who cannot has nothing.

<!-- toc -->
## Table of Contents

- [Moving around](#moving-around)
- [Globbing and brace expansion](#globbing-and-brace-expansion)
- [Finding the answer with no browser](#finding-the-answer-with-no-browser)
- [vim survival](#vim-survival)
- [The permission model](#the-permission-model)
- [Processes and jobs](#processes-and-jobs)
- [Redirection](#redirection)
- [The ten commands every task uses](#the-ten-commands-every-task-uses)
- [Shell habits that save minutes](#shell-habits-that-save-minutes)
- [Memorise](#memorise)

<!-- toc stop -->

## Moving around

```bash
pwd                     # where am I
cd /etc/systemd/system  # absolute
cd ../..                # relative
cd -                    # back to the previous directory
cd                      # home

ls -l  ls -la  ls -ltr  ls -ld  ls -lh  ls -li     # long, hidden, oldest last, dir itself, human, inode
tree -L 2 /etc          # if installed
find /etc -maxdepth 1 -type d      # the portable substitute for tree

cat file  less file  head -20 file  tail -20 file  tail -f /var/log/syslog
file /usr/bin/openssl   # what kind of thing is this
stat -c '%A %U:%G %s %n' file
readlink -f /usr/bin/vi # follow every symlink to the real path
which vi; type -a vi; command -v vi
df -h .                 # which filesystem am I standing on
```

Creating, copying and removing, with the flags that matter:

```bash
touch file; mkdir -p /srv/app/logs
cp -p file /backup/          # -p preserves mode, ownership and timestamps
cp -a dir /backup/           # archive: recursive, preserves everything, keeps symlinks
cp -r dir /backup/           # recursive but resets metadata
mv old new                   # rename and move are the same operation
rm -f file; rm -rf dir       # -f suppresses the error when nothing is there
ln -s /target /link          # symbolic; ln without -s makes a hard link
install -o ana -g devs -m 640 -D src /etc/app/config    # copy and set mode in one step
```

Paths that matter on every task host:

| Path | Holds |
|---|---|
| `/etc` | configuration. Almost every persistent change lands here |
| `/etc/*.d/` | drop-in directories. Prefer a new file here over editing the main file |
| `/var/log` | logs, when the service does not use the journal |
| `/usr/share/doc` | package documentation and example configs, explicitly allowed in the exam |
| `/usr/lib/systemd/system` | vendor units, read only in practice |
| `/etc/systemd/system` | local units and drop-ins, the ones to write |
| `/proc` | live kernel and process state, including `/proc/<pid>/limits` |
| `/tmp` | scratch space, mode 1777, wiped on reboot |
| `/opt` | where exam tasks often ask for an answer file to be written |

## Globbing and brace expansion

The shell expands these before the command ever runs, which is why a command sometimes acts on the wrong files.

| Pattern | Matches |
|---|---|
| `*` | any string including the empty one, but never a leading dot |
| `?` | exactly one character |
| `[abc]` | one character from the set |
| `[a-z]`, `[0-9]` | one character from the range |
| `[!abc]` | one character that is not in the set |
| `.*` | dotfiles, and it also matches `.` and `..`, which is how a recursive delete escapes |
| `{a,b,c}` | brace expansion, not globbing. It expands even when no file matches |
| `{1..5}` | expands to `1 2 3 4 5` |
| `**` | recursive, only after `shopt -s globstar` |

```bash
ls /etc/cron.*                 # cron.d cron.daily cron.hourly ...
cp file{,.bak}                 # expands to: cp file file.bak
mkdir -p /srv/{app,data,logs}
echo *.conf                    # see what a glob expands to before using it
ls -d /etc/ssh/*               # quote the pattern to pass it to find instead
find /etc -name '*.conf'       # the quotes matter: find does the matching, not the shell
```

## Finding the answer with no browser

`man -k` and `apropos` are the same command. Both search the short descriptions of every installed manual page, so they turn "I do not know the command" into "here are six candidates".

```bash
man -k acl                     # apropos acl
man -k 'password.*expire'
man 5 sudoers                  # the file format, not the command
man 8 useradd                  # an administration command
man -f crontab                 # whatis: which sections exist for this name
man 1 crontab; man 5 crontab   # the command and the file are different pages
setfacl --help | less
systemctl --help | grep -i mask
ls /usr/share/doc/openssh-server/
zcat /usr/share/doc/nftables/examples/*.gz | less
grep -rn 'PermitRootLogin' /etc/ssh/
```

Inside `man` and `less`: `/pattern` searches forward, `n` repeats it, `N` reverses it, `G` jumps to the end, `g` to the start, `q` quits. The EXAMPLES section is usually near the bottom, so `G` then `?EXAMPLES` finds it fastest. Always read SEE ALSO; it is how one page leads to the file format page that actually answers the task.

| Manual section | Contains | Example |
|---|---|---|
| 1 | User commands | `man 1 tar` |
| 2 | System calls | `man 2 chmod` |
| 3 | Library functions | `man 3 strftime` |
| 4 | Devices and special files | `man 4 loop` |
| 5 | File formats and configuration files | `man 5 fstab` |
| 7 | Overviews, conventions and miscellany | `man 7 regex` |
| 8 | Administration commands and daemons | `man 8 mount` |

The section number matters because the same name lives in more than one section. `man passwd` gives the command; `man 5 passwd` gives the file layout the task is actually asking about. The same trap applies to `crontab`, `hosts`, `group` and `shadow`.

| When the task is about | Read |
|---|---|
| Persistent mounts | `man 5 fstab`, `man 8 mount` |
| Scheduled jobs | `man 5 crontab`, `man 1 crontab`, `man 5 systemd.timer` |
| SSH server settings | `man 5 sshd_config` |
| Sudo rules | `man 5 sudoers`, `man 8 visudo` |
| Units and services | `man 5 systemd.unit`, `man 5 systemd.service` |
| Account attributes | `man 8 useradd`, `man 1 chage`, `man 5 login.defs` |
| ACLs | `man 1 setfacl`, `man 5 acl` |
| Login limits | `man 5 limits.conf` |
| Certificates | `man 1 openssl-x509`, `man 1 openssl-req` |
| Firewalling | `man 8 nft`, `man 8 iptables`, `man 8 firewall-cmd`, `man 8 ufw` |

## vim survival

The exam remote desktop blocks the INSERT key, so `i` is the only way into insert mode. `Ctrl+W` closes the browser tab, so the exam uses `Ctrl+Alt+W` instead. Terminal copy and paste are `Ctrl+Shift+C` and `Ctrl+Shift+V`.

| Key | Does |
|---|---|
| `i` / `a` / `o` | insert here, insert after the cursor, open a new line below |
| `Esc` | leave insert mode. Press it before every colon command |
| `:w` / `:q` / `:wq` / `:q!` | write, quit, write and quit, quit discarding changes |
| `:w !sudo tee %` | save a file opened without root |
| `dd` / `yy` / `p` / `u` / `Ctrl+r` | delete a line, copy a line, paste, undo, redo |
| `gg` / `G` / `:42` | top of file, end of file, go to line 42 |
| `/pattern` / `n` / `N` | search forward, next match, previous match |
| `:%s/old/new/g` | replace everywhere; add `c` to confirm each one |
| `:set paste` | stop auto-indent from mangling pasted blocks |
| `:set nu` | line numbers, useful when an error message names a line |
| `x` / `D` / `A` | delete a character, delete to end of line, append at end of line |
| `V` then `j` then `d` | visual line select, extend down, delete the selection |
| `:g/pattern/d` | delete every line matching a pattern |

`nano` is installed too and needs no modes. It is a legitimate choice for a three-line edit under time pressure. What is not legitimate is discovering mid-exam that neither editor is familiar.

## The permission model

```bash
ls -l /srv/shared        # -rwxr-x---  1 ana devs  4096 Sep  6 10:00 file
stat -c '%A %a %U:%G %n' /srv/shared
chmod 640 file; chmod u+x,g-w file; chmod -R g+rwX dir
chown ana:devs file; chgrp devs file
umask                    # 0022 gives 644 on files and 755 on directories
id; groups; newgrp devs
```

Read the ten characters of `ls -l` left to right: type, then owner, group and other triples.

| Bit | Octal | On a file | On a directory |
|---|---|---|---|
| `r` | 4 | read the contents | list the names inside |
| `w` | 2 | change the contents | create, rename and delete entries |
| `x` | 1 | execute it | enter it and stat what is inside |
| SUID | 4000 | run as the file's owner, shown as `s` in the owner triple | no effect |
| SGID | 2000 | run as the file's group | new entries inherit the directory's group |
| sticky | 1000 | no effect | only an entry's owner may delete it, as in `/tmp` |

Three rules that decide most tasks. A directory needs `x` for anyone to reach anything inside it, so `r` without `x` on a directory is nearly useless. A numeric `chmod` is absolute and wipes the special bits unless a fourth digit is given, so `chmod 755` clears SUID. And a trailing `+` in the `ls -l` mode means an ACL is present and the nine bits are not the whole story.

## Processes and jobs

```bash
ps aux | head; ps -ef | grep [n]ginx
ps -eo pid,ppid,user,pcpu,pmem,etime,comm --sort=-pcpu | head
pgrep -a nginx; pgrep -u ana -n .        # newest process owned by ana
top -b -n 1 -o %CPU | head -15
kill 1234                # SIGTERM, the polite default
kill -9 1234             # SIGKILL, last resort, no cleanup
kill -HUP 1234           # many daemons reload their config on SIGHUP
pkill -u ana; killall nginx
nice -n 10 ./job.sh; renice -n 5 -p 1234
nohup ./long.sh > /tmp/out 2>&1 &        # survives logout
jobs; bg %1; fg %1                       # Ctrl+Z suspends, bg resumes in background
```

A process has a PID, a parent PID, an owner, a working directory and a set of limits, and all of it is readable under `/proc/<pid>/`. `kill` sends a signal rather than killing anything, which is why `-HUP` reloads and `-TERM` asks politely. Reach for `-9` only after `-TERM` has failed, because it gives the process no chance to flush or clean up.

## Redirection

| Form | Effect |
|---|---|
| `cmd > f` | stdout to `f`, truncating it first |
| `cmd >> f` | stdout appended to `f` |
| `cmd 2> f` | stderr to `f` |
| `cmd > f 2>&1` | both streams to `f`. This order only |
| `cmd &> f` | bash shorthand for the same thing |
| `cmd 2>/dev/null` | discard errors, keep output |
| `cmd < f` | stdin from `f` |
| `cmd <<'EOF' ... EOF` | here-document. The quoted marker stops all expansion |
| `cmd <<< "text"` | here-string |
| `a \| b` | stdout of `a` becomes stdin of `b` |
| `a \|& b` | stdout and stderr of `a` into `b` |
| `cmd \| tee f` | to `f` and to the screen; `tee -a` appends |
| `cmd > f1 2> f2` | output and errors to separate files |

Two facts explain most redirection bugs. The shell sets redirections up left to right, so `> f 2>&1` sends both streams to the file while `2>&1 > f` leaves stderr on the terminal. And `>` truncates the target the instant the line is parsed, before the command runs, so a command that reads and writes the same file destroys it.

## The ten commands every task uses

| Command | The question it answers |
|---|---|
| `man` and `man -k` | what is this, what are its flags, what is the file format |
| `systemctl` | is it running, is it enabled, why did it fail |
| `journalctl -u X -b` | what did it say when it failed |
| `ls -l` and `stat` | who owns it and what is its mode |
| `grep -rn` | which file contains this setting |
| `find` | which files match these attributes |
| `ss -tulpn` | what is listening, and which process owns the port |
| `df -h` and `lsblk -f` | what is mounted, from which device, how full |
| `ip -br a` and `ip r` | what address and which route |
| `getent` | how does this host resolve a user, group or hostname |

Every one of them is read-only, so all ten are safe to run before touching anything. Running the relevant three before an edit and the same three after it is the whole verification method. A worked example on a service task looks like this:

```bash
systemctl is-active nginx; ss -tulpn | grep ':80'; stat -c '%a %U:%G' /etc/nginx/nginx.conf
cp /etc/nginx/nginx.conf{,.bak}
vi /etc/nginx/nginx.conf
nginx -t && systemctl restart nginx
systemctl is-active nginx; systemctl is-enabled nginx; ss -tulpn | grep ':80'
```

## Shell habits that save minutes

```bash
sudo -i                                  # first command on every task host
PS1='\u@\h:\w\$ '                        # keeps the hostname visible
hostname                                 # confirm the host before typing anything
cp /etc/ssh/sshd_config{,.bak}           # back up before every edit
Ctrl+R                                   # search shell history
history | grep netplan
Tab Tab                                  # complete a command or a path
Ctrl+A  Ctrl+E  Ctrl+U  Ctrl+K  Ctrl+L   # line start, line end, cut left, cut right, clear
!!                                       # repeat the last command, as in: sudo !!
```

Validators that catch a mistake before it costs a task: `visudo -c` for sudoers, `sshd -t` for the SSH server, `mount -a` and `findmnt --verify` for `/etc/fstab`, `bash -n` for a script, `systemd-analyze verify` for a unit, `nft -c -f` for a ruleset, and `netplan try` for a network change, which reverts itself if nothing confirms it.

## Memorise

- The exam allows only man pages, `/usr/share/doc` and installed packages. `man -k`, `apropos` and `cmd --help | less` replace every search engine.
- Section numbers matter: `man 1 passwd` is the command and `man 5 passwd` is the file. The same split applies to `crontab`, `hosts`, `group` and `shadow`.
- In `man` and `less`, `/pattern`, `n`, `G` and `q` are the whole interface, and EXAMPLES is usually at the bottom.
- The shell expands globs before the command sees them, so quote a pattern meant for `find`, and `echo *.conf` shows what will actually happen.
- Brace expansion is not globbing. `cp file{,.bak}` works whether or not anything matches.
- A directory needs `x` before its contents can be reached, a numeric `chmod` wipes the special bits, and a trailing `+` in `ls -l` means an ACL is hiding the truth.
- SGID on a directory makes new files inherit its group, and the sticky bit stops users deleting each other's files.
- `kill` sends a signal: `-TERM` asks, `-HUP` usually reloads, `-9` is the last resort with no cleanup.
- `> f 2>&1` redirects both streams and the reverse order does not, and `>` truncates before the command runs.
- A quoted here-document marker such as `<<'EOF'` stops the shell expanding anything inside the block, which is what a configuration file needs.
- `sudo -i` first, `hostname` second, back up the file third, edit fourth, verify fifth.
- `visudo -c`, `sshd -t`, `mount -a`, `bash -n`, `systemd-analyze verify` and `netplan try` are the six validators worth memorising.
- In vim: `i` to insert, `Esc` to leave, `:wq` to save and quit, `:q!` to abandon, `:set paste` before pasting. The INSERT key is disabled in the exam and `Ctrl+Alt+W` replaces `Ctrl+W`.
- `cp -p` and `cp -a` preserve metadata and plain `cp` does not, which is what "preserve permissions" in a prompt means.
- The ten read-only commands, `man`, `systemctl`, `journalctl`, `ls -l`, `grep -rn`, `find`, `ss -tulpn`, `df -h`, `ip -br a` and `getent`, answer nearly every question a task asks before and after the change.
- Ask one question before leaving any task: would this survive a reboot. If no file changed, the answer is no.

This note deliberately stops at exam technique. For the internals underneath it, the process, memory, filesystem, networking and kernel notes at https://github.com/SanjeevMurthy/le-linux go much deeper than the LFCS needs, and are the right place to go after the certification rather than before it.
