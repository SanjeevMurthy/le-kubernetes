# Q37. A script with separate stdout and stderr files (solution)

## Steps

**1. Write the script.**

```bash
cat > /opt/course/37/report.sh <<'SCRIPT'
#!/bin/bash
OUT=/opt/course/37/report.txt
ERR=/opt/course/37/errors.txt

df -h    >  "$OUT" 2>  "$ERR"
free -m  >> "$OUT" 2>> "$ERR"
ls /opt/course/37/missing >> "$OUT" 2>> "$ERR"
date     >> "$OUT" 2>> "$ERR"

echo DONE
SCRIPT
```

**2. Make it executable and check it parses.**

```bash
chmod 755 /opt/course/37/report.sh
bash -n /opt/course/37/report.sh
```

**3. Run it from somewhere else, which is how it will be graded.**

```bash
cd /tmp && /opt/course/37/report.sh
```

A shorter form redirects both streams once, at the top of the script, and every later command inherits them:

```bash
#!/bin/bash
exec > /opt/course/37/report.txt 2> /opt/course/37/errors.txt
df -h
free -m
ls /opt/course/37/missing
date
echo DONE >&2      # careful: with exec, DONE would land in errors.txt
```

That variant needs a saved copy of the original standard output to print `DONE` to the terminal, so the plain per-command redirections above are the safer answer under time pressure.

## Why

Redirections are applied left to right, which is why `> out.txt 2>&1` sends both streams to the file and `2>&1 > out.txt` does not: in the second form stderr is aimed at wherever stdout pointed at that moment, which is still the terminal.

`>` truncates its target the instant the shell parses the line, before the command runs at all, so the first redirection resets `report.txt` and every later one must use `>>` or the file ends up holding only the last command's output.

Two separate destinations are the whole point of this task. `&>` and `> file 2>&1` merge the streams, which would put the `ls` error message in the middle of the report. Keeping `2>` pointed at a second file is what lets the report stay readable and the failure stay visible.

The `ls` on a path that does not exist is deliberate: it proves the error redirection is real. Without a command that actually fails, an empty `errors.txt` says nothing about whether stderr was captured or simply never used.

Absolute paths inside the script are what make it independent of the working directory. A relative `report.txt` would land wherever the caller happened to be. A `#!/bin/bash` shebang and mode 755 are what turn the text file into something a unit, a cron job or a timer can execute directly.

## Verify

```bash
ls -l /opt/course/37/report.sh          # expect -rwxr-xr-x
head -1 /opt/course/37/report.sh        # expect #!/bin/bash
bash -n /opt/course/37/report.sh

cd /tmp && /opt/course/37/report.sh     # prints DONE and nothing else
head -3 /opt/course/37/report.txt       # the df header
tail -1 /opt/course/37/report.txt       # the date
cat /opt/course/37/errors.txt           # the ls error message
```

## Docs

- `man 1 bash`, its REDIRECTION section, for `>`, `>>`, `2>`, `2>&1`, `&>` and `exec`
- `man 1 df`, `man 1 free` and `man 1 date` for the three commands the report runs
- `man 1 chmod` for the executable bit
- `man 1 test` and `man 1 bash` under SHELL BUILTIN COMMANDS for `set -euo pipefail` when a script grows
