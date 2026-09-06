# LFCS Essential Commands (20%)

Essential Commands is 20 percent of the LFCS exam. The exam is 17 to 20 performance-based tasks in 2 hours, and 67 percent is the pass mark, so roughly six minutes per task and no room to research a command.

The only documentation allowed is man pages, the documents the distribution installs under `/usr/share/doc`, and packages that are part of the distribution. There is no browser and no internet. Every `**Docs.**` line below therefore names a man page and its section instead of a URL, and every command in this note is one that a stock Ubuntu or Rocky install already has.

Each task runs on its own designated host, reached with `ssh <nodename>` from the `base` host. Never reboot `base`. Nested SSH is not supported, so `exit` back to `base` before connecting anywhere else. `sudo -i` gives root on any task host. Never block ports 8080, 4505 or 4506, because that ends the exam session. Graders score the end state, not the method, and they score it after a reboot, so every recipe below ends with a verification command and every persistent change names the file that makes it persist.

<!-- toc -->
## Table of Contents

- [What the exam asks](#what-the-exam-asks)
- [Recipe 1: Git basics from clone to first commit](#recipe-1-git-basics-from-clone-to-first-commit)
- [Recipe 2: Create, enable and troubleshoot a service](#recipe-2-create-enable-and-troubleshoot-a-service)
- [Recipe 3: Monitor system performance](#recipe-3-monitor-system-performance)
- [Recipe 4: Application and service specific constraints](#recipe-4-application-and-service-specific-constraints)
- [Recipe 5: Troubleshoot a filesystem that is nearly full](#recipe-5-troubleshoot-a-filesystem-that-is-nearly-full)
- [Recipe 6: Work with SSL certificates](#recipe-6-work-with-ssl-certificates)
- [Recipe 7: Text processing with grep, sed and awk](#recipe-7-text-processing-with-grep-sed-and-awk)
- [Recipe 8: find, permissions and the special bits](#recipe-8-find-permissions-and-the-special-bits)
- [Recipe 9: Archives, links and redirection](#recipe-9-archives-links-and-redirection)
- [Ubuntu vs Rocky](#ubuntu-vs-rocky)
- [Quick reference](#quick-reference)
- [Memorise](#memorise)

<!-- toc stop -->

## What the exam asks

| Task type | Sources | Drill |
|---|---|---|
| OpenSSL certificate inspection, generation and web server use | 4 | Q33 (planned) |
| systemd: write a unit, enable it, diagnose a failing service | 2 | Q38 (planned) |
| Process and IO monitoring, system performance | 1 | Q39 (planned) |
| Application and service resource limits | 1 | Q40 (planned) |
| Git basics: clone, branch, commit, `.gitignore` | 1 | Q32 (planned) |
| `find` with permission, size and time filters plus `-exec` | 1 | Q34 (planned) |
| Hard and soft links | 1 | Q36 (planned) |
| Archives with tar, gzip, bzip2, xz and zip | 1 | Q36 (planned) |
| Shell scripting and I/O redirection | 1 | Q37 (planned) |
| Disk-space troubleshooting | 0 exam reports, 2 practice sources | Q31 (planned) |
| Text processing with grep, sed and awk | no standalone row | Q35 (planned) |

Sources are distinct candidate write-ups counted in the exam research report, section 3. OpenSSL is the third most reported task type on the whole exam, tied with containers, so treat Recipe 6 as the highest value page in this note. Text processing has no row of its own because it is never the task; it is the tool used inside the other tasks.

## Recipe 1: Git basics from clone to first commit

**Goal.** A cloned repository with a new branch, a `.gitignore`, and a commit that `git log` shows with the right author.

**Frequency.** 1 candidate source (research section 3, git basics row). Drill: Q32 (planned).

**Commands.**
```bash
# Identity first. Without both values git refuses to create the commit and prints
# "Please tell me who you are". That is the classic time sink in this task.
git config --global user.name "Ana Diaz"
git config --global user.email "ana@example.com"

git clone /srv/git/app.git /home/ana/app
cd /home/ana/app

git checkout -b feature/logging    # create and switch
git switch -c feature/logging      # the same thing in newer syntax

printf '*.log\nbuild/\n' > .gitignore
git add .gitignore src/app.py
git status
git diff --staged                  # exactly what the next commit will contain
git commit -m "Add gitignore and logging"

git log --oneline -5
git push -u origin feature/logging

git stash && git stash list && git stash pop     # park and restore uncommitted work
```
**Verify.**
```bash
git -C /home/ana/app rev-parse --abbrev-ref HEAD      # expect feature/logging
git -C /home/ana/app log --oneline -1
git -C /home/ana/app log -1 --format='%an <%ae>'      # the identity that was set
git -C /home/ana/app status --short                   # empty means nothing left uncommitted
git -C /home/ana/app check-ignore -v build/x.o        # proves .gitignore matches
```
**Gotchas.**
- Both `user.name` and `user.email` must be set before the first commit. Run them as the user who must own the commit, not through `sudo`, or the author line names root.
- `--global` writes `~/.gitconfig` and follows the user across repositories, which is what makes the identity persist. `--local` writes `.git/config` inside one repository only.
- `git add .gitignore` is still required. A `.gitignore` stops untracked files from being staged; it never removes a file that is already tracked. Use `git rm --cached <file>` for that.
- `git commit -m` with nothing staged exits non-zero and writes no commit, and `-u` on the first push records the upstream so a later bare `git push` works.
- Every ssh task host has git preinstalled and the `base` host does not, which is one more reason never to work on `base`.

**Docs.** `man 1 git`, `man 1 git-commit`, `man 1 git-config` for the `user.name` and `user.email` keys, `man 5 gitignore` for the pattern syntax. `git help -a` lists every subcommand offline.

## Recipe 2: Create, enable and troubleshoot a service

**Goal.** A unit that starts at boot, runs the right binary as the right user, and is still running after a reboot. Or a broken unit repaired and proven active.

**Frequency.** 2 candidate sources (research section 3, systemd unit row). Drill: Q38 (planned).

**Commands.**
```bash
sudo -i
cat > /etc/systemd/system/inventory.service <<'UNIT'
[Unit]
Description=Inventory API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=app
ExecStart=/usr/local/bin/inventory --port 9090
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now inventory.service

# Diagnosing a unit that will not start.
systemctl status inventory.service --no-pager -l
journalctl -u inventory.service -b --no-pager | tail -30
systemd-analyze verify /etc/systemd/system/inventory.service
SYSTEMD_LOG_LEVEL=debug systemctl start inventory.service

ss -tlpn | grep ':9090'                   # another process already holding the port
systemctl list-units --state=failed
systemctl unmask inventory.service        # a masked unit refuses every start
```
**Verify.**
```bash
systemctl is-active inventory.service     # expect active
systemctl is-enabled inventory.service    # expect enabled, this is the persistence check
systemctl show -p MainPID -p User -p ExecStart inventory.service
systemctl cat inventory.service           # the effective unit plus every drop-in
ss -tlpn | grep ':9090'
```
**Gotchas.**
- `start` affects only the current boot. `enable` creates the symlink under `/etc/systemd/system/multi-user.target.wants/` and is the thing that survives a reboot. `enable --now` does both, and a task that says "on boot" is graded with `systemctl is-enabled`.
- Without an `[Install]` section `enable` reports "no installation config" and nothing persists. `WantedBy=multi-user.target` is the normal answer.
- Run `systemctl daemon-reload` after every unit edit, otherwise systemd keeps the copy it loaded earlier and the change looks ignored.
- `ExecStart` takes an absolute path and no shell syntax. Pipes, `&&` and variable expansion need `ExecStart=/bin/bash -c '...'`.
- Never edit a vendor unit under `/usr/lib/systemd/system`. Use `systemctl edit <unit>`, which writes `/etc/systemd/system/<unit>.d/override.conf` and survives a package upgrade.
- A masked unit is a symlink to `/dev/null` and fails with "Unit is masked". `systemctl unmask` before anything else.

**Docs.** `man 5 systemd.unit`, `man 5 systemd.service`, `man 5 systemd.exec`, `man 1 systemctl`, `man 1 journalctl`. Working examples are readable on the host under `/usr/lib/systemd/system/`.

## Recipe 3: Monitor system performance

**Goal.** Identify the CPU, memory or disk pressure the task names, and write the answer to the exact path it asks for.

**Frequency.** 1 candidate source for process and IO monitoring (research section 3, process management row), corroborated by a KodeKloud mock task that asks for the PID of the heaviest disk reader. Drill: Q39 (planned).

**Commands.**
```bash
uptime                  # load over 1, 5 and 15 minutes
cat /proc/loadavg
nproc                   # divide the load by this before calling it high

top -b -n 1 -o %CPU | head -15
top -b -n 1 -o %MEM | head -15

ps -eo pid,ppid,user,pcpu,pmem,rss,etime,comm --sort=-pcpu | head -10

free -m                 # read the "available" column, not "free"
vmstat 1 5              # watch the r, b, si, so and wa columns
iostat -xz 1 3          # per-device utilisation, needs the sysstat package
pidstat -d 1 3          # per-process disk read and write rates, needs root
sar -u 1 3              # historical CPU once sysstat collection is enabled

# Write only the value the task asked for, with no label around it.
echo 1234 > /opt/highread.pid
```
**Verify.**
```bash
cat /opt/highread.pid
ps -p "$(cat /opt/highread.pid)" -o pid,comm,user --no-headers
uptime; nproc; free -m
```
**Gotchas.**
- `pidstat -d` and `iotop` show empty disk columns for a normal user. Run them after `sudo -i`.
- `iostat`, `pidstat`, `sar` and `mpstat` all come from the `sysstat` package. Installing distribution packages during the exam is explicitly allowed.
- Installing `sysstat` does not enable history collection. `sar` keeps printing "Cannot open /var/log/sa..." until collection is turned on, which is a separate step and differs between Ubuntu and Rocky.
- Load average counts runnable and uninterruptible tasks, so a load of 8 on 8 CPUs is exactly full and not overloaded. Report `nproc` beside it, and read the "available" column of `free` rather than "free", because page cache is reclaimable.
- Write the file exactly as worded. A grader matching a bare number fails on `PID: 1234`.

**Docs.** `man 1 top`, `man 1 ps` and its STANDARD FORMAT SPECIFIERS section for `-o`, `man 1 vmstat`, `man 1 free`, `man 1 pidstat`, `man 1 iostat`, `man 1 sar`, `man 5 proc` for `/proc/loadavg`.

## Recipe 4: Application and service specific constraints

**Goal.** A service that cannot exceed a named limit on open files, tasks, memory or CPU, with the limit still in force after a reboot.

**Frequency.** 1 candidate source (research section 3, resource limits row). Drill: Q40 (planned).

**Commands.**
```bash
sudo -i
# Read what the unit has now.
systemctl show inventory.service -p LimitNOFILE -p TasksMax -p MemoryMax -p CPUQuotaPerSecUSec

# Persist per-service limits in a drop-in, never in the vendor unit.
mkdir -p /etc/systemd/system/inventory.service.d
cat > /etc/systemd/system/inventory.service.d/limits.conf <<'DROPIN'
[Service]
LimitNOFILE=65535
LimitNPROC=4096
TasksMax=512
MemoryMax=512M
CPUQuota=50%
DROPIN
systemctl daemon-reload
systemctl restart inventory.service

systemctl edit inventory.service   # writes the same drop-in interactively

# Interactive shell limits. Current shell and its children only.
ulimit -n        # soft open files
ulimit -Hn       # hard open files
ulimit -u        # max user processes

# What the running process actually received.
cat /proc/"$(systemctl show -p MainPID --value inventory.service)"/limits
```
**Verify.**
```bash
systemctl show inventory.service -p LimitNOFILE --value      # expect 65535
systemctl show inventory.service -p TasksMax -p MemoryMax
grep 'Max open files' /proc/"$(systemctl show -p MainPID --value inventory.service)"/limits
systemctl cat inventory.service          # the header lists every drop-in that applied
```
**Gotchas.**
- `ulimit` changes the current shell only and is never the answer to a persistence question.
- Services do not read `/etc/security/limits.conf`. PAM applies that file at login, and systemd starts services without a login session. Per-service limits belong in a unit drop-in. The login side is Recipe 4 of note `05-users-and-groups.md`.
- `LimitNOFILE` is the systemd spelling and `nofile` is the `limits.conf` spelling. Mixing them silently does nothing.
- `MemoryMax` kills the service when it is exceeded and `MemoryHigh` only throttles it, so read which behaviour the task wants.
- `daemon-reload` alone is not enough, because the running process keeps its old limits until the service restarts. `systemctl edit --full` copies the whole unit into `/etc` and then never picks up vendor changes, so prefer the plain drop-in.

**Docs.** `man 5 systemd.resource-control` for `TasksMax`, `MemoryMax` and `CPUQuota`, `man 5 systemd.exec` for the `Limit*` directives, `man 5 limits.conf`, and `man 1 bash` under the `ulimit` builtin.

## Recipe 5: Troubleshoot a filesystem that is nearly full

**Goal.** Find what filled the filesystem the task names, release the space, and prove the result with `df`.

**Frequency.** No exam report in research section 3, and 2 practice sources (a KodeKloud mock task on a 98 percent full `/data`, plus admincool's notes). Drill: Q31 (planned).

**Commands.**
```bash
df -h                  # which filesystem is full
df -i                  # a full inode table looks identical from user space
du -xh --max-depth=1 /data 2>/dev/null | sort -h | tail -10

find /data -xdev -type f -size +100M -exec ls -lh {} \; | sort -k5 -h | tail

# Space held by a deleted file that a process still has open.
# df stays full while du finds nothing.
lsof +L1 | head
lsof -nP /data | grep deleted
systemctl restart rsyslog        # releasing the handle returns the space
: > /var/log/huge.log            # truncate a live log instead of deleting it

journalctl --disk-usage && journalctl --vacuum-size=200M
apt clean                        # Ubuntu
dnf clean all                    # Rocky
```
**Verify.**
```bash
df -h /data
df -i /data
du -xsh /data
lsof +L1 | wc -l          # expect 0 remaining deleted-but-open files
```
**Gotchas.**
- `du` counts names and `df` counts blocks. When the two disagree the space sits in a deleted but still open file. Restart the writer or truncate its log; deleting the name a second time does nothing.
- `-x` on `du` and `-xdev` on `find` keep the scan inside one filesystem. Without them the totals include other mounts and the scan takes far longer.
- A filesystem can be full on inodes with gigabytes of bytes free, so check `df -i` before hunting for large files.
- ext4 reserves 5 percent for root, so a filesystem that is "100 percent" for a normal user still accepts root writes. `tune2fs -m 1 /dev/sdb1` lowers the reserve and that change persists in the superblock.
- Never delete a file the task did not name. Truncate logs, vacuum the journal, clean package caches.

**Docs.** `man 1 df`, `man 1 du`, `man 8 lsof`, `man 1 find`, `man 1 journalctl` for `--vacuum-size`, `man 8 tune2fs`.

## Recipe 6: Work with SSL certificates

**Goal.** Read the fields of a certificate, create a self-signed certificate or a CSR, validate a chain, and prove a private key belongs to a certificate.

**Frequency.** 4 candidate sources (research section 3, SSL and TLS certificate row), which ties this with containers as the third most reported task type on the exam. Drill: Q33 (planned).

**Commands.**
```bash
# Inspect. This is the reported task: report the common name and the expiry.
openssl x509 -in /etc/ssl/certs/site.crt -noout -subject -enddate -issuer
openssl x509 -in site.crt -noout -text | less
openssl x509 -in site.crt -noout -serial -ext subjectAltName -fingerprint -sha256
openssl x509 -in site.crt -noout -checkend 604800; echo "exit=$?"   # 1 if it expires within 7 days

# Self-signed certificate and key in one command.
openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout /etc/ssl/private/site.key -out /etc/ssl/certs/site.crt \
  -subj "/C=IN/ST=KA/L=Bengaluru/O=Example/CN=web.example.com" \
  -addext "subjectAltName=DNS:web.example.com"

# Certificate signing request against an existing key.
openssl genrsa -out site.key 2048
openssl req -new -key site.key -out site.csr -subj "/CN=web.example.com"
openssl req -in site.csr -noout -text -verify

# Chain validation.
openssl verify -CAfile /etc/ssl/certs/ca.crt site.crt        # expect "site.crt: OK"

# What a live server presents.
openssl s_client -connect web.example.com:443 -servername web.example.com </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -dates -issuer

# Does this key match this certificate? The two hashes must be identical.
openssl x509 -noout -modulus -in site.crt | openssl sha256
openssl rsa  -noout -modulus -in site.key | openssl sha256
openssl req  -noout -modulus -in site.csr | openssl sha256

chown root:root /etc/ssl/private/site.key
chmod 600 /etc/ssl/private/site.key
```
**Verify.**
```bash
openssl x509 -in /etc/ssl/certs/site.crt -noout -subject -enddate
diff <(openssl x509 -noout -modulus -in site.crt) \
     <(openssl rsa -noout -modulus -in site.key) && echo MATCH
openssl verify -CAfile ca.crt site.crt
stat -c '%a %U:%G %n' /etc/ssl/private/site.key     # expect 600 root:root
```
**Gotchas.**
- `-noout` suppresses the base64 blob. Without it the fields scroll off the screen.
- `-nodes` leaves the private key unencrypted. Without it openssl prompts for a passphrase and the web server then cannot start unattended.
- `-subj` must begin with a slash and separate components with slashes. `CN=x` without the leading slash is rejected.
- `-days` belongs to `req -x509`, because a CSR has no validity period. `openssl s_client` needs `-servername` against any host serving more than one certificate, otherwise it returns the default virtual host.
- Comparing the sha256 of the modulus is the only reliable key-to-certificate check. File sizes and timestamps prove nothing.
- A private key readable by anyone but root is a graded failure in its own right, so `chmod 600` every time. The trust store path differs by distribution and a new CA only persists once the extract command has run, so see the Ubuntu vs Rocky table below.

**Docs.** `man 1 openssl`, `man 1 openssl-x509`, `man 1 openssl-req`, `man 1 openssl-verify`, `man 1 openssl-rsa`, `man 1 openssl-s_client`, `man 5 config` for the field names used by `-subj`. `openssl x509 -help` and `openssl req -help` list every option offline.

## Recipe 7: Text processing with grep, sed and awk

**Goal.** Extract, count or rewrite the lines a task names, and write the result to the exact path requested.

**Frequency.** No standalone row in research section 3. Text processing is the tool used inside other tasks, most visibly the shell scripting and I/O redirection row (1 source) and the disk-space row. Drill: Q35 (planned).

**Commands.**
```bash
grep -E 'ERROR|FATAL' /var/log/app.log
grep -c 'ERROR' /var/log/app.log                     # counts matching lines
grep -o '[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}' access.log | sort -u   # only the match
grep -v '^#' /etc/ssh/sshd_config | grep -v '^$'     # strip comments and blank lines
grep -rn 'ListenAddress' /etc                        # which file holds this setting

sed -n '10,20p' file                                 # print a line range
sed -i.bak 's,http://,https://,g' /etc/app/config.ini
sed -i '/^DEBUG/d' /etc/app/config.ini               # delete matching lines
sed -i 's/^#\s*\(PermitRootLogin\).*/\1 no/' /etc/ssh/sshd_config

awk -F: '$3 >= 1000 {print $1}' /etc/passwd          # normal user names
awk -F, '{print $3}' data.csv
awk '{sum += $5} END {print sum}' access.log

cut -d: -f1,7 /etc/passwd
tr 'a-z' 'A-Z' < names.txt
tr -s ' ' < spaced.txt
wc -l /var/log/app.log

# The classic one-liner: the five most frequent values in a column.
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -5 > /opt/top-ips.txt
find /var/log -name '*.log' -print0 | xargs -0 grep -l 'ERROR'
grep 'ERROR' app.log | tee /opt/errors.txt | wc -l
```
**Verify.**
```bash
cat /opt/top-ips.txt
wc -l < /opt/top-ips.txt                  # expect exactly 5
diff /etc/app/config.ini /etc/app/config.ini.bak
grep -c 'http://' /etc/app/config.ini     # expect 0
```
**Gotchas.**
- `sed -i` with no suffix edits in place with no undo. `sed -i.bak` leaves the original beside it, costs nothing, and has saved many tasks.
- Run any `sed` once without `-i` and read the output first. In-place edits of `/etc/fstab` or `sshd_config` are how candidates lock themselves out of a host.
- `sed` accepts any delimiter, so `s,http://,https://,g` avoids escaping every slash in a URL.
- `grep -c` counts lines, not matches, so when one line can match twice use `grep -o pattern file | wc -l`.
- In awk, `-F:` splits on a literal colon, fields run from `$1` upward, `$0` is the whole line, `NF` is the field count and `NR` the record number.
- Basic regular expressions need `\{1,3\}` and `\(...\)`; `grep -E` and `sed -E` take the unescaped forms. Pick one dialect per command and stay in it.
- `uniq` only collapses adjacent duplicates, so the `sort` before it is mandatory. `sort -rn` is numeric and descending, and `sort -h` understands the K, M and G suffixes that `du -h` prints.

**Docs.** `man 1 grep`, `man 1 sed`, `man 1 awk` (often a link to `man 1 gawk` or `man 1 mawk`), `man 1 sort`, `man 1 uniq`, `man 1 cut`, `man 1 tr`, `man 1 xargs`, and `man 7 regex` for the regular expression syntax itself.

## Recipe 8: find, permissions and the special bits

**Goal.** Locate files by owner, size, age or permission bits, act on them, and set the ownership and mode a task names.

**Frequency.** 1 candidate source for `find` and 1 for SUID, SGID and sticky bits (research section 3, find row and permissions row). Drill: Q34 (planned).

**Commands.**
```bash
find /data -type f -user ana -size +1M -mtime -7
find /var/log -type f -name '*.log' -mmin -30
find / -xdev -type f -perm -4000 2>/dev/null        # every SUID binary
find / -xdev -type f -perm -2000 2>/dev/null        # every SGID binary
find /data -type d -perm /0002 -o -type f -size +100M   # world-writable dirs or big files
find /data -type f -size +100M -exec cp -p {} /backup/ \;
find /data -type f -name '*.tmp' -exec rm -f {} +   # + batches, \; runs once per file
find /home -maxdepth 2 -type d -empty -delete

chown -R ana:devs /srv/project
chmod 640 /srv/project/config
chmod -R g+rwX /srv/project      # capital X adds execute on directories only
chmod 3775 /srv/shared           # leading 3 = SGID + sticky, then rwxrwxr-x
chmod g+s /srv/shared            # SGID: new files inherit the directory group
chmod +t /srv/upload             # sticky: only the owner may delete their file
chmod u+s /usr/local/bin/tool    # SUID: the program runs as the file owner

umask                            # 0022 yields 644 files and 755 directories
umask 0027                       # current shell only
```
**Verify.**
```bash
stat -c '%A %a %U:%G %n' /srv/shared      # expect drwxrwsr-t and 3775
find /srv/project ! -user ana | head      # empty means chown -R covered everything
sudo -u ana touch /srv/shared/f && stat -c '%U:%G %n' /srv/shared/f
getfacl -p /srv/shared                    # confirms no ACL is overriding the mode
```
**Gotchas.**
- `-perm -4000` means "at least these bits", `-perm /4000` means "any of these bits", and bare `-perm 4000` means "exactly this mode". The dash form is the one that finds SUID files.
- `-exec cmd {} \;` runs once per file and `-exec cmd {} +` batches them, with the semicolon escaped. Put `-type f` before `-exec` so the action never fires on a directory.
- `cp` without `-p` resets ownership, mode and timestamps. Any task that says "preserve" means `cp -p` or `cp -a`.
- Numeric modes are absolute, so `chmod 755` clears SUID, SGID and sticky unless a fourth digit is given. `chmod 4755` keeps SUID.
- SGID on a directory makes new files inherit the directory's group, which is how a shared project directory is built, while SGID on a file makes the program run with the file's group. The sticky bit on a world-writable directory stops users deleting each other's files, and `/tmp` is the model at mode 1777.
- `umask` is subtractive and applies only to files created afterwards. Making it persistent means writing it into `/etc/profile.d/` or the user's `~/.bashrc`, which is Recipe 3 of note `05-users-and-groups.md`.

**Docs.** `man 1 find` and its EXPRESSION section for `-perm`, `-size` and `-mtime`, `man 1 chmod`, `man 1 chown`, `man 1 stat`, `man 7 inode` for the mode bits, and `man 1 bash` under the `umask` builtin.

## Recipe 9: Archives, links and redirection

**Goal.** Build or unpack the archive a task names, create the link it asks for, and send output and errors to the files it names.

**Frequency.** 1 candidate source for archives, 1 for hard and soft links, and 1 for shell scripting and I/O redirection (research section 3). Drills: Q36 and Q37 (planned).

**Commands.**
```bash
# c create, x extract, t list, z gzip, j bzip2, J xz, f file, v verbose, p permissions.
tar czf /backup/etc.tar.gz /etc
tar cJf /backup/data.tar.xz --exclude='*.tmp' --exclude='cache' /data
tar czf /backup/home.tar.gz -C /home ana      # -C drops the leading path

tar tzf /backup/etc.tar.gz | head             # always list before extracting
tar xzf /backup/etc.tar.gz -C /restore
tar xJf /backup/data.tar.xz -C /restore --same-owner -p

gzip -k file.txt && gunzip file.txt.gz
xz -k -9 file.txt && unxz file.txt.xz
zip -r /backup/site.zip /var/www/site && unzip -l /backup/site.zip

ln -s /opt/app/current/bin/app /usr/local/bin/app   # symbolic, crosses filesystems
ln /data/report.csv /data/archive/report.csv        # hard, same filesystem only
readlink -f /usr/local/bin/app

cmd > out.txt          # stdout, truncating
cmd >> out.txt         # stdout, appending
cmd 2> err.txt         # stderr only
cmd > out.txt 2>&1     # both into one file, in this order
cmd &> all.txt         # bash shorthand for the same thing
cmd 2>/dev/null        # discard errors
cmd | tee out.txt      # to the file and to the screen

cat > /usr/local/bin/report.sh <<'SCRIPT'
#!/bin/bash
set -euo pipefail
du -xh --max-depth=1 /data | sort -h > /var/log/report.out 2> /var/log/report.err
SCRIPT
chmod 755 /usr/local/bin/report.sh
```
**Verify.**
```bash
tar tzf /backup/etc.tar.gz | head -3
file /backup/data.tar.xz                  # expect XZ compressed data
test -L /usr/local/bin/app && readlink -f /usr/local/bin/app
stat -c '%i' /data/report.csv /data/archive/report.csv   # identical inode means hard link
stat -c '%h' /data/report.csv             # link count 2
bash -n /usr/local/bin/report.sh          # syntax check without running it
```
**Gotchas.**
- `> out.txt 2>&1` works and `2>&1 > out.txt` does not. Redirections are applied left to right, so the second form aims stderr at the terminal that stdout still pointed to.
- `>` truncates the target the moment the shell parses the line, before the command runs, so `cmd > file` where `file` is also the input empties it.
- `tar` chooses the compressor from the flag, not the file name, so `tar czf x.tar.xz` writes gzip data under a misleading name. GNU tar accepts `-a` to pick from the suffix instead.
- Extract as root with `-p` to keep permissions, and pass `-C /target` because tar strips the leading slash and extracts relative to the working directory.
- A hard link cannot cross a filesystem and cannot point at a directory. A symlink does both but breaks when its target moves, and a relative symlink resolves from the directory holding the link, so prefer absolute targets.
- A `#!/bin/bash` shebang, mode 755 and `set -euo pipefail` are what turn a text file into a script that a unit or a cron job can actually run.

**Docs.** `man 1 tar`, `man 1 gzip`, `man 1 xz`, `man 1 zip`, `man 1 ln`, `man 1 readlink`, `man 1 stat`, `man 7 symlink`, and `man 1 bash` under REDIRECTION.

## Ubuntu vs Rocky

The distribution is not stated officially. Ubuntu is the most likely, and RHEL-family nodes are possible, so know both columns.

| Task | Ubuntu | Rocky |
|---|---|---|
| Install git, sysstat, archivers | `apt install -y git sysstat zip unzip xz-utils` | `dnf install -y git sysstat zip unzip xz` |
| Enable sysstat history collection | set `ENABLED="true"` in `/etc/default/sysstat`, then `systemctl enable --now sysstat` | `systemctl enable --now sysstat` |
| Certificate directory | `/etc/ssl/certs` | `/etc/pki/tls/certs` |
| Private key directory | `/etc/ssl/private` | `/etc/pki/tls/private` |
| Add a CA to the trust store | copy to `/usr/local/share/ca-certificates/x.crt`, then `update-ca-certificates` | copy to `/etc/pki/ca-trust/source/anchors/x.crt`, then `update-ca-trust extract` |
| Web server package, user and root | `apache2`, user `www-data`, `/var/www/html` | `httpd`, user `apache`, `/var/www/html` |
| Which package owns a file | `dpkg -S /usr/bin/openssl` | `rpm -qf /usr/bin/openssl` |
| Clear the package cache | `apt clean` | `dnf clean all` |
| Vendor unit directory | `/lib/systemd/system` | `/usr/lib/systemd/system` |
| Extra security layer on a service task | AppArmor profiles under `/etc/apparmor.d/` | SELinux contexts, booleans and ports |

## Quick reference

```bash
# git
git config --global user.name "N"; git config --global user.email "e@x"
git switch -c feature/x; git add -A; git commit -m "msg"; git push -u origin feature/x
git -C /path rev-parse --abbrev-ref HEAD; git -C /path log --oneline -1

# systemd services and limits
systemctl daemon-reload; systemctl enable --now svc; systemctl is-active svc; systemctl is-enabled svc
journalctl -u svc -b --no-pager | tail -30; systemctl cat svc; ss -tlpn | grep ':PORT'
systemctl show svc -p LimitNOFILE -p TasksMax -p MemoryMax
cat /proc/"$(systemctl show -p MainPID --value svc)"/limits

# performance and disk space
uptime; nproc; free -m; vmstat 1 5; top -b -n1 -o %CPU | head -15
ps -eo pid,pcpu,pmem,rss,comm --sort=-pcpu | head; pidstat -d 1 3; iostat -xz 1 3
df -h; df -i; du -xh --max-depth=1 /data | sort -h | tail
lsof +L1; : > /var/log/big.log; journalctl --vacuum-size=200M

# openssl
openssl x509 -in c.crt -noout -subject -enddate -issuer
openssl req -x509 -newkey rsa:2048 -nodes -days 365 -keyout k.key -out c.crt -subj "/CN=host"
openssl req -new -key k.key -out c.csr -subj "/CN=host"; openssl verify -CAfile ca.crt c.crt
openssl s_client -connect host:443 -servername host </dev/null 2>/dev/null | openssl x509 -noout -subject
openssl x509 -noout -modulus -in c.crt | openssl sha256

# text
grep -rn 'pattern' /etc; grep -c ERROR f; grep -o RE f | wc -l
sed -i.bak 's,a,b,g' f; sed -n '5,10p' f; sed -i '/^#/d' f
awk -F: '$3>=1000 {print $1}' /etc/passwd; sort f | uniq -c | sort -rn | head -5

# find, permissions, archives, links, redirection
find /d -type f -user u -size +1M -mtime -7; find / -xdev -type f -perm -4000 2>/dev/null
find /d -type f -name '*.tmp' -exec rm -f {} +
chmod 3775 /srv/shared; chown -R u:g /srv/p; stat -c '%A %a %U:%G' /srv/shared
tar czf a.tar.gz /d; tar cJf a.tar.xz --exclude='*.tmp' /d; tar tzf a.tar.gz; tar xJf a.tar.xz -C /r
ln -s /target /link; ln /f /hardlink; stat -c '%i %h' /f /hardlink
cmd > out 2>&1; cmd 2>/dev/null; cmd | tee out
```

## Memorise

- Set `git config --global user.name` and `user.email` before the first commit, as the owning user, or the commit fails outright.
- `enable` is persistence and `start` is not. `systemctl enable --now` does both, and `[Install] WantedBy=multi-user.target` is what makes `enable` work at all.
- `systemctl daemon-reload` after every unit edit, then restart the service for the new limits to apply.
- Per-service limits are a drop-in at `/etc/systemd/system/<unit>.d/limits.conf` with `LimitNOFILE`, `TasksMax`, `MemoryMax` and `CPUQuota`. `ulimit` and `limits.conf` do not reach services.
- When `df` says full and `du` says empty, the space is in a deleted but open file. Find it with `lsof +L1` and release it by restarting the writer.
- `df -i` before hunting for large files, and `openssl x509 -in cert -noout -subject -enddate -issuer` is the certificate inspection answer.
- `openssl req -x509 -newkey rsa:2048 -nodes -days 365 -keyout k -out c -subj "/CN=host"` creates a self-signed pair, and `-nodes` is what leaves the key usable unattended.
- Match a key to a certificate by comparing `openssl x509 -noout -modulus` with `openssl rsa -noout -modulus`. Key files are `chmod 600` and root owned.
- `sed -i.bak` always, read the output once without `-i` first, and remember that `sort | uniq -c | sort -rn | head -5` needs its leading `sort`.
- `-perm -4000` finds SUID, `-perm /0002` finds world writable, `-exec {} +` batches and `-exec {} \;` does not.
- `chmod 3775` is SGID plus sticky, and a numeric mode wipes the special bits unless a fourth digit is present.
- `> out 2>&1` redirects both streams; the reversed order does not.
- `tar` reads the compression from the flag, so match `z` to `.gz`, `J` to `.xz` and `j` to `.bz2`, and pass `-C` when extracting. Identical inode numbers prove a hard link and `readlink -f` proves a symlink target.
- Allowed documentation is `man`, `/usr/share/doc` and installed packages only. `man -k` and `cmd --help | less` replace the browser.
