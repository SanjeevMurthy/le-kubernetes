# Q39. Report CPU hog, load, cores, memory and process count (solution)

## Steps

**1. Find the busiest process.**

```bash
top -b -n 1 -c -o %CPU | head -12
ps -eo pid,pcpu,pmem,args --sort=-pcpu | head -5
pgrep -af lfcs-burner
```

All three put the same process at the top, and its command line begins with `lfcs-burner`. Its `comm` is `sha256sum`, because the burner was started with `exec -a`, which renames only `argv[0]` and leaves the executable name alone. That is why the commands above read the full command line: `ps -o comm`, and `top` without `-c`, print `sha256sum`, and `pgrep lfcs-burner` without `-f` finds nothing at all. Only `args` and `pgrep -f` see the name.

**2. Write the five files.**

```bash
mkdir -p /opt/course/39
cd /opt/course/39

ps -eo pid,pcpu --sort=-pcpu --no-headers | head -1 | awk '{print $1}' > cpu.txt
nproc > cores.txt
cut -d' ' -f1-3 /proc/loadavg > load.txt
free -m | awk '/^Mem:/ {print $7}' > mem.txt
ps -e --no-headers | wc -l > procs.txt

for f in *.txt; do printf '%s: ' "$f"; cat "$f"; done
```

The load line can also come from `uptime`:

```bash
uptime | awk -F'load average:' '{print $2}' | tr -d ',' > load.txt
```

## Why

`top -b -n 1` runs top in batch mode for a single iteration, which is what makes it usable in a pipeline; `-o %CPU` sorts by processor use. The first iteration of top reports CPU time since boot rather than an instantaneous rate, so a second iteration, or `ps --sort=-pcpu`, gives a steadier answer on a host that has been up for a while.

`nproc` counts the CPUs available to the current process, which is the number to divide the load average by before calling a load high. A load of 8 on 8 cores is exactly full, not overloaded. The load average counts runnable and uninterruptible tasks, so heavy disk waiting raises it without any CPU being busy.

`/proc/loadavg` always prints the three averages with a dot as the decimal separator, while `uptime` follows the locale and can print commas. When a grader is going to parse the file, the procfs form is the safer source.

Read the `available` column of `free -m`, not `free`. Page cache is counted as used but is reclaimable the moment an application asks for memory, so `free` understates what a new process can actually get. On the `free -m` table, `available` is the seventh field of the `Mem:` row.

Write only the value asked for. A grader matching a bare number fails on `PID: 1234`, and that is a whole task lost for a label nobody wanted.

## Verify

```bash
cd /opt/course/39
cat cpu.txt cores.txt load.txt mem.txt procs.txt

ps -p "$(cat cpu.txt)" -o pid,pcpu,args --no-headers   # the lfcs-burner command line
nproc
cat /proc/loadavg
free -m
ps -e --no-headers | wc -l
```

## Docs

- `man 1 top` for `-b`, `-n` and `-o`
- `man 1 ps` and its STANDARD FORMAT SPECIFIERS section for `-eo` and `--sort`
- `man 1 nproc`, `man 1 uptime`, `man 1 free`
- `man 5 proc` for `/proc/loadavg`, `/proc/cpuinfo` and `/proc/meminfo`
- `man 1 vmstat` and `man 1 pidstat` when the question is about sustained pressure rather than one instant
