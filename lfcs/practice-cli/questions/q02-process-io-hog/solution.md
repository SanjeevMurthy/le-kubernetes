# Q02. Find the disk-reading process, record its PID, lower its priority (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Watch per-process disk I/O for a few seconds.**

```bash
pidstat -d 1 5
```

The last block is an average over the run. One process has a `kB_rd/s` column far above every other line. Note its PID.

`iotop -bod5 -n2` gives the same picture where it is installed, and `ps` alone does not, because `ps` reports CPU, not I/O.

**2. Confirm what that PID actually is before touching it.**

```bash
ps -p <pid> -o pid,ppid,ni,comm,args
cat /proc/<pid>/io
```

`args` shows the process is named `lfcs-reader`, and `read_bytes` in `/proc/<pid>/io` keeps climbing, which is the storage-layer counter that `pidstat -d` reports.

**3. Write the PID to the deliverable.**

```bash
mkdir -p /opt/course/2
echo <pid> > /opt/course/2/pid.txt
```

Or without retyping it:

```bash
pgrep -f lfcs-reader > /opt/course/2/pid.txt
```

**4. Lower the priority.**

```bash
renice -n 15 -p <pid>
ps -o ni= -p <pid>
```

## Why

Nice values run from -20, the most favourable, to 19, the least. Raising the number makes the process yield the CPU to everything else. Only root can move a nice value back down, so a normal user who raises it cannot undo it.

`renice` is the right tool here because the task says explicitly not to kill the process. Reaching for `kill -9` on a process that is merely noisy destroys unflushed data and any temp files it holds, and on this exam it also fails the task outright.

Two counters exist for reads and they answer different questions. `rchar` in `/proc/<pid>/io` counts bytes returned by `read()` calls, including bytes served from the page cache. `read_bytes` counts bytes actually fetched from the block layer. `pidstat -d` reports the second one, which is why a process re-reading a cached file shows nothing there. The reader in this scenario drops its own cached pages after each pass so the traffic is real.

The nice value itself is not persistent. It belongs to the process and dies with it. When a task asks for a permanently deprioritised workload, the answer is `Nice=15` in the `[Service]` section of a systemd unit, not a `renice` command.

## Verify

```bash
cat /opt/course/2/pid.txt
ps -o pid,ni,comm -p "$(cat /opt/course/2/pid.txt)"
ps -o ni= -p "$(cat /opt/course/2/pid.txt)"   # 15
```

## Docs

- `man 1 pidstat` for `-d` and the `kB_rd/s` column
- `man 1 renice` and `man 2 setpriority` for the nice range and who may change it
- `man 1 ps` for `-o ni=` and the other output specifiers
- `man 1 pgrep` for matching on the full command line with `-f`
- `man 5 proc` for `/proc/<pid>/io`, `rchar` and `read_bytes`
- `man 7 signal` for what each signal does before reaching for `kill`
